package gitx

import (
	"context"
	"os"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
)

// BaseKind says what a session's changes are compared against.
type BaseKind int

const (
	// BaseSession is the commit HEAD was on when the session started.
	BaseSession BaseKind = iota + 1
	// BaseHeadNoBase is HEAD, because the session recorded no base (its
	// directory wasn't a repository with commits when it started).
	BaseHeadNoBase
	// BaseHeadMissing is HEAD, because the recorded base commit no longer
	// exists in the repository.
	BaseHeadMissing
	// BaseEmpty is the empty tree: there is neither a usable base nor a
	// HEAD commit, so every file counts as added.
	BaseEmpty
)

// Base is the tree a session's changes are diffed against.
type Base struct {
	// Rev is a commit sha, or the empty tree's sha for BaseEmpty.
	Rev  string
	Kind BaseKind
}

// FileStatus is how a file differs from the base.
type FileStatus int

const (
	FileModified FileStatus = iota + 1
	FileAdded
	FileDeleted
	FileRenamed
	FileCopied
	FileTypeChanged
	FileUnmerged
)

// File is one changed file.
type File struct {
	// Path is relative to the repository root, slash-separated.
	Path string
	// OldPath is the path before a rename or copy.
	OldPath string
	Status  FileStatus
	// Additions and Deletions count lines; both are 0 for a binary file.
	Additions, Deletions int
	Binary               bool
	// Where the change is relative to HEAD: staged (in the index),
	// unstaged (only in the work tree) or untracked. A file the session
	// committed since its base and hasn't touched since has none of them.
	Staged, Unstaged, Untracked bool
}

// Status is a repository's state as a session sees it.
type Status struct {
	// IsRepo is false when the directory isn't in a git work tree; nothing
	// else is set then.
	IsRepo bool
	Root   string
	// Branch is the checked-out branch; empty when HEAD is detached.
	Branch string
	// Head is HEAD's commit; empty for an unborn branch.
	Head     string
	Detached bool
	// Upstream is the branch's upstream (e.g. origin/main), if any; Ahead
	// and Behind count commits relative to it.
	Upstream      string
	Ahead, Behind int
	// Counts relative to HEAD, like git status.
	Staged, Unstaged, Untracked, Conflicted int
	// BaseCommit is the session's recorded base; Base is what was actually
	// diffed against.
	BaseCommit string
	Base       Base
	// Files changed since Base: committed, staged, unstaged and untracked.
	Files []File
	// FilesTruncated says Files was cut at the caller's limit.
	FilesTruncated bool
}

// emptyTree is the sha of the empty tree, which depends on the repository's
// hash algorithm.
func emptyTree(ctx context.Context, root string) (string, error) {
	out, err := RunOpts(ctx, root, Options{Stdin: strings.NewReader("")}, "hash-object", "-t", "tree", "--stdin")
	return strings.TrimSpace(out.Text), err
}

// ResolveBase picks what to diff against: the recorded base commit if it
// still exists, otherwise HEAD, otherwise the empty tree.
func ResolveBase(ctx context.Context, root, recorded string) (Base, error) {
	if recorded != "" && !strings.HasPrefix(recorded, "-") {
		if _, err := read(ctx, root, "cat-file", "-e", recorded+"^{commit}"); err == nil {
			return Base{Rev: recorded, Kind: BaseSession}, nil
		}
	}
	if h := head(ctx, root); h != "" {
		kind := BaseHeadNoBase
		if recorded != "" {
			kind = BaseHeadMissing
		}
		return Base{Rev: h, Kind: kind}, nil
	}
	t, err := emptyTree(ctx, root)
	return Base{Rev: t, Kind: BaseEmpty}, err
}

// GetStatus reports the repository containing dir: branch, upstream, counts
// relative to HEAD, and the files changed since the session's base commit
// (recorded; empty if none). At most maxFiles files are listed (0: all).
func GetStatus(ctx context.Context, dir, recorded string, maxFiles int) (*Status, error) {
	root, err := Root(ctx, dir)
	if err != nil || root == "" {
		return &Status{}, err
	}
	st := &Status{IsRepo: true, Root: root, BaseCommit: recorded}
	out, err := read(ctx, root, "status", "--porcelain=v2", "--branch", "-z", "--untracked-files=all")
	if err != nil {
		return nil, err
	}
	where := parsePorcelain(out, st)
	if st.Base, err = ResolveBase(ctx, root, recorded); err != nil {
		return nil, err
	}
	err = withIntentIndex(ctx, root, func(env []string) error {
		files, err := changedFiles(ctx, root, env, st.Base.Rev)
		if err != nil {
			return err
		}
		for i := range files {
			f := &files[i]
			w := where[f.Path]
			f.Staged, f.Unstaged, f.Untracked = w.staged, w.unstaged, w.untracked
		}
		if maxFiles > 0 && len(files) > maxFiles {
			files, st.FilesTruncated = files[:maxFiles], true
		}
		st.Files = files
		return nil
	})
	if err != nil {
		return nil, err
	}
	return st, nil
}

type location struct{ staged, unstaged, untracked bool }

// parsePorcelain fills st's branch fields and counts from `git status
// --porcelain=v2 --branch -z` and returns where each path's changes are.
func parsePorcelain(out string, st *Status) map[string]location {
	where := map[string]location{}
	recs := strings.Split(out, "\x00")
	for i := 0; i < len(recs); i++ {
		r := recs[i]
		switch {
		case strings.HasPrefix(r, "# branch.oid "):
			if oid := strings.TrimPrefix(r, "# branch.oid "); oid != "(initial)" {
				st.Head = oid
			}
		case strings.HasPrefix(r, "# branch.head "):
			if b := strings.TrimPrefix(r, "# branch.head "); b == "(detached)" {
				st.Detached = true
			} else {
				st.Branch = b
			}
		case strings.HasPrefix(r, "# branch.upstream "):
			st.Upstream = strings.TrimPrefix(r, "# branch.upstream ")
		case strings.HasPrefix(r, "# branch.ab "):
			for _, f := range strings.Fields(strings.TrimPrefix(r, "# branch.ab ")) {
				n, _ := strconv.Atoi(f[1:])
				if f[0] == '+' {
					st.Ahead = n
				} else {
					st.Behind = n
				}
			}
		case strings.HasPrefix(r, "1 "), strings.HasPrefix(r, "2 "):
			// 1 XY sub mH mI mW hH hI path; type 2 adds a score field
			// and is followed by a record holding the original path.
			n := 9
			if r[0] == '2' {
				n = 10
				i++
			}
			f := strings.SplitN(r, " ", n)
			if len(f) < n {
				continue
			}
			xy := f[1]
			loc := location{staged: xy[0] != '.', unstaged: xy[1] != '.'}
			if loc.staged {
				st.Staged++
			}
			if loc.unstaged {
				st.Unstaged++
			}
			where[f[n-1]] = loc
		case strings.HasPrefix(r, "u "):
			f := strings.SplitN(r, " ", 11)
			if len(f) == 11 {
				st.Conflicted++
				where[f[10]] = location{unstaged: true}
			}
		case strings.HasPrefix(r, "? "):
			st.Untracked++
			where[r[2:]] = location{untracked: true}
		}
	}
	return where
}

// withIntentIndex runs fn with env pointing git at a scratch copy of the
// index in which every untracked (not ignored) file is added with
// --intent-to-add, so `git diff <base>` shows untracked files as new files.
// The repository's own index is never written.
func withIntentIndex(ctx context.Context, root string, fn func(env []string) error) error {
	tmp, err := os.MkdirTemp("", "flit-index-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tmp)
	index := filepath.Join(tmp, "index")
	real, err := read(ctx, root, "rev-parse", "--path-format=absolute", "--git-path", "index")
	if err != nil {
		return err
	}
	if data, err := os.ReadFile(strings.TrimSpace(real)); err == nil {
		if err := os.WriteFile(index, data, 0o600); err != nil {
			return err
		}
	}
	env := append([]string{"GIT_INDEX_FILE=" + index}, readEnv...)
	untracked, err := RunOpts(ctx, root, Options{Env: env}, "ls-files", "-z", "--others", "--exclude-standard")
	if err != nil {
		return err
	}
	if untracked.Text != "" {
		_, err := RunOpts(ctx, root, Options{Env: env, Stdin: strings.NewReader(untracked.Text)},
			"add", "--intent-to-add", "--pathspec-from-file=-", "--pathspec-file-nul")
		if err != nil {
			return err
		}
	}
	return fn(env)
}

// diffArgs are common to every diff against a base.
var diffArgs = []string{"diff", "--no-color", "--no-ext-diff", "--no-textconv", "-M"}

// changedFiles lists files that differ between base and the work tree.
func changedFiles(ctx context.Context, root string, env []string, base string) ([]File, error) {
	names, err := RunOpts(ctx, root, Options{Env: env}, slices.Concat(diffArgs, []string{"--name-status", "-z", base, "--"})...)
	if err != nil {
		return nil, err
	}
	nums, err := RunOpts(ctx, root, Options{Env: env}, slices.Concat(diffArgs, []string{"--numstat", "-z", base, "--"})...)
	if err != nil {
		return nil, err
	}
	var files []File
	byPath := map[string]int{}
	recs := strings.Split(names.Text, "\x00")
	for i := 0; i+1 < len(recs); i += 2 {
		code, f := recs[i], File{Path: recs[i+1]}
		if code == "" {
			break
		}
		switch code[0] {
		case 'A':
			f.Status = FileAdded
		case 'D':
			f.Status = FileDeleted
		case 'R', 'C':
			f.Status = FileRenamed
			if code[0] == 'C' {
				f.Status = FileCopied
			}
			if i+2 >= len(recs) {
				break
			}
			f.OldPath, f.Path = recs[i+1], recs[i+2]
			i++
		case 'T':
			f.Status = FileTypeChanged
		case 'U':
			f.Status = FileUnmerged
		default:
			f.Status = FileModified
		}
		byPath[f.Path] = len(files)
		files = append(files, f)
	}
	// numstat -z: "add\tdel\tpath\0", or "add\tdel\t\0old\0new\0" for a
	// rename or copy; "-" counts mean binary.
	recs = strings.Split(nums.Text, "\x00")
	for i := 0; i < len(recs); i++ {
		parts := strings.SplitN(recs[i], "\t", 3)
		if len(parts) < 3 {
			continue
		}
		path := parts[2]
		if path == "" && i+2 < len(recs) {
			path = recs[i+2]
			i += 2
		}
		j, ok := byPath[path]
		if !ok {
			continue
		}
		if parts[0] == "-" {
			files[j].Binary = true
			continue
		}
		files[j].Additions, _ = strconv.Atoi(parts[0])
		files[j].Deletions, _ = strconv.Atoi(parts[1])
	}
	return files, nil
}

// Diff is a unified diff of a session's changes.
type Diff struct {
	IsRepo bool
	Base   Base
	Text   string
	// Truncated says the diff was cut at the size limit (at a line end).
	Truncated bool
}

// GetDiff returns the unified diff between the session's base and the work
// tree of dir's repository, untracked files included as new files,
// optionally only for path (relative to the repository root). At most
// maxBytes are returned.
func GetDiff(ctx context.Context, dir, recorded, path string, maxBytes int) (*Diff, error) {
	root, err := Root(ctx, dir)
	if err != nil || root == "" {
		return &Diff{}, err
	}
	d := &Diff{IsRepo: true}
	if d.Base, err = ResolveBase(ctx, root, recorded); err != nil {
		return nil, err
	}
	err = withIntentIndex(ctx, root, func(env []string) error {
		args := slices.Concat(diffArgs, []string{d.Base.Rev, "--"})
		if path != "" {
			args = append(args, path)
		}
		// One byte over the limit tells a diff that fits exactly from one
		// that doesn't.
		out, err := RunOpts(ctx, root, Options{Env: env, Limit: maxBytes + 1}, args...)
		if err != nil {
			return err
		}
		d.Text = out.Text
		if out.Truncated || len(d.Text) > maxBytes {
			d.Truncated = true
			d.Text = d.Text[:maxBytes]
			if i := strings.LastIndexByte(d.Text, '\n'); i >= 0 {
				d.Text = d.Text[:i+1]
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return d, nil
}
