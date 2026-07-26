/// Riverpod wiring for attachment control (ticket P7).
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/data/repositories/attachment_repository_impl.dart';
import 'package:flit/domain/models/attachment.dart';
import 'package:flit/domain/repositories/attachment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The attachment repository for the current connection, or null when there is
/// no RPC client (disconnected / pre-connect).
final attachmentRepositoryProvider = Provider<AttachmentRepository?>((ref) {
  final client = ref.watch(rpcClientProvider);
  if (client == null) {
    return null;
  }
  return AttachmentRepositoryImpl(client);
});

/// Staged attachments for the composer — local state only (no RPC).
final class StagedAttachments {
  const StagedAttachments({
    this.images = const <ImageAttachment>[],
    this.files = const <FileAttachment>[],
  });

  /// Staged images (including PDF pages).
  final List<ImageAttachment> images;

  /// Staged files.
  final List<FileAttachment> files;

  @override
  bool operator ==(Object other) {
    return other is StagedAttachments &&
        _listEquals(other.images, images) &&
        _listEquals(other.files, files);
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(images), Object.hashAll(files));

  @override
  String toString() {
    return 'StagedAttachments(images: $images, files: $files)';
  }
}

/// Provider for staged attachments.
final stagedAttachmentsProvider =
    NotifierProvider<StagedAttachmentsNotifier, StagedAttachments>(
      StagedAttachmentsNotifier.new,
    );

class StagedAttachmentsNotifier extends Notifier<StagedAttachments> {
  @override
  StagedAttachments build() => const StagedAttachments();

  /// Add an image to the staged list.
  void addImage(ImageAttachment img) {
    state = StagedAttachments(
      images: <ImageAttachment>[...state.images, img],
      files: state.files,
    );
  }

  /// Add multiple PDF pages to the staged list.
  void addPdfPages(List<ImageAttachment> pages) {
    state = StagedAttachments(
      images: <ImageAttachment>[...state.images, ...pages],
      files: state.files,
    );
  }

  /// Add a file to the staged list.
  void addFile(FileAttachment f) {
    state = StagedAttachments(
      images: state.images,
      files: <FileAttachment>[...state.files, f],
    );
  }

  /// Remove an image by path.
  void removeImage(String path) {
    state = StagedAttachments(
      images: state.images.where((img) => img.path != path).toList(),
      files: state.files,
    );
  }

  /// Clear all staged attachments (called after successful prompt submit).
  void clear() {
    state = const StagedAttachments();
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
