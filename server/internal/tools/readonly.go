package tools

import (
	"regexp"
	"slices"
	"strings"
)

// readOnlyPrograms are the programs shell.read_only allows without asking,
// each with a check of its arguments. They only read files and print, as
// long as the check passes (no find -delete, no sort -o, ...).
var readOnlyPrograms = map[string]func([]arg) bool{
	"cd": anyArgs, "pwd": anyArgs, "ls": anyArgs, "cat": anyArgs, "head": anyArgs, "tail": anyArgs,
	"wc": anyArgs, "grep": anyArgs, "egrep": anyArgs, "fgrep": anyArgs, "echo": anyArgs, "printf": anyArgs,
	"stat": anyArgs, "du": anyArgs, "df": anyArgs, "which": anyArgs, "type": anyArgs, "whoami": anyArgs,
	"uname": anyArgs, "basename": anyArgs, "dirname": anyArgs, "realpath": anyArgs, "readlink": anyArgs,
	"true": anyArgs, "false": anyArgs, "test": anyArgs, "[": anyArgs, "diff": anyArgs, "cmp": anyArgs,
	"comm": anyArgs, "cut": anyArgs, "tr": anyArgs, "nl": anyArgs, "column": anyArgs, "paste": anyArgs,
	"fold": anyArgs, "rev": anyArgs, "seq": anyArgs, "sleep": anyArgs, "jq": anyArgs, "ps": anyArgs,
	"continue": anyArgs, "break": anyArgs,
	"md5sum": anyArgs, "sha1sum": anyArgs, "sha256sum": anyArgs, "sha512sum": anyArgs,
	"file":    literalWithout("-C", "--compile"),
	"tree":    literalWithout("-o"),
	"rg":      literalWithout("--pre"),
	"date":    literalWithout("-s", "--set"),
	"sort":    sortArgs,
	"uniq":    uniqArgs,
	"find":    literalWithout("-exec", "-execdir", "-ok", "-okdir", "-delete", "-fprint", "-fprint0", "-fprintf", "-fls"),
	"command": func(a []arg) bool { return len(a) > 0 && a[0].lit && (a[0].val == "-v" || a[0].val == "-V") },
	"git":     gitArgs,
	"sed":     sedArgs,
}

// readOnly reports whether running name with args only reads.
func readOnly(name string, args []arg) bool {
	check, ok := readOnlyPrograms[name]
	return ok && check(args)
}

func anyArgs([]arg) bool { return true }

func allLiteral(args []arg) bool {
	for _, a := range args {
		if !a.lit {
			return false
		}
	}
	return true
}

// literalWithout allows literal arguments, none of which is one of flags
// (or flag=value).
func literalWithout(flags ...string) func([]arg) bool {
	return func(args []arg) bool {
		return allLiteral(args) && !hasFlag(args, flags...)
	}
}

func hasFlag(args []arg, flags ...string) bool {
	for _, a := range args {
		if a.val == "--" {
			return false
		}
		for _, f := range flags {
			if a.val == f || strings.HasPrefix(a.val, f+"=") {
				return true
			}
		}
	}
	return false
}

// shortCluster reports whether a is a cluster of short options (-rno)
// containing c.
func shortCluster(a arg, c byte) bool {
	return len(a.val) > 1 && a.val[0] == '-' && a.val[1] != '-' && strings.IndexByte(a.val[1:], c) >= 0
}

// sortArgs refuses -o/--output, which writes the result to a file.
func sortArgs(args []arg) bool {
	if !allLiteral(args) || hasFlag(args, "--output") {
		return false
	}
	return !slices.ContainsFunc(args, func(a arg) bool { return shortCluster(a, 'o') })
}

// uniqArgs refuses a second file name, which uniq writes its output to.
func uniqArgs(args []arg) bool {
	if !allLiteral(args) {
		return false
	}
	files := 0
	for _, a := range args {
		if !strings.HasPrefix(a.val, "-") || a.val == "-" {
			files++
		}
	}
	return files <= 1
}

// sedPrint is a sed script that only prints lines: 1,80p, $p, 10q.
var sedPrint = regexp.MustCompile(`^(\d+|\$)(,(\d+|\$))?[pq]$`)

// sedArgs allows sed when it only prints line ranges (sed -n 1,80p file),
// the one way models use it to read files. Other scripts can write files
// (w, -i) or run commands (e).
func sedArgs(args []arg) bool {
	if !allLiteral(args) {
		return false
	}
	scripts := 0
	for _, a := range args {
		switch {
		case a.val == "-n" || a.val == "--quiet" || a.val == "--silent" || a.val == "-E" || a.val == "-r" || a.val == "-s" || a.val == "-u" || a.val == "-z":
		case strings.HasPrefix(a.val, "-"):
			return false
		case scripts == 0:
			if !sedPrint.MatchString(a.val) {
				return false
			}
			scripts++
		}
	}
	return scripts == 1
}

// gitReadOnly are git subcommands that only read, with any further
// argument check.
var gitReadOnly = map[string]func([]arg) bool{
	"status": anyArgs, "log": anyArgs, "show": anyArgs, "diff": anyArgs, "grep": gitGrepArgs,
	"rev-parse": anyArgs, "ls-files": anyArgs, "ls-tree": anyArgs, "cat-file": anyArgs, "blame": anyArgs,
	"shortlog": anyArgs, "describe": anyArgs, "show-ref": anyArgs, "merge-base": anyArgs, "rev-list": anyArgs,
	"for-each-ref": anyArgs, "diff-tree": anyArgs, "name-rev": anyArgs, "count-objects": anyArgs,
	"version": anyArgs, "whatchanged": anyArgs, "cherry": anyArgs, "merge-tree": anyArgs,
	"branch":      gitBranchArgs,
	"tag":         gitListOnly("-l", "--list"),
	"remote":      gitRemoteArgs,
	"stash":       gitFirstIn("list", "show"),
	"worktree":    gitFirstIn("list"),
	"reflog":      func(a []arg) bool { return len(a) == 0 || a[0].val == "show" || strings.HasPrefix(a[0].val, "-") },
	"config":      gitFirstIn("--get", "--get-all", "--get-regexp", "--list", "-l"),
	"hash-object": func(a []arg) bool { return !hasFlag(a, "-w") },
}

// gitArgs allows read-only git subcommands. Arguments must be literal, and
// options that write files (--output) or run programs (-c, --exec-path)
// are refused.
func gitArgs(args []arg) bool {
	if !allLiteral(args) {
		return false
	}
	// Global options before the subcommand.
	for len(args) > 0 && strings.HasPrefix(args[0].val, "-") {
		switch v := args[0].val; {
		case v == "--no-pager" || v == "-P" || v == "--no-optional-locks" || v == "--literal-pathspecs" || v == "--bare":
			args = args[1:]
		case v == "-C" && len(args) > 1:
			args = args[2:]
		case strings.HasPrefix(v, "--git-dir=") || strings.HasPrefix(v, "--work-tree="):
			args = args[1:]
		default:
			return false // -c, --exec-path, --config-env, ...
		}
	}
	if len(args) == 0 {
		return false
	}
	check, ok := gitReadOnly[args[0].val]
	rest := args[1:]
	return ok && !hasFlag(rest, "--output") && check(rest)
}

// gitGrepArgs refuses -O/--open-files-in-pager, which runs a program.
func gitGrepArgs(args []arg) bool {
	return !hasFlag(args, "--open-files-in-pager") &&
		!slices.ContainsFunc(args, func(a arg) bool { return strings.HasPrefix(a.val, "-O") })
}

// gitBranchArgs allows listing branches but not creating, deleting,
// renaming or changing them.
func gitBranchArgs(args []arg) bool {
	if hasFlag(args, "-d", "-D", "--delete", "-m", "-M", "--move", "-c", "-C", "--copy", "-f", "--force",
		"-u", "--set-upstream-to", "--unset-upstream", "--edit-description", "-t", "--track", "--no-track") {
		return false
	}
	positional := slices.ContainsFunc(args, func(a arg) bool { return !strings.HasPrefix(a.val, "-") })
	// A bare name would create a branch; with a listing option it's a
	// pattern or commit instead.
	return !positional || hasFlag(args, "-l", "--list", "-a", "--all", "-r", "--remotes", "--contains",
		"--no-contains", "--merged", "--no-merged", "--points-at")
}

// gitListOnly allows the subcommand with no arguments or with a listing
// flag.
func gitListOnly(flags ...string) func([]arg) bool {
	return func(args []arg) bool { return len(args) == 0 || hasFlag(args, flags...) }
}

// gitFirstIn allows the subcommand when its first argument is one of
// first.
func gitFirstIn(first ...string) func([]arg) bool {
	return func(args []arg) bool { return len(args) > 0 && slices.Contains(first, args[0].val) }
}

func gitRemoteArgs(args []arg) bool {
	return len(args) == 0 || args[0].val == "-v" || args[0].val == "--verbose" || args[0].val == "get-url"
}
