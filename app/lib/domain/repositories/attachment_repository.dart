/// Repository interface for attachment control (ticket P7).
library;

import 'package:flit/domain/models/attachment.dart';

/// Attachment repository — image, PDF, and file attachment control.
abstract interface class AttachmentRepository {
  /// Attach an image from base64 bytes (wire `image.attach_bytes`).
  ///
  /// [contentBase64] is the base64-encoded image data (with or without
  /// data:image/...;base64, prefix). [filename] and [ext] are optional hints.
  Future<ImageAttachment> attachImageBytes(
    String sessionId, {
    required String contentBase64,
    String? filename,
    String? ext,
  });

  /// Detach an image (wire `image.detach`).
  ///
  /// [path] is the server-side path returned by attach_bytes.
  Future<DetachResult> detachImage(String sessionId, String path);

  /// Attach a PDF (wire `pdf.attach`).
  ///
  /// [contentBase64] is the base64-encoded PDF data (required for remote).
  /// [filename] is optional. [firstPage] and [lastPage] are optional page
  /// range constraints.
  Future<PdfAttachment> attachPdf(
    String sessionId, {
    required String contentBase64,
    String? filename,
    int? firstPage,
    int? lastPage,
  });

  /// Attach a file (wire `file.attach`).
  ///
  /// [path] is the local path (for loopback), or [dataUrl] is the data URL
  /// (for remote: `data:<mime>;base64,<b64>`). [name] is optional.
  Future<FileAttachment> attachFile(
    String sessionId, {
    String? path,
    String? dataUrl,
    String? name,
  });

  /// Detect whether text matches a drop pattern (wire `input.detect_drop`).
  ///
  /// [text] is the user input to check for file/image paths.
  Future<DropDetection> detectDrop(String sessionId, String text);

  /// Paste from clipboard (wire `clipboard.paste`).
  ///
  /// Returns attached image if clipboard contains an image.
  Future<ClipboardPasteResult> pasteClipboard(String sessionId);

  /// Collapse a large paste (wire `paste.collapse`).
  ///
  /// [text] is the pasted text. NO session_id needed for this method.
  Future<PasteCollapseResult> collapsePaste(String text);
}
