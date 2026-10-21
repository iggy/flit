import 'package:flit/domain/models/flit_git.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseUnifiedDiff classifies lines and numbers them', () {
    const diff =
        'diff --git a/a.txt b/a.txt\n'
        'index 1111111..2222222 100644\n'
        '--- a/a.txt\n'
        '+++ b/a.txt\n'
        '@@ -1,3 +1,3 @@ heading\n'
        ' one\n'
        '-two\n'
        '+TWO\n'
        ' three\n'
        '\\ No newline at end of file\n'
        'diff --git a/img.bin b/img.bin\n'
        'Binary files a/img.bin and b/img.bin differ\n';
    final lines = parseUnifiedDiff(diff);
    expect(lines.map((l) => l.kind).toList(), <FlitDiffLineKind>[
      FlitDiffLineKind.header,
      FlitDiffLineKind.header,
      FlitDiffLineKind.header,
      FlitDiffLineKind.header,
      FlitDiffLineKind.hunk,
      FlitDiffLineKind.context,
      FlitDiffLineKind.removed,
      FlitDiffLineKind.added,
      FlitDiffLineKind.context,
      FlitDiffLineKind.note,
      FlitDiffLineKind.header,
      FlitDiffLineKind.note,
    ]);
    expect(
      lines[5],
      const FlitDiffLine(
        FlitDiffLineKind.context,
        'one',
        oldLine: 1,
        newLine: 1,
      ),
    );
    expect(
      lines[6],
      const FlitDiffLine(FlitDiffLineKind.removed, 'two', oldLine: 2),
    );
    expect(
      lines[7],
      const FlitDiffLine(FlitDiffLineKind.added, 'TWO', newLine: 2),
    );
    expect(
      lines[8],
      const FlitDiffLine(
        FlitDiffLineKind.context,
        'three',
        oldLine: 3,
        newLine: 3,
      ),
    );
  });

  test('a new file counts from line 1 and keeps +++/--- as headers', () {
    final lines = parseUnifiedDiff(
      'diff --git a/n b/n\nnew file mode 100644\n--- /dev/null\n+++ b/n\n'
      '@@ -0,0 +1,2 @@\n+x\n+--y\n',
    );
    expect(lines[3].kind, FlitDiffLineKind.header);
    expect(
      lines.last,
      const FlitDiffLine(FlitDiffLineKind.added, '--y', newLine: 2),
    );
  });

  test('empty diff has no lines', () {
    expect(parseUnifiedDiff(''), isEmpty);
  });

  test('branchLabel falls back to a short sha when detached', () {
    const s = FlitGitStatus(
      isRepo: true,
      head: '0123456789abcdef',
      detached: true,
    );
    expect(s.branchLabel, '0123456');
    expect(
      const FlitGitStatus(isRepo: true, branch: 'main').branchLabel,
      'main',
    );
  });
}
