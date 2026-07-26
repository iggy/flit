// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageAttachDto _$ImageAttachDtoFromJson(Map<String, dynamic> json) =>
    ImageAttachDto(
      path: json['path'] as String?,
      name: json['name'] as String?,
      count: (json['count'] as num?)?.toInt(),
      tokenEstimate: (json['token_estimate'] as num?)?.toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      bytes: (json['bytes'] as num?)?.toInt(),
      text: json['text'] as String?,
      remainder: json['remainder'] as String?,
    );

Map<String, dynamic> _$ImageAttachDtoToJson(ImageAttachDto instance) =>
    <String, dynamic>{
      'path': instance.path,
      'name': instance.name,
      'count': instance.count,
      'token_estimate': instance.tokenEstimate,
      'width': instance.width,
      'height': instance.height,
      'bytes': instance.bytes,
      'text': instance.text,
      'remainder': instance.remainder,
    };

DetachResultDto _$DetachResultDtoFromJson(Map<String, dynamic> json) =>
    DetachResultDto(
      detached: json['detached'] as bool?,
      count: (json['count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DetachResultDtoToJson(DetachResultDto instance) =>
    <String, dynamic>{'detached': instance.detached, 'count': instance.count};

PdfAttachDto _$PdfAttachDtoFromJson(Map<String, dynamic> json) => PdfAttachDto(
  attached: json['attached'] as bool?,
  filename: json['filename'] as String?,
  pagesAttached: (json['pages_attached'] as num?)?.toInt(),
  pages:
      (json['pages'] as List<dynamic>?)
          ?.map((e) => ImageAttachDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ImageAttachDto>[],
  count: (json['count'] as num?)?.toInt(),
  text: json['text'] as String?,
);

Map<String, dynamic> _$PdfAttachDtoToJson(PdfAttachDto instance) =>
    <String, dynamic>{
      'attached': instance.attached,
      'filename': instance.filename,
      'pages_attached': instance.pagesAttached,
      'pages': instance.pages,
      'count': instance.count,
      'text': instance.text,
    };

FileAttachDto _$FileAttachDtoFromJson(Map<String, dynamic> json) =>
    FileAttachDto(
      attached: json['attached'] as bool?,
      name: json['name'] as String?,
      path: json['path'] as String?,
      refPath: json['ref_path'] as String?,
      refText: json['ref_text'] as String?,
      uploaded: json['uploaded'] as bool?,
    );

Map<String, dynamic> _$FileAttachDtoToJson(FileAttachDto instance) =>
    <String, dynamic>{
      'attached': instance.attached,
      'name': instance.name,
      'path': instance.path,
      'ref_path': instance.refPath,
      'ref_text': instance.refText,
      'uploaded': instance.uploaded,
    };

DropDetectionDto _$DropDetectionDtoFromJson(Map<String, dynamic> json) =>
    DropDetectionDto(
      matched: json['matched'] as bool?,
      isImage: json['is_image'] as bool?,
      path: json['path'] as String?,
      name: json['name'] as String?,
      text: json['text'] as String?,
      count: (json['count'] as num?)?.toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      tokenEstimate: (json['token_estimate'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DropDetectionDtoToJson(DropDetectionDto instance) =>
    <String, dynamic>{
      'matched': instance.matched,
      'is_image': instance.isImage,
      'path': instance.path,
      'name': instance.name,
      'text': instance.text,
      'count': instance.count,
      'width': instance.width,
      'height': instance.height,
      'token_estimate': instance.tokenEstimate,
    };

ClipboardPasteDto _$ClipboardPasteDtoFromJson(Map<String, dynamic> json) =>
    ClipboardPasteDto(
      attached: json['attached'] as bool?,
      message: json['message'] as String?,
      path: json['path'] as String?,
      count: (json['count'] as num?)?.toInt(),
      name: json['name'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      tokenEstimate: (json['token_estimate'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ClipboardPasteDtoToJson(ClipboardPasteDto instance) =>
    <String, dynamic>{
      'attached': instance.attached,
      'message': instance.message,
      'path': instance.path,
      'count': instance.count,
      'name': instance.name,
      'width': instance.width,
      'height': instance.height,
      'token_estimate': instance.tokenEstimate,
    };

PasteCollapseDto _$PasteCollapseDtoFromJson(Map<String, dynamic> json) =>
    PasteCollapseDto(
      placeholder: json['placeholder'] as String?,
      path: json['path'] as String?,
      lines: (json['lines'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PasteCollapseDtoToJson(PasteCollapseDto instance) =>
    <String, dynamic>{
      'placeholder': instance.placeholder,
      'path': instance.path,
      'lines': instance.lines,
    };
