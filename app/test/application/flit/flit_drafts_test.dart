import 'package:flit/application/flit/flit_drafts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drafts are kept per session', () {
    final store = FlitDraftStore()
      ..write('a', 'hello')
      ..write('b', 'world');
    expect(store.read('a'), 'hello');
    expect(store.read('b'), 'world');
    expect(store.read('c'), '');
  });

  test('writing again replaces the draft', () {
    final store = FlitDraftStore()
      ..write('a', 'hel')
      ..write('a', 'hello');
    expect(store.read('a'), 'hello');
  });

  test('empty text and clear forget the draft', () {
    final store = FlitDraftStore()
      ..write('a', 'hello')
      ..write('b', 'world')
      ..write('a', '')
      ..clear('b');
    expect(store.read('a'), '');
    expect(store.read('b'), '');
  });
}
