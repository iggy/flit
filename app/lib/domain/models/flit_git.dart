/// A flit session's git repository and its changes (flit.v1 `GitStatus`,
/// `GitDiff`), as the app sees them.
library;

/// What a session's changes are compared against (flit.v1 `GitDiffBase`).
enum FlitDiffBase {
  /// The commit HEAD was on when the session started.
  sessionStart,

  /// HEAD: the session recorded no base commit.
  headNoBase,

  /// HEAD: the session's base commit no longer exists.
  headBaseMissing,

  /// Nothing: the repository has no commits, so every file is new.
  emptyTree,

  unknown,
}

/// How a file differs from the diff base (flit.v1 `GitFileStatus`).
enum FlitFileStatus {
  modified,
  added,
  deleted,
  renamed,
  copied,
  typeChanged,
  unmerged,
  unknown,
}

/// One file changed since the diff base.
final class FlitGitFile {
  const FlitGitFile({
    required this.path,
    required this.status,
    this.oldPath = '',
    this.additions = 0,
    this.deletions = 0,
    this.binary = false,
    this.staged = false,
    this.unstaged = false,
    this.untracked = false,
  });

  /// Relative to the repository root.
  final String path;

  /// The path before a rename or copy; empty otherwise.
  final String oldPath;
  final FlitFileStatus status;
  final int additions;
  final int deletions;
  final bool binary;

  /// Where the change is relative to HEAD; none of them for a file
  /// committed since the base.
  final bool staged;
  final bool unstaged;
  final bool untracked;

  @override
  bool operator ==(Object other) =>
      other is FlitGitFile &&
      other.path == path &&
      other.oldPath == oldPath &&
      other.status == status &&
      other.additions == additions &&
      other.deletions == deletions &&
      other.binary == binary &&
      other.staged == staged &&
      other.unstaged == unstaged &&
      other.untracked == untracked;

  @override
  int get hashCode => Object.hash(
    path,
    oldPath,
    status,
    additions,
    deletions,
    binary,
    staged,
    unstaged,
    untracked,
  );
}

/// The repository a session works in.
final class FlitGitStatus {
  const FlitGitStatus({
    required this.isRepo,
    this.root = '',
    this.branch = '',
    this.head = '',
    this.detached = false,
    this.upstream = '',
    this.ahead = 0,
    this.behind = 0,
    this.stagedCount = 0,
    this.unstagedCount = 0,
    this.untrackedCount = 0,
    this.conflictedCount = 0,
    this.baseCommit = '',
    this.diffBase = '',
    this.diffBaseKind = FlitDiffBase.unknown,
    this.files = const <FlitGitFile>[],
    this.filesTruncated = false,
  });

  /// Not a repository: the working directory isn't in a git work tree.
  static const FlitGitStatus none = FlitGitStatus(isRepo: false);

  final bool isRepo;
  final String root;

  /// The branch; empty when HEAD is detached.
  final String branch;

  /// HEAD's commit; empty before the first commit.
  final String head;
  final bool detached;

  /// The upstream branch, empty if none; [ahead] and [behind] count commits
  /// relative to it.
  final String upstream;
  final int ahead;
  final int behind;

  /// Counts relative to HEAD, like git status.
  final int stagedCount;
  final int unstagedCount;
  final int untrackedCount;
  final int conflictedCount;

  /// The session's base commit, and what was actually diffed against.
  final String baseCommit;
  final String diffBase;
  final FlitDiffBase diffBaseKind;

  /// Files changed since [diffBase]; [filesTruncated] says the server left
  /// some out.
  final List<FlitGitFile> files;
  final bool filesTruncated;

  /// The branch, or a short sha when detached.
  String get branchLabel {
    if (branch.isNotEmpty) {
      return branch;
    }
    return head.length > 7 ? head.substring(0, 7) : head;
  }
}

/// A unified diff of a session's changes.
final class FlitGitDiff {
  const FlitGitDiff({
    required this.isRepo,
    required this.text,
    this.diffBase = '',
    this.diffBaseKind = FlitDiffBase.unknown,
    this.truncated = false,
  });

  final bool isRepo;
  final String text;
  final String diffBase;
  final FlitDiffBase diffBaseKind;

  /// The server cut the diff at its size limit.
  final bool truncated;
}

/// What a line of a unified diff is.
enum FlitDiffLineKind {
  /// `diff --git`, `index`, `---`/`+++`, mode and rename lines.
  header,

  /// `@@ -a,b +c,d @@`.
  hunk,
  added,
  removed,
  context,

  /// `\ No newline at end of file`, `Binary files ... differ`.
  note,
}

/// One line of a unified diff, with its line numbers in the old and new
/// file (null where the line doesn't exist on that side).
final class FlitDiffLine {
  const FlitDiffLine(this.kind, this.text, {this.oldLine, this.newLine});

  final FlitDiffLineKind kind;

  /// The line without its leading +, - or space for added, removed and
  /// context lines; the whole line otherwise.
  final String text;
  final int? oldLine;
  final int? newLine;

  @override
  bool operator ==(Object other) =>
      other is FlitDiffLine &&
      other.kind == kind &&
      other.text == text &&
      other.oldLine == oldLine &&
      other.newLine == newLine;

  @override
  int get hashCode => Object.hash(kind, text, oldLine, newLine);

  @override
  String toString() => 'FlitDiffLine($kind, $text, $oldLine, $newLine)';
}

final RegExp _hunkHeader = RegExp(r'^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@');

/// Splits a unified diff (git diff output) into classified lines.
List<FlitDiffLine> parseUnifiedDiff(String diff) {
  final out = <FlitDiffLine>[];
  var oldLine = 0;
  var newLine = 0;
  var inHunk = false;
  final lines = diff.split('\n');
  if (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  for (final line in lines) {
    if (line.startsWith('diff ')) {
      inHunk = false;
      out.add(FlitDiffLine(FlitDiffLineKind.header, line));
      continue;
    }
    final hunk = _hunkHeader.firstMatch(line);
    if (hunk != null) {
      inHunk = true;
      oldLine = int.parse(hunk.group(1)!);
      newLine = int.parse(hunk.group(2)!);
      out.add(FlitDiffLine(FlitDiffLineKind.hunk, line));
      continue;
    }
    if (!inHunk) {
      out.add(
        FlitDiffLine(
          line.startsWith('Binary files ')
              ? FlitDiffLineKind.note
              : FlitDiffLineKind.header,
          line,
        ),
      );
      continue;
    }
    if (line.startsWith('+')) {
      out.add(
        FlitDiffLine(
          FlitDiffLineKind.added,
          line.substring(1),
          newLine: newLine++,
        ),
      );
    } else if (line.startsWith('-')) {
      out.add(
        FlitDiffLine(
          FlitDiffLineKind.removed,
          line.substring(1),
          oldLine: oldLine++,
        ),
      );
    } else if (line.startsWith(r'\')) {
      out.add(FlitDiffLine(FlitDiffLineKind.note, line));
    } else {
      out.add(
        FlitDiffLine(
          FlitDiffLineKind.context,
          line.isEmpty ? '' : line.substring(1),
          oldLine: oldLine++,
          newLine: newLine++,
        ),
      );
    }
  }
  return out;
}

/// What removing a session's worktree did.
final class FlitWorktreeRemoval {
  const FlitWorktreeRemoval({
    required this.branch,
    required this.branchKept,
    this.commits = 0,
  });

  final String branch;

  /// The branch stayed, holding [commits] commits found nowhere else.
  final bool branchKept;
  final int commits;
}
