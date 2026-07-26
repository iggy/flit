import 'package:flit/domain/models/attachment.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attachment_dtos.g.dart';

/// Wire DTO for `image.attach_bytes` result, also reused for PDF pages
/// and clipboard/detect_drop image results.
@JsonSerializable()
class ImageAttachDto {
  const ImageAttachDto({
    this.path,
    this.name,
    this.count,
    this.tokenEstimate,
    this.width,
    this.height,
    this.bytes,
    this.text,
    this.remainder,
  });

  factory ImageAttachDto.fromJson(Map<String, dynamic> json) =>
      _$ImageAttachDtoFromJson(json);

  @JsonKey(name: 'path')
  final String? path;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'count')
  final int? count;

  @JsonKey(name: 'token_estimate')
  final int? tokenEstimate;

  @JsonKey(name: 'width')
  final int? width;

  @JsonKey(name: 'height')
  final int? height;

  @JsonKey(name: 'bytes')
  final int? bytes;

  @JsonKey(name: 'text')
  final String? text;

  @JsonKey(name: 'remainder')
  final String? remainder;

  Map<String, dynamic> toJson() => _$ImageAttachDtoToJson(this);

  ImageAttachment toDomain() {
    return ImageAttachment(
      path: path ?? '',
      name: name ?? '',
      count: count ?? 0,
      tokenEstimate: tokenEstimate,
      width: width,
      height: height,
      bytes: bytes,
      text: text,
    );
  }
}

/// Wire DTO for `image.detach` result.
@JsonSerializable()
class DetachResultDto {
  const DetachResultDto({this.detached, this.count});

  factory DetachResultDto.fromJson(Map<String, dynamic> json) =>
      _$DetachResultDtoFromJson(json);

  @JsonKey(name: 'detached')
  final bool? detached;

  @JsonKey(name: 'count')
  final int? count;

  Map<String, dynamic> toJson() => _$DetachResultDtoToJson(this);

  DetachResult toDomain() {
    return DetachResult(detached: detached ?? false, count: count ?? 0);
  }
}

/// Wire DTO for `pdf.attach` result.
@JsonSerializable()
class PdfAttachDto {
  const PdfAttachDto({
    this.attached,
    this.filename,
    this.pagesAttached,
    this.pages = const <ImageAttachDto>[],
    this.count,
    this.text,
  });

  factory PdfAttachDto.fromJson(Map<String, dynamic> json) =>
      _$PdfAttachDtoFromJson(json);

  @JsonKey(name: 'attached')
  final bool? attached;

  @JsonKey(name: 'filename')
  final String? filename;

  @JsonKey(name: 'pages_attached')
  final int? pagesAttached;

  @JsonKey(name: 'pages')
  final List<ImageAttachDto> pages;

  @JsonKey(name: 'count')
  final int? count;

  @JsonKey(name: 'text')
  final String? text;

  Map<String, dynamic> toJson() => _$PdfAttachDtoToJson(this);

  PdfAttachment toDomain() {
    return PdfAttachment(
      filename: filename ?? '',
      pagesAttached: pagesAttached ?? 0,
      pages: pages.map((dto) => dto.toDomain()).toList(),
      count: count ?? 0,
      text: text ?? '',
    );
  }
}

/// Wire DTO for `file.attach` result.
@JsonSerializable()
class FileAttachDto {
  const FileAttachDto({
    this.attached,
    this.name,
    this.path,
    this.refPath,
    this.refText,
    this.uploaded,
  });

  factory FileAttachDto.fromJson(Map<String, dynamic> json) =>
      _$FileAttachDtoFromJson(json);

  @JsonKey(name: 'attached')
  final bool? attached;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'path')
  final String? path;

  @JsonKey(name: 'ref_path')
  final String? refPath;

  @JsonKey(name: 'ref_text')
  final String? refText;

  @JsonKey(name: 'uploaded')
  final bool? uploaded;

  Map<String, dynamic> toJson() => _$FileAttachDtoToJson(this);

  FileAttachment toDomain() {
    return FileAttachment(
      name: name ?? '',
      path: path ?? '',
      refPath: refPath ?? '',
      refText: refText ?? '',
      uploaded: uploaded ?? false,
    );
  }
}

/// Wire DTO for `input.detect_drop` result.
@JsonSerializable()
class DropDetectionDto {
  const DropDetectionDto({
    this.matched,
    this.isImage,
    this.path,
    this.name,
    this.text,
    this.count,
    this.width,
    this.height,
    this.tokenEstimate,
  });

  factory DropDetectionDto.fromJson(Map<String, dynamic> json) =>
      _$DropDetectionDtoFromJson(json);

  @JsonKey(name: 'matched')
  final bool? matched;

  @JsonKey(name: 'is_image')
  final bool? isImage;

  @JsonKey(name: 'path')
  final String? path;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'text')
  final String? text;

  @JsonKey(name: 'count')
  final int? count;

  @JsonKey(name: 'width')
  final int? width;

  @JsonKey(name: 'height')
  final int? height;

  @JsonKey(name: 'token_estimate')
  final int? tokenEstimate;

  Map<String, dynamic> toJson() => _$DropDetectionDtoToJson(this);

  DropDetection toDomain() {
    final matchedValue = matched ?? false;
    final isImageValue = isImage ?? false;
    ImageAttachment? imageAttachment;
    if (matchedValue && isImageValue && path != null) {
      imageAttachment = ImageAttachment(
        path: path!,
        name: name ?? '',
        count: count ?? 0,
        tokenEstimate: tokenEstimate,
        width: width,
        height: height,
      );
    }
    return DropDetection(
      matched: matchedValue,
      isImage: isImageValue,
      path: path,
      name: name,
      text: text,
      image: imageAttachment,
    );
  }
}

/// Wire DTO for `clipboard.paste` result.
@JsonSerializable()
class ClipboardPasteDto {
  const ClipboardPasteDto({
    this.attached,
    this.message,
    this.path,
    this.count,
    this.name,
    this.width,
    this.height,
    this.tokenEstimate,
  });

  factory ClipboardPasteDto.fromJson(Map<String, dynamic> json) =>
      _$ClipboardPasteDtoFromJson(json);

  @JsonKey(name: 'attached')
  final bool? attached;

  @JsonKey(name: 'message')
  final String? message;

  @JsonKey(name: 'path')
  final String? path;

  @JsonKey(name: 'count')
  final int? count;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'width')
  final int? width;

  @JsonKey(name: 'height')
  final int? height;

  @JsonKey(name: 'token_estimate')
  final int? tokenEstimate;

  Map<String, dynamic> toJson() => _$ClipboardPasteDtoToJson(this);

  ClipboardPasteResult toDomain() {
    final attachedValue = attached ?? false;
    ImageAttachment? imageAttachment;
    if (attachedValue && path != null) {
      imageAttachment = ImageAttachment(
        path: path!,
        name: name ?? '',
        count: count ?? 0,
        tokenEstimate: tokenEstimate,
        width: width,
        height: height,
      );
    }
    return ClipboardPasteResult(
      attached: attachedValue,
      message: message,
      image: imageAttachment,
    );
  }
}

/// Wire DTO for `paste.collapse` result.
@JsonSerializable()
class PasteCollapseDto {
  const PasteCollapseDto({this.placeholder, this.path, this.lines});

  factory PasteCollapseDto.fromJson(Map<String, dynamic> json) =>
      _$PasteCollapseDtoFromJson(json);

  @JsonKey(name: 'placeholder')
  final String? placeholder;

  @JsonKey(name: 'path')
  final String? path;

  @JsonKey(name: 'lines')
  final int? lines;

  Map<String, dynamic> toJson() => _$PasteCollapseDtoToJson(this);

  PasteCollapseResult toDomain() {
    return PasteCollapseResult(
      placeholder: placeholder ?? '',
      path: path ?? '',
      lines: lines ?? 0,
    );
  }
}
