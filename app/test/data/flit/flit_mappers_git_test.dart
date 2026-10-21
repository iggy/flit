import 'package:flit/data/flit/flit_mappers.dart';
import 'package:flit/domain/models/flit_git.dart';
import 'package:flit_api/flit_api.dart' as pb;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gitStatusFromProto maps a repository', () {
    final s = gitStatusFromProto(
      pb.GitStatusResponse(
        isRepo: true,
        root: '/src',
        branch: 'main',
        head: 'abc',
        upstream: 'origin/main',
        ahead: 2,
        behind: 1,
        stagedCount: 1,
        untrackedCount: 3,
        baseCommit: 'base',
        diffBase: 'base',
        diffBaseKind: pb.GitDiffBase.GIT_DIFF_BASE_SESSION_START,
        files: <pb.GitFileChange>[
          pb.GitFileChange(
            path: 'b.txt',
            oldPath: 'a.txt',
            status: pb.GitFileStatus.GIT_FILE_STATUS_RENAMED,
            additions: 4,
            deletions: 2,
            staged: true,
          ),
        ],
        filesTruncated: true,
      ),
    );
    expect(s.isRepo, isTrue);
    expect(s.branch, 'main');
    expect(s.upstream, 'origin/main');
    expect((s.ahead, s.behind), (2, 1));
    expect((s.stagedCount, s.untrackedCount), (1, 3));
    expect(s.diffBaseKind, FlitDiffBase.sessionStart);
    expect(s.filesTruncated, isTrue);
    expect(s.files, const <FlitGitFile>[
      FlitGitFile(
        path: 'b.txt',
        oldPath: 'a.txt',
        status: FlitFileStatus.renamed,
        additions: 4,
        deletions: 2,
        staged: true,
      ),
    ]);
  });

  test('gitStatusFromProto: not a repository', () {
    expect(gitStatusFromProto(pb.GitStatusResponse()).isRepo, isFalse);
  });

  test('gitDiffFromProto', () {
    final d = gitDiffFromProto(
      pb.GitDiffResponse(
        isRepo: true,
        diff: '+x\n',
        diffBase: 'h',
        diffBaseKind: pb.GitDiffBase.GIT_DIFF_BASE_HEAD_BASE_MISSING,
        truncated: true,
      ),
    );
    expect(d.text, '+x\n');
    expect(d.diffBaseKind, FlitDiffBase.headBaseMissing);
    expect(d.truncated, isTrue);
  });

  test('sessions and projects carry worktree fields', () {
    final s = sessionFromProto(
      pb.Session(
        id: 's',
        workingDir: '/data/worktrees/s/sub',
        sourceDir: '/src/app/sub',
        worktreePath: '/data/worktrees/s',
        worktreeBranch: 'flit/abcd1234',
      ),
    );
    expect(s.hasWorktree, isTrue);
    expect(s.worktreeBranch, 'flit/abcd1234');
    expect(s.sourceDir, '/src/app/sub');
    expect(sessionFromProto(pb.Session(id: 't')).hasWorktree, isFalse);

    expect(
      projectFromProto(pb.Project(id: 'p', worktreesEnabled: true)).worktrees,
      isTrue,
    );
  });
}
