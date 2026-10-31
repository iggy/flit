import 'package:flit/domain/models/shared_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a bare URL is the draft', () {
    expect(
      const SharedContent(text: ' https://arxiv.org/abs/1706.03762 ').draft,
      'https://arxiv.org/abs/1706.03762',
    );
  });

  test('a page title goes above the URL', () {
    expect(
      const SharedContent(
        text: 'https://arxiv.org/abs/1706.03762',
        subject: 'Attention Is All You Need',
      ).draft,
      'Attention Is All You Need\nhttps://arxiv.org/abs/1706.03762',
    );
  });

  test('a subject already in the text is not repeated', () {
    expect(
      const SharedContent(
        text: 'Attention Is All You Need https://arxiv.org/abs/1706.03762',
        subject: 'Attention Is All You Need',
      ).draft,
      'Attention Is All You Need https://arxiv.org/abs/1706.03762',
    );
  });

  test('subject only, and empty', () {
    expect(const SharedContent(subject: 'A title').draft, 'A title');
    expect(const SharedContent(text: ' ', subject: '').isEmpty, isTrue);
  });
}
