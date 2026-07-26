/// Domain models for attachment control (ticket P7).
///
/// Wire shapes from gateway protocol (image.attach_bytes, image.detach,
/// pdf.attach, file.attach, input.detect_drop, clipboard.paste,
/// paste.collapse).
library;

/// Image attachment from `image.attach_bytes`, a page in `pdf.attach`,
/// or an image from `clipboard.paste`/`input.detect_drop`.
final class ImageAttachment {
  const ImageAttachment({
    required this.path,
    required this.name,
    required this.count,
    this.tokenEstimate,
    this.width,
    this.height,
    this.bytes,
    this.text,
  });

  /// Wire `path` — server-side path to the attached image.
  final String path;

  /// Wire `name` — display name of the image.
  final String name;

  /// Wire `count` — total number of images attached in the session.
  final int count;

  /// Wire `token_estimate` — estimated token cost (nullable, absent if
  /// server-side PIL unavailable).
  final int? tokenEstimate;

  /// Wire `width` — image width in pixels (nullable, absent if PIL unavailable).
  final int? width;

  /// Wire `height` — image height in pixels (nullable, absent if PIL unavailable).
  final int? height;

  /// Wire `bytes` — image size in bytes (nullable).
  final int? bytes;

  /// Wire `text` — OCR or extracted text (nullable).
  final String? text;

  @override
  bool operator ==(Object other) {
    return other is ImageAttachment &&
        other.path == path &&
        other.name == name &&
        other.count == count &&
        other.tokenEstimate == tokenEstimate &&
        other.width == width &&
        other.height == height &&
        other.bytes == bytes &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(
        path,
        name,
        count,
        tokenEstimate,
        width,
        height,
        bytes,
        text,
      );

  @override
  String toString() {
    return 'ImageAttachment(path: $path, name: $name, count: $count, '
        'tokenEstimate: $tokenEstimate, width: $width, height: $height, '
        'bytes: $bytes, text: $text)';
  }
}

/// PDF attachment from `pdf.attach`.
final class PdfAttachment {
  const PdfAttachment({
    required this.filename,
    required this.pagesAttached,
    this.pages = const <ImageAttachment>[],
    required this.count,
    required this.text,
  });

  /// Wire `filename` — name of the PDF file.
  final String filename;

  /// Wire `pages_attached` — number of pages attached.
  final int pagesAttached;

  /// Wire `pages` — list of page images (each page is an [ImageAttachment]).
  final List<ImageAttachment> pages;

  /// Wire `count` — total number of images attached in the session.
  final int count;

  /// Wire `text` — extracted text from the PDF.
  final String text;

  @override
  bool operator ==(Object other) {
    return other is PdfAttachment &&
        other.filename == filename &&
        other.pagesAttached == pagesAttached &&
        _listEquals(other.pages, pages) &&
        other.count == count &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(
        filename,
        pagesAttached,
        Object.hashAll(pages),
        count,
        text,
      );

  @override
  String toString() {
    return 'PdfAttachment(filename: $filename, pagesAttached: $pagesAttached, '
        'pages: $pages, count: $count, text: $text)';
  }
}

/// File attachment from `file.attach`.
final class FileAttachment {
  const FileAttachment({
    required this.name,
    required this.path,
    required this.refPath,
    required this.refText,
    required this.uploaded,
  });

  /// Wire `name` — display name of the file.
  final String name;

  /// Wire `path` — server-side path to the attached file.
  final String path;

  /// Wire `ref_path` — reference path for the file.
  final String refPath;

  /// Wire `ref_text` — reference text (e.g. "@file:foo.csv").
  final String refText;

  /// Wire `uploaded` — whether the file was uploaded.
  final bool uploaded;

  @override
  bool operator ==(Object other) {
    return other is FileAttachment &&
        other.name == name &&
        other.path == path &&
        other.refPath == refPath &&
        other.refText == refText &&
        other.uploaded == uploaded;
  }

  @override
  int get hashCode => Object.hash(name, path, refPath, refText, uploaded);

  @override
  String toString() {
    return 'FileAttachment(name: $name, path: $path, refPath: $refPath, '
        'refText: $refText, uploaded: $uploaded)';
  }
}

/// Result of `image.detach`.
final class DetachResult {
  const DetachResult({
    required this.detached,
    required this.count,
  });

  /// Wire `detached` — whether the image was detached.
  final bool detached;

  /// Wire `count` — total number of images remaining in the session.
  final int count;

  @override
  bool operator ==(Object other) {
    return other is DetachResult &&
        other.detached == detached &&
        other.count == count;
  }

  @override
  int get hashCode => Object.hash(detached, count);

  @override
  String toString() {
    return 'DetachResult(detached: $detached, count: $count)';
  }
}

/// Result of `input.detect_drop`.
final class DropDetection {
  const DropDetection({
    required this.matched,
    this.isImage = false,
    this.path,
    this.name,
    this.text,
    this.image,
  });

  /// Wire `matched` — whether the text matched a drop pattern.
  final bool matched;

  /// Wire `is_image` — whether the drop is an image (only present when matched).
  final bool isImage;

  /// Wire `path` — path to the dropped file (only present when matched).
  final String? path;

  /// Wire `name` — name of the dropped file (only present for file drops).
  final String? name;

  /// Wire `text` — extracted text (only present when matched).
  final String? text;

  /// Image attachment (only populated for matched image case).
  final ImageAttachment? image;

  @override
  bool operator ==(Object other) {
    return other is DropDetection &&
        other.matched == matched &&
        other.isImage == isImage &&
        other.path == path &&
        other.name == name &&
        other.text == text &&
        other.image == image;
  }

  @override
  int get hashCode => Object.hash(matched, isImage, path, name, text, image);

  @override
  String toString() {
    return 'DropDetection(matched: $matched, isImage: $isImage, path: $path, '
        'name: $name, text: $text, image: $image)';
  }
}

/// Result of `clipboard.paste`.
final class ClipboardPasteResult {
  const ClipboardPasteResult({
    required this.attached,
    this.message,
    this.image,
  });

  /// Wire `attached` — whether an image was attached from clipboard.
  final bool attached;

  /// Wire `message` — human-readable message (nullable).
  final String? message;

  /// Image attachment (only populated when attached is true).
  final ImageAttachment? image;

  @override
  bool operator ==(Object other) {
    return other is ClipboardPasteResult &&
        other.attached == attached &&
        other.message == message &&
        other.image == image;
  }

  @override
  int get hashCode => Object.hash(attached, message, image);

  @override
  String toString() {
    return 'ClipboardPasteResult(attached: $attached, message: $message, '
        'image: $image)';
  }
}

/// Result of `paste.collapse`.
final class PasteCollapseResult {
  const PasteCollapseResult({
    required this.placeholder,
    required this.path,
    required this.lines,
  });

  /// Wire `placeholder` — placeholder text for collapsed paste.
  final String placeholder;

  /// Wire `path` — path to the collapsed paste file.
  final String path;

  /// Wire `lines` — number of lines in the collapsed paste.
  final int lines;

  @override
  bool operator ==(Object other) {
    return other is PasteCollapseResult &&
        other.placeholder == placeholder &&
        other.path == path &&
        other.lines == lines;
  }

  @override
  int get hashCode => Object.hash(placeholder, path, lines);

  @override
  String toString() {
    return 'PasteCollapseResult(placeholder: $placeholder, path: $path, '
        'lines: $lines)';
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
