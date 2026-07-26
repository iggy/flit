// P7 acceptance: StagedAttachmentsNotifier state management.

import 'package:flit/application/attachments/attachment_providers.dart';
import 'package:flit/domain/models/attachment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StagedAttachmentsNotifier', () {
    test('initial state is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(stagedAttachmentsProvider);

      expect(state.images, isEmpty);
      expect(state.files, isEmpty);
    });

    test('addImage appends to images list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(stagedAttachmentsProvider.notifier);
      const img1 = ImageAttachment(
        path: '/tmp/img1.png',
        name: 'img1.png',
        count: 1,
      );
      const img2 = ImageAttachment(
        path: '/tmp/img2.png',
        name: 'img2.png',
        count: 2,
      );

      notifier.addImage(img1);
      var state = container.read(stagedAttachmentsProvider);
      expect(state.images.length, 1);
      expect(state.images[0], img1);
      expect(state.files, isEmpty);

      notifier.addImage(img2);
      state = container.read(stagedAttachmentsProvider);
      expect(state.images.length, 2);
      expect(state.images[0], img1);
      expect(state.images[1], img2);
    });

    test('addPdfPages appends multiple images', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(stagedAttachmentsProvider.notifier);
      const page1 = ImageAttachment(
        path: '/tmp/pdf_p1.png',
        name: 'doc.pdf page 1',
        count: 1,
      );
      const page2 = ImageAttachment(
        path: '/tmp/pdf_p2.png',
        name: 'doc.pdf page 2',
        count: 2,
      );

      notifier.addPdfPages(const <ImageAttachment>[page1, page2]);
      final state = container.read(stagedAttachmentsProvider);

      expect(state.images.length, 2);
      expect(state.images[0], page1);
      expect(state.images[1], page2);
      expect(state.files, isEmpty);
    });

    test('addFile appends to files list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(stagedAttachmentsProvider.notifier);
      const file1 = FileAttachment(
        name: 'data.csv',
        path: '/tmp/data.csv',
        refPath: '@file:data.csv',
        refText: '@file:data.csv',
        uploaded: true,
      );
      const file2 = FileAttachment(
        name: 'notes.txt',
        path: '/tmp/notes.txt',
        refPath: '@file:notes.txt',
        refText: '@file:notes.txt',
        uploaded: false,
      );

      notifier.addFile(file1);
      var state = container.read(stagedAttachmentsProvider);
      expect(state.files.length, 1);
      expect(state.files[0], file1);
      expect(state.images, isEmpty);

      notifier.addFile(file2);
      state = container.read(stagedAttachmentsProvider);
      expect(state.files.length, 2);
      expect(state.files[0], file1);
      expect(state.files[1], file2);
    });

    test('removeImage removes by path', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(stagedAttachmentsProvider.notifier);
      const img1 = ImageAttachment(
        path: '/tmp/img1.png',
        name: 'img1.png',
        count: 1,
      );
      const img2 = ImageAttachment(
        path: '/tmp/img2.png',
        name: 'img2.png',
        count: 2,
      );
      const img3 = ImageAttachment(
        path: '/tmp/img3.png',
        name: 'img3.png',
        count: 3,
      );

      notifier.addImage(img1);
      notifier.addImage(img2);
      notifier.addImage(img3);

      notifier.removeImage('/tmp/img2.png');
      final state = container.read(stagedAttachmentsProvider);

      expect(state.images.length, 2);
      expect(state.images[0], img1);
      expect(state.images[1], img3);
    });

    test('removeImage does nothing if path not found', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(stagedAttachmentsProvider.notifier);
      const img1 = ImageAttachment(
        path: '/tmp/img1.png',
        name: 'img1.png',
        count: 1,
      );

      notifier.addImage(img1);
      notifier.removeImage('/tmp/nonexistent.png');
      final state = container.read(stagedAttachmentsProvider);

      expect(state.images.length, 1);
      expect(state.images[0], img1);
    });

    test('clear resets to empty state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(stagedAttachmentsProvider.notifier);
      const img1 = ImageAttachment(
        path: '/tmp/img1.png',
        name: 'img1.png',
        count: 1,
      );
      const file1 = FileAttachment(
        name: 'data.csv',
        path: '/tmp/data.csv',
        refPath: '@file:data.csv',
        refText: '@file:data.csv',
        uploaded: true,
      );

      notifier.addImage(img1);
      notifier.addFile(file1);

      notifier.clear();
      final state = container.read(stagedAttachmentsProvider);

      expect(state.images, isEmpty);
      expect(state.files, isEmpty);
    });

    test('mixed operations preserve both lists', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(stagedAttachmentsProvider.notifier);
      const img1 = ImageAttachment(
        path: '/tmp/img1.png',
        name: 'img1.png',
        count: 1,
      );
      const file1 = FileAttachment(
        name: 'data.csv',
        path: '/tmp/data.csv',
        refPath: '@file:data.csv',
        refText: '@file:data.csv',
        uploaded: true,
      );

      notifier.addImage(img1);
      notifier.addFile(file1);

      var state = container.read(stagedAttachmentsProvider);
      expect(state.images.length, 1);
      expect(state.files.length, 1);

      notifier.removeImage('/tmp/img1.png');
      state = container.read(stagedAttachmentsProvider);
      expect(state.images, isEmpty);
      expect(state.files.length, 1);
      expect(state.files[0], file1);
    });
  });
}
