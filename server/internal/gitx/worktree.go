package gitx

import (
	"context"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"runtime"
	"slices"
	"strconv"
	"strings"
)

// ErrUnborn is returned when a worktree is asked for in a repository with
// no commits yet: there is nothing to check out.
var ErrUnborn = errors.New("the repository has no commits yet")

// AddWorktree creates a worktree of the repository at root at dir, on a
// new branch named branch (or branch-2, branch-3, ... if that exists)
// starting at root's HEAD. The checkout at root is left as it is. It
// returns the branch it made and the commit it started at.
func AddWorktree(ctx context.Context, root, dir, branch string) (string, string, error) {
	base := head(ctx, root)
	if base == "" {
		return "", "", ErrUnborn
	}
	name := branch
	for i := 2; ; i++ {
		if _, err := read(ctx, root, "show-ref", "--verify", "--quiet", "refs/heads/"+name); err != nil {
			break
		}
		name = branch + "-" + strconv.Itoa(i)
	}
	if err := os.MkdirAll(filepath.Dir(dir), 0o755); err != nil {
		return "", "", err
	}
	if _, err := Run(ctx, root, "worktree", "add", "--quiet", "-b", name, dir, base); err != nil {
		return "", "", err
	}
	return name, base, nil
}

// CopyMethod says how a directory was copied.
type CopyMethod string

const (
	// CopyReflink shares the files' data with the source (copy on write).
	CopyReflink CopyMethod = "reflink"
	// CopyPlain copied every byte: the filesystem can't reflink.
	CopyPlain CopyMethod = "copy"
)

// Copied is one ignored directory copied into a worktree.
type Copied struct {
	// Path is relative to the repository root, slash-separated.
	Path   string
	Method CopyMethod
	// Err is set when the copy failed; the worktree may lack the directory.
	Err error
}

// reflinkCopy copies directory src to dst (which must not exist) sharing
// data blocks, or fails if the filesystem can't. Symlinks are copied as
// links, never followed. A variable so tests can make it fail.
var reflinkCopy = func(ctx context.Context, src, dst string) error {
	var cmd *exec.Cmd
	switch runtime.GOOS {
	case "linux":
		cmd = exec.CommandContext(ctx, "cp", "-R", "-P", "--reflink=always", src, dst)
	case "darwin":
		cmd = exec.CommandContext(ctx, "cp", "-c", "-R", "-P", src, dst)
	default:
		return errors.ErrUnsupported
	}
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("cp: %v: %s", err, strings.TrimSpace(string(out)))
	}
	return nil
}

// CopyIgnored copies the ignored directories of the work tree at src whose
// name is in names (e.g. node_modules, anywhere in the tree) to the same
// place under dst, by reflink where the filesystem supports it and a plain
// copy otherwise. Names that match nothing are skipped. A directory that is
// itself a symlink is skipped, and symlinks inside are copied as links, so
// nothing outside the repository is ever read.
func CopyIgnored(ctx context.Context, src, dst string, names []string) ([]Copied, error) {
	if len(names) == 0 {
		return nil, nil
	}
	out, err := read(ctx, src, "ls-files", "-z", "--others", "--ignored", "--exclude-standard", "--directory")
	if err != nil {
		return nil, err
	}
	var copied []Copied
	for _, p := range strings.Split(out, "\x00") {
		if !strings.HasSuffix(p, "/") {
			continue // a file, or the end of the list
		}
		p = strings.TrimSuffix(p, "/")
		if !slices.Contains(names, path.Base(p)) || !filepath.IsLocal(p) {
			continue
		}
		from, to := filepath.Join(src, filepath.FromSlash(p)), filepath.Join(dst, filepath.FromSlash(p))
		if fi, err := os.Lstat(from); err != nil || !fi.IsDir() {
			continue
		}
		if _, err := os.Lstat(to); err == nil {
			continue
		}
		c := Copied{Path: p, Method: CopyReflink}
		if err := os.MkdirAll(filepath.Dir(to), 0o755); err != nil {
			c.Err = err
		} else if err := reflinkCopy(ctx, from, to); err != nil {
			c.Method = CopyPlain
			if err := os.RemoveAll(to); err != nil {
				c.Err = err
			} else {
				c.Err = plainCopy(from, to)
			}
		}
		copied = append(copied, c)
	}
	return copied, nil
}

// plainCopy copies directory src to dst byte by byte, keeping modes and
// copying symlinks as links.
func plainCopy(src, dst string) error {
	return filepath.WalkDir(src, func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(src, p)
		if err != nil {
			return err
		}
		to := filepath.Join(dst, rel)
		info, err := d.Info()
		if err != nil {
			return err
		}
		switch {
		case d.IsDir():
			return os.MkdirAll(to, info.Mode().Perm()|0o700)
		case d.Type()&fs.ModeSymlink != 0:
			link, err := os.Readlink(p)
			if err != nil {
				return err
			}
			return os.Symlink(link, to)
		case d.Type().IsRegular():
			return copyFile(p, to, info.Mode().Perm())
		}
		return nil // sockets, devices, ...
	})
}

func copyFile(src, dst string, mode fs.FileMode) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_EXCL, mode)
	if err != nil {
		return err
	}
	if _, err := io.Copy(out, in); err != nil {
		out.Close()
		return err
	}
	return out.Close()
}

// Uncommitted says whether the work tree at dir has changes that aren't
// committed: modified or untracked files (ignored ones don't count).
func Uncommitted(ctx context.Context, dir string) (bool, error) {
	out, err := read(ctx, dir, "status", "--porcelain", "-z", "--untracked-files=normal")
	return out != "", err
}

// OnlyOnBranch counts the commits on branch that no other branch, tag or
// remote-tracking ref has and that weren't there at base: what deleting
// the branch would lose.
func OnlyOnBranch(ctx context.Context, dir, branch, base string) (int, error) {
	args := []string{"rev-list", "--count", "refs/heads/" + branch, "--not",
		"--exclude=" + branch, "--branches", "--tags", "--remotes"}
	if base != "" {
		args = append(args, base)
	}
	out, err := read(ctx, dir, args...)
	if err != nil {
		return 0, err
	}
	return strconv.Atoi(strings.TrimSpace(out))
}

// RemoveWorktree removes the worktree at dir; git refuses if it has
// uncommitted changes. With deleteBranch it deletes branch as well.
func RemoveWorktree(ctx context.Context, dir, branch string, deleteBranch bool) error {
	common, err := read(ctx, dir, "rev-parse", "--path-format=absolute", "--git-common-dir")
	if err != nil {
		return err
	}
	if _, err := Run(ctx, dir, "worktree", "remove", dir); err != nil {
		return err
	}
	if !deleteBranch || branch == "" {
		return nil
	}
	_, err = Run(ctx, strings.TrimSpace(common), "branch", "-D", branch)
	return err
}
