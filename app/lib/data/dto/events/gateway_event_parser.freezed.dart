// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gateway_event_parser.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TypedGatewayEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TypedGatewayEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TypedGatewayEvent()';
}


}

/// @nodoc
class $TypedGatewayEventCopyWith<$Res>  {
$TypedGatewayEventCopyWith(TypedGatewayEvent _, $Res Function(TypedGatewayEvent) __);
}


/// Adds pattern-matching-related methods to [TypedGatewayEvent].
extension TypedGatewayEventPatterns on TypedGatewayEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GatewayReady value)?  gatewayReady,TResult Function( SessionInfo value)?  sessionInfo,TResult Function( MessageStart value)?  messageStart,TResult Function( MessageDelta value)?  messageDelta,TResult Function( MessageComplete value)?  messageComplete,TResult Function( TurnError value)?  turnError,TResult Function( ToolStart value)?  toolStart,TResult Function( ToolProgress value)?  toolProgress,TResult Function( ToolComplete value)?  toolComplete,TResult Function( ApprovalRequestEvent value)?  approvalRequest,TResult Function( ClarifyRequestEvent value)?  clarifyRequest,TResult Function( StatusUpdate value)?  statusUpdate,TResult Function( UnknownEvent value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GatewayReady() when gatewayReady != null:
return gatewayReady(_that);case SessionInfo() when sessionInfo != null:
return sessionInfo(_that);case MessageStart() when messageStart != null:
return messageStart(_that);case MessageDelta() when messageDelta != null:
return messageDelta(_that);case MessageComplete() when messageComplete != null:
return messageComplete(_that);case TurnError() when turnError != null:
return turnError(_that);case ToolStart() when toolStart != null:
return toolStart(_that);case ToolProgress() when toolProgress != null:
return toolProgress(_that);case ToolComplete() when toolComplete != null:
return toolComplete(_that);case ApprovalRequestEvent() when approvalRequest != null:
return approvalRequest(_that);case ClarifyRequestEvent() when clarifyRequest != null:
return clarifyRequest(_that);case StatusUpdate() when statusUpdate != null:
return statusUpdate(_that);case UnknownEvent() when unknown != null:
return unknown(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GatewayReady value)  gatewayReady,required TResult Function( SessionInfo value)  sessionInfo,required TResult Function( MessageStart value)  messageStart,required TResult Function( MessageDelta value)  messageDelta,required TResult Function( MessageComplete value)  messageComplete,required TResult Function( TurnError value)  turnError,required TResult Function( ToolStart value)  toolStart,required TResult Function( ToolProgress value)  toolProgress,required TResult Function( ToolComplete value)  toolComplete,required TResult Function( ApprovalRequestEvent value)  approvalRequest,required TResult Function( ClarifyRequestEvent value)  clarifyRequest,required TResult Function( StatusUpdate value)  statusUpdate,required TResult Function( UnknownEvent value)  unknown,}){
final _that = this;
switch (_that) {
case GatewayReady():
return gatewayReady(_that);case SessionInfo():
return sessionInfo(_that);case MessageStart():
return messageStart(_that);case MessageDelta():
return messageDelta(_that);case MessageComplete():
return messageComplete(_that);case TurnError():
return turnError(_that);case ToolStart():
return toolStart(_that);case ToolProgress():
return toolProgress(_that);case ToolComplete():
return toolComplete(_that);case ApprovalRequestEvent():
return approvalRequest(_that);case ClarifyRequestEvent():
return clarifyRequest(_that);case StatusUpdate():
return statusUpdate(_that);case UnknownEvent():
return unknown(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GatewayReady value)?  gatewayReady,TResult? Function( SessionInfo value)?  sessionInfo,TResult? Function( MessageStart value)?  messageStart,TResult? Function( MessageDelta value)?  messageDelta,TResult? Function( MessageComplete value)?  messageComplete,TResult? Function( TurnError value)?  turnError,TResult? Function( ToolStart value)?  toolStart,TResult? Function( ToolProgress value)?  toolProgress,TResult? Function( ToolComplete value)?  toolComplete,TResult? Function( ApprovalRequestEvent value)?  approvalRequest,TResult? Function( ClarifyRequestEvent value)?  clarifyRequest,TResult? Function( StatusUpdate value)?  statusUpdate,TResult? Function( UnknownEvent value)?  unknown,}){
final _that = this;
switch (_that) {
case GatewayReady() when gatewayReady != null:
return gatewayReady(_that);case SessionInfo() when sessionInfo != null:
return sessionInfo(_that);case MessageStart() when messageStart != null:
return messageStart(_that);case MessageDelta() when messageDelta != null:
return messageDelta(_that);case MessageComplete() when messageComplete != null:
return messageComplete(_that);case TurnError() when turnError != null:
return turnError(_that);case ToolStart() when toolStart != null:
return toolStart(_that);case ToolProgress() when toolProgress != null:
return toolProgress(_that);case ToolComplete() when toolComplete != null:
return toolComplete(_that);case ApprovalRequestEvent() when approvalRequest != null:
return approvalRequest(_that);case ClarifyRequestEvent() when clarifyRequest != null:
return clarifyRequest(_that);case StatusUpdate() when statusUpdate != null:
return statusUpdate(_that);case UnknownEvent() when unknown != null:
return unknown(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Map<String, dynamic> skin)?  gatewayReady,TResult Function( String? sessionId,  Map<String, dynamic> info)?  sessionInfo,TResult Function( String? sessionId)?  messageStart,TResult Function( String? sessionId,  String text,  String? rendered)?  messageDelta,TResult Function( String? sessionId,  String text,  String? rendered,  String? reasoning,  Usage? usage,  MessageTerminalStatus status)?  messageComplete,TResult Function( String? sessionId,  String? message)?  turnError,TResult Function( String? sessionId,  String toolId,  String name,  String? context,  String? argsText,  List<dynamic>? todos)?  toolStart,TResult Function( String? sessionId,  String name,  String preview)?  toolProgress,TResult Function( String? sessionId,  String toolId,  String name,  dynamic args,  dynamic result,  double? durationS,  String? summary,  String? resultText,  String? inlineDiff,  List<dynamic>? todos,  String? error)?  toolComplete,TResult Function( String? sessionId,  String command,  String description,  String? patternKey,  List<String> patternKeys,  bool allowPermanent)?  approvalRequest,TResult Function( String? sessionId,  String question,  List<String>? choices,  String requestId)?  clarifyRequest,TResult Function( String? sessionId,  String? kind,  String? text)?  statusUpdate,TResult Function( String type,  String? sessionId,  Map<String, dynamic> payload)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GatewayReady() when gatewayReady != null:
return gatewayReady(_that.skin);case SessionInfo() when sessionInfo != null:
return sessionInfo(_that.sessionId,_that.info);case MessageStart() when messageStart != null:
return messageStart(_that.sessionId);case MessageDelta() when messageDelta != null:
return messageDelta(_that.sessionId,_that.text,_that.rendered);case MessageComplete() when messageComplete != null:
return messageComplete(_that.sessionId,_that.text,_that.rendered,_that.reasoning,_that.usage,_that.status);case TurnError() when turnError != null:
return turnError(_that.sessionId,_that.message);case ToolStart() when toolStart != null:
return toolStart(_that.sessionId,_that.toolId,_that.name,_that.context,_that.argsText,_that.todos);case ToolProgress() when toolProgress != null:
return toolProgress(_that.sessionId,_that.name,_that.preview);case ToolComplete() when toolComplete != null:
return toolComplete(_that.sessionId,_that.toolId,_that.name,_that.args,_that.result,_that.durationS,_that.summary,_that.resultText,_that.inlineDiff,_that.todos,_that.error);case ApprovalRequestEvent() when approvalRequest != null:
return approvalRequest(_that.sessionId,_that.command,_that.description,_that.patternKey,_that.patternKeys,_that.allowPermanent);case ClarifyRequestEvent() when clarifyRequest != null:
return clarifyRequest(_that.sessionId,_that.question,_that.choices,_that.requestId);case StatusUpdate() when statusUpdate != null:
return statusUpdate(_that.sessionId,_that.kind,_that.text);case UnknownEvent() when unknown != null:
return unknown(_that.type,_that.sessionId,_that.payload);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Map<String, dynamic> skin)  gatewayReady,required TResult Function( String? sessionId,  Map<String, dynamic> info)  sessionInfo,required TResult Function( String? sessionId)  messageStart,required TResult Function( String? sessionId,  String text,  String? rendered)  messageDelta,required TResult Function( String? sessionId,  String text,  String? rendered,  String? reasoning,  Usage? usage,  MessageTerminalStatus status)  messageComplete,required TResult Function( String? sessionId,  String? message)  turnError,required TResult Function( String? sessionId,  String toolId,  String name,  String? context,  String? argsText,  List<dynamic>? todos)  toolStart,required TResult Function( String? sessionId,  String name,  String preview)  toolProgress,required TResult Function( String? sessionId,  String toolId,  String name,  dynamic args,  dynamic result,  double? durationS,  String? summary,  String? resultText,  String? inlineDiff,  List<dynamic>? todos,  String? error)  toolComplete,required TResult Function( String? sessionId,  String command,  String description,  String? patternKey,  List<String> patternKeys,  bool allowPermanent)  approvalRequest,required TResult Function( String? sessionId,  String question,  List<String>? choices,  String requestId)  clarifyRequest,required TResult Function( String? sessionId,  String? kind,  String? text)  statusUpdate,required TResult Function( String type,  String? sessionId,  Map<String, dynamic> payload)  unknown,}) {final _that = this;
switch (_that) {
case GatewayReady():
return gatewayReady(_that.skin);case SessionInfo():
return sessionInfo(_that.sessionId,_that.info);case MessageStart():
return messageStart(_that.sessionId);case MessageDelta():
return messageDelta(_that.sessionId,_that.text,_that.rendered);case MessageComplete():
return messageComplete(_that.sessionId,_that.text,_that.rendered,_that.reasoning,_that.usage,_that.status);case TurnError():
return turnError(_that.sessionId,_that.message);case ToolStart():
return toolStart(_that.sessionId,_that.toolId,_that.name,_that.context,_that.argsText,_that.todos);case ToolProgress():
return toolProgress(_that.sessionId,_that.name,_that.preview);case ToolComplete():
return toolComplete(_that.sessionId,_that.toolId,_that.name,_that.args,_that.result,_that.durationS,_that.summary,_that.resultText,_that.inlineDiff,_that.todos,_that.error);case ApprovalRequestEvent():
return approvalRequest(_that.sessionId,_that.command,_that.description,_that.patternKey,_that.patternKeys,_that.allowPermanent);case ClarifyRequestEvent():
return clarifyRequest(_that.sessionId,_that.question,_that.choices,_that.requestId);case StatusUpdate():
return statusUpdate(_that.sessionId,_that.kind,_that.text);case UnknownEvent():
return unknown(_that.type,_that.sessionId,_that.payload);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Map<String, dynamic> skin)?  gatewayReady,TResult? Function( String? sessionId,  Map<String, dynamic> info)?  sessionInfo,TResult? Function( String? sessionId)?  messageStart,TResult? Function( String? sessionId,  String text,  String? rendered)?  messageDelta,TResult? Function( String? sessionId,  String text,  String? rendered,  String? reasoning,  Usage? usage,  MessageTerminalStatus status)?  messageComplete,TResult? Function( String? sessionId,  String? message)?  turnError,TResult? Function( String? sessionId,  String toolId,  String name,  String? context,  String? argsText,  List<dynamic>? todos)?  toolStart,TResult? Function( String? sessionId,  String name,  String preview)?  toolProgress,TResult? Function( String? sessionId,  String toolId,  String name,  dynamic args,  dynamic result,  double? durationS,  String? summary,  String? resultText,  String? inlineDiff,  List<dynamic>? todos,  String? error)?  toolComplete,TResult? Function( String? sessionId,  String command,  String description,  String? patternKey,  List<String> patternKeys,  bool allowPermanent)?  approvalRequest,TResult? Function( String? sessionId,  String question,  List<String>? choices,  String requestId)?  clarifyRequest,TResult? Function( String? sessionId,  String? kind,  String? text)?  statusUpdate,TResult? Function( String type,  String? sessionId,  Map<String, dynamic> payload)?  unknown,}) {final _that = this;
switch (_that) {
case GatewayReady() when gatewayReady != null:
return gatewayReady(_that.skin);case SessionInfo() when sessionInfo != null:
return sessionInfo(_that.sessionId,_that.info);case MessageStart() when messageStart != null:
return messageStart(_that.sessionId);case MessageDelta() when messageDelta != null:
return messageDelta(_that.sessionId,_that.text,_that.rendered);case MessageComplete() when messageComplete != null:
return messageComplete(_that.sessionId,_that.text,_that.rendered,_that.reasoning,_that.usage,_that.status);case TurnError() when turnError != null:
return turnError(_that.sessionId,_that.message);case ToolStart() when toolStart != null:
return toolStart(_that.sessionId,_that.toolId,_that.name,_that.context,_that.argsText,_that.todos);case ToolProgress() when toolProgress != null:
return toolProgress(_that.sessionId,_that.name,_that.preview);case ToolComplete() when toolComplete != null:
return toolComplete(_that.sessionId,_that.toolId,_that.name,_that.args,_that.result,_that.durationS,_that.summary,_that.resultText,_that.inlineDiff,_that.todos,_that.error);case ApprovalRequestEvent() when approvalRequest != null:
return approvalRequest(_that.sessionId,_that.command,_that.description,_that.patternKey,_that.patternKeys,_that.allowPermanent);case ClarifyRequestEvent() when clarifyRequest != null:
return clarifyRequest(_that.sessionId,_that.question,_that.choices,_that.requestId);case StatusUpdate() when statusUpdate != null:
return statusUpdate(_that.sessionId,_that.kind,_that.text);case UnknownEvent() when unknown != null:
return unknown(_that.type,_that.sessionId,_that.payload);case _:
  return null;

}
}

}

/// @nodoc


class GatewayReady implements TypedGatewayEvent {
  const GatewayReady({required final  Map<String, dynamic> skin}): _skin = skin;
  

 final  Map<String, dynamic> _skin;
 Map<String, dynamic> get skin {
  if (_skin is EqualUnmodifiableMapView) return _skin;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_skin);
}


/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GatewayReadyCopyWith<GatewayReady> get copyWith => _$GatewayReadyCopyWithImpl<GatewayReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GatewayReady&&const DeepCollectionEquality().equals(other._skin, _skin));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_skin));

@override
String toString() {
  return 'TypedGatewayEvent.gatewayReady(skin: $skin)';
}


}

/// @nodoc
abstract mixin class $GatewayReadyCopyWith<$Res> implements $TypedGatewayEventCopyWith<$Res> {
  factory $GatewayReadyCopyWith(GatewayReady value, $Res Function(GatewayReady) _then) = _$GatewayReadyCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic> skin
});




}
/// @nodoc
class _$GatewayReadyCopyWithImpl<$Res>
    implements $GatewayReadyCopyWith<$Res> {
  _$GatewayReadyCopyWithImpl(this._self, this._then);

  final GatewayReady _self;
  final $Res Function(GatewayReady) _then;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? skin = null,}) {
  return _then(GatewayReady(
skin: null == skin ? _self._skin : skin // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc


class SessionInfo implements TypedGatewayEvent {
  const SessionInfo({required this.sessionId, required final  Map<String, dynamic> info}): _info = info;
  

 final  String? sessionId;
 final  Map<String, dynamic> _info;
 Map<String, dynamic> get info {
  if (_info is EqualUnmodifiableMapView) return _info;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_info);
}


/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionInfoCopyWith<SessionInfo> get copyWith => _$SessionInfoCopyWithImpl<SessionInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionInfo&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other._info, _info));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,const DeepCollectionEquality().hash(_info));

@override
String toString() {
  return 'TypedGatewayEvent.sessionInfo(sessionId: $sessionId, info: $info)';
}


}

/// @nodoc
abstract mixin class $SessionInfoCopyWith<$Res> implements $TypedGatewayEventCopyWith<$Res> {
  factory $SessionInfoCopyWith(SessionInfo value, $Res Function(SessionInfo) _then) = _$SessionInfoCopyWithImpl;
@useResult
$Res call({
 String? sessionId, Map<String, dynamic> info
});




}
/// @nodoc
class _$SessionInfoCopyWithImpl<$Res>
    implements $SessionInfoCopyWith<$Res> {
  _$SessionInfoCopyWithImpl(this._self, this._then);

  final SessionInfo _self;
  final $Res Function(SessionInfo) _then;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,Object? info = null,}) {
  return _then(SessionInfo(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,info: null == info ? _self._info : info // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc


class MessageStart implements TypedGatewayEvent {
  const MessageStart({required this.sessionId});
  

 final  String? sessionId;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageStartCopyWith<MessageStart> get copyWith => _$MessageStartCopyWithImpl<MessageStart>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageStart&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId);

@override
String toString() {
  return 'TypedGatewayEvent.messageStart(sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class $MessageStartCopyWith<$Res> implements $TypedGatewayEventCopyWith<$Res> {
  factory $MessageStartCopyWith(MessageStart value, $Res Function(MessageStart) _then) = _$MessageStartCopyWithImpl;
@useResult
$Res call({
 String? sessionId
});




}
/// @nodoc
class _$MessageStartCopyWithImpl<$Res>
    implements $MessageStartCopyWith<$Res> {
  _$MessageStartCopyWithImpl(this._self, this._then);

  final MessageStart _self;
  final $Res Function(MessageStart) _then;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,}) {
  return _then(MessageStart(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class MessageDelta implements TypedGatewayEvent {
  const MessageDelta({required this.sessionId, required this.text, this.rendered});
  

 final  String? sessionId;
 final  String text;
 final  String? rendered;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageDeltaCopyWith<MessageDelta> get copyWith => _$MessageDeltaCopyWithImpl<MessageDelta>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageDelta&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.text, text) || other.text == text)&&(identical(other.rendered, rendered) || other.rendered == rendered));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,text,rendered);

@override
String toString() {
  return 'TypedGatewayEvent.messageDelta(sessionId: $sessionId, text: $text, rendered: $rendered)';
}


}

/// @nodoc
abstract mixin class $MessageDeltaCopyWith<$Res> implements $TypedGatewayEventCopyWith<$Res> {
  factory $MessageDeltaCopyWith(MessageDelta value, $Res Function(MessageDelta) _then) = _$MessageDeltaCopyWithImpl;
@useResult
$Res call({
 String? sessionId, String text, String? rendered
});




}
/// @nodoc
class _$MessageDeltaCopyWithImpl<$Res>
    implements $MessageDeltaCopyWith<$Res> {
  _$MessageDeltaCopyWithImpl(this._self, this._then);

  final MessageDelta _self;
  final $Res Function(MessageDelta) _then;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,Object? text = null,Object? rendered = freezed,}) {
  return _then(MessageDelta(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,rendered: freezed == rendered ? _self.rendered : rendered // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class MessageComplete implements TypedGatewayEvent {
  const MessageComplete({required this.sessionId, required this.text, this.rendered, this.reasoning, this.usage, required this.status});
  

 final  String? sessionId;
 final  String text;
 final  String? rendered;
 final  String? reasoning;
 final  Usage? usage;
 final  MessageTerminalStatus status;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCompleteCopyWith<MessageComplete> get copyWith => _$MessageCompleteCopyWithImpl<MessageComplete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageComplete&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.text, text) || other.text == text)&&(identical(other.rendered, rendered) || other.rendered == rendered)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,text,rendered,reasoning,usage,status);

@override
String toString() {
  return 'TypedGatewayEvent.messageComplete(sessionId: $sessionId, text: $text, rendered: $rendered, reasoning: $reasoning, usage: $usage, status: $status)';
}


}

/// @nodoc
abstract mixin class $MessageCompleteCopyWith<$Res> implements $TypedGatewayEventCopyWith<$Res> {
  factory $MessageCompleteCopyWith(MessageComplete value, $Res Function(MessageComplete) _then) = _$MessageCompleteCopyWithImpl;
@useResult
$Res call({
 String? sessionId, String text, String? rendered, String? reasoning, Usage? usage, MessageTerminalStatus status
});




}
/// @nodoc
class _$MessageCompleteCopyWithImpl<$Res>
    implements $MessageCompleteCopyWith<$Res> {
  _$MessageCompleteCopyWithImpl(this._self, this._then);

  final MessageComplete _self;
  final $Res Function(MessageComplete) _then;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,Object? text = null,Object? rendered = freezed,Object? reasoning = freezed,Object? usage = freezed,Object? status = null,}) {
  return _then(MessageComplete(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,rendered: freezed == rendered ? _self.rendered : rendered // ignore: cast_nullable_to_non_nullable
as String?,reasoning: freezed == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String?,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as Usage?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageTerminalStatus,
  ));
}


}

/// @nodoc


class TurnError implements TypedGatewayEvent {
  const TurnError({required this.sessionId, this.message});
  

 final  String? sessionId;
 final  String? message;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TurnErrorCopyWith<TurnError> get copyWith => _$TurnErrorCopyWithImpl<TurnError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TurnError&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,message);

@override
String toString() {
  return 'TypedGatewayEvent.turnError(sessionId: $sessionId, message: $message)';
}


}

/// @nodoc
abstract mixin class $TurnErrorCopyWith<$Res> implements $TypedGatewayEventCopyWith<$Res> {
  factory $TurnErrorCopyWith(TurnError value, $Res Function(TurnError) _then) = _$TurnErrorCopyWithImpl;
@useResult
$Res call({
 String? sessionId, String? message
});




}
/// @nodoc
class _$TurnErrorCopyWithImpl<$Res>
    implements $TurnErrorCopyWith<$Res> {
  _$TurnErrorCopyWithImpl(this._self, this._then);

  final TurnError _self;
  final $Res Function(TurnError) _then;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,Object? message = freezed,}) {
  return _then(TurnError(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ToolStart implements TypedGatewayEvent {
  const ToolStart({required this.sessionId, required this.toolId, required this.name, this.context, this.argsText, final  List<dynamic>? todos}): _todos = todos;
  

 final  String? sessionId;
 final  String toolId;
 final  String name;
 final  String? context;
 final  String? argsText;
 final  List<dynamic>? _todos;
 List<dynamic>? get todos {
  final value = _todos;
  if (value == null) return null;
  if (_todos is EqualUnmodifiableListView) return _todos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolStartCopyWith<ToolStart> get copyWith => _$ToolStartCopyWithImpl<ToolStart>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolStart&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.toolId, toolId) || other.toolId == toolId)&&(identical(other.name, name) || other.name == name)&&(identical(other.context, context) || other.context == context)&&(identical(other.argsText, argsText) || other.argsText == argsText)&&const DeepCollectionEquality().equals(other._todos, _todos));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,toolId,name,context,argsText,const DeepCollectionEquality().hash(_todos));

@override
String toString() {
  return 'TypedGatewayEvent.toolStart(sessionId: $sessionId, toolId: $toolId, name: $name, context: $context, argsText: $argsText, todos: $todos)';
}


}

/// @nodoc
abstract mixin class $ToolStartCopyWith<$Res> implements $TypedGatewayEventCopyWith<$Res> {
  factory $ToolStartCopyWith(ToolStart value, $Res Function(ToolStart) _then) = _$ToolStartCopyWithImpl;
@useResult
$Res call({
 String? sessionId, String toolId, String name, String? context, String? argsText, List<dynamic>? todos
});




}
/// @nodoc
class _$ToolStartCopyWithImpl<$Res>
    implements $ToolStartCopyWith<$Res> {
  _$ToolStartCopyWithImpl(this._self, this._then);

  final ToolStart _self;
  final $Res Function(ToolStart) _then;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,Object? toolId = null,Object? name = null,Object? context = freezed,Object? argsText = freezed,Object? todos = freezed,}) {
  return _then(ToolStart(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,toolId: null == toolId ? _self.toolId : toolId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,context: freezed == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String?,argsText: freezed == argsText ? _self.argsText : argsText // ignore: cast_nullable_to_non_nullable
as String?,todos: freezed == todos ? _self._todos : todos // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,
  ));
}


}

/// @nodoc


class ToolProgress implements TypedGatewayEvent {
  const ToolProgress({required this.sessionId, required this.name, required this.preview});
  

 final  String? sessionId;
 final  String name;
 final  String preview;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolProgressCopyWith<ToolProgress> get copyWith => _$ToolProgressCopyWithImpl<ToolProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolProgress&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.name, name) || other.name == name)&&(identical(other.preview, preview) || other.preview == preview));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,name,preview);

@override
String toString() {
  return 'TypedGatewayEvent.toolProgress(sessionId: $sessionId, name: $name, preview: $preview)';
}


}

/// @nodoc
abstract mixin class $ToolProgressCopyWith<$Res> implements $TypedGatewayEventCopyWith<$Res> {
  factory $ToolProgressCopyWith(ToolProgress value, $Res Function(ToolProgress) _then) = _$ToolProgressCopyWithImpl;
@useResult
$Res call({
 String? sessionId, String name, String preview
});




}
/// @nodoc
class _$ToolProgressCopyWithImpl<$Res>
    implements $ToolProgressCopyWith<$Res> {
  _$ToolProgressCopyWithImpl(this._self, this._then);

  final ToolProgress _self;
  final $Res Function(ToolProgress) _then;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,Object? name = null,Object? preview = null,}) {
  return _then(ToolProgress(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ToolComplete implements TypedGatewayEvent {
  const ToolComplete({required this.sessionId, required this.toolId, required this.name, this.args, this.result, this.durationS, this.summary, this.resultText, this.inlineDiff, final  List<dynamic>? todos, this.error}): _todos = todos;
  

 final  String? sessionId;
 final  String toolId;
 final  String name;
 final  dynamic args;
 final  dynamic result;
 final  double? durationS;
 final  String? summary;
 final  String? resultText;
 final  String? inlineDiff;
 final  List<dynamic>? _todos;
 List<dynamic>? get todos {
  final value = _todos;
  if (value == null) return null;
  if (_todos is EqualUnmodifiableListView) return _todos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  String? error;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolCompleteCopyWith<ToolComplete> get copyWith => _$ToolCompleteCopyWithImpl<ToolComplete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolComplete&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.toolId, toolId) || other.toolId == toolId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.args, args)&&const DeepCollectionEquality().equals(other.result, result)&&(identical(other.durationS, durationS) || other.durationS == durationS)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.resultText, resultText) || other.resultText == resultText)&&(identical(other.inlineDiff, inlineDiff) || other.inlineDiff == inlineDiff)&&const DeepCollectionEquality().equals(other._todos, _todos)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,toolId,name,const DeepCollectionEquality().hash(args),const DeepCollectionEquality().hash(result),durationS,summary,resultText,inlineDiff,const DeepCollectionEquality().hash(_todos),error);

@override
String toString() {
  return 'TypedGatewayEvent.toolComplete(sessionId: $sessionId, toolId: $toolId, name: $name, args: $args, result: $result, durationS: $durationS, summary: $summary, resultText: $resultText, inlineDiff: $inlineDiff, todos: $todos, error: $error)';
}


}

/// @nodoc
abstract mixin class $ToolCompleteCopyWith<$Res> implements $TypedGatewayEventCopyWith<$Res> {
  factory $ToolCompleteCopyWith(ToolComplete value, $Res Function(ToolComplete) _then) = _$ToolCompleteCopyWithImpl;
@useResult
$Res call({
 String? sessionId, String toolId, String name, dynamic args, dynamic result, double? durationS, String? summary, String? resultText, String? inlineDiff, List<dynamic>? todos, String? error
});




}
/// @nodoc
class _$ToolCompleteCopyWithImpl<$Res>
    implements $ToolCompleteCopyWith<$Res> {
  _$ToolCompleteCopyWithImpl(this._self, this._then);

  final ToolComplete _self;
  final $Res Function(ToolComplete) _then;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,Object? toolId = null,Object? name = null,Object? args = freezed,Object? result = freezed,Object? durationS = freezed,Object? summary = freezed,Object? resultText = freezed,Object? inlineDiff = freezed,Object? todos = freezed,Object? error = freezed,}) {
  return _then(ToolComplete(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,toolId: null == toolId ? _self.toolId : toolId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,args: freezed == args ? _self.args : args // ignore: cast_nullable_to_non_nullable
as dynamic,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as dynamic,durationS: freezed == durationS ? _self.durationS : durationS // ignore: cast_nullable_to_non_nullable
as double?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,resultText: freezed == resultText ? _self.resultText : resultText // ignore: cast_nullable_to_non_nullable
as String?,inlineDiff: freezed == inlineDiff ? _self.inlineDiff : inlineDiff // ignore: cast_nullable_to_non_nullable
as String?,todos: freezed == todos ? _self._todos : todos // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ApprovalRequestEvent implements TypedGatewayEvent {
  const ApprovalRequestEvent({required this.sessionId, required this.command, required this.description, this.patternKey, required final  List<String> patternKeys, required this.allowPermanent}): _patternKeys = patternKeys;
  

 final  String? sessionId;
 final  String command;
 final  String description;
 final  String? patternKey;
 final  List<String> _patternKeys;
 List<String> get patternKeys {
  if (_patternKeys is EqualUnmodifiableListView) return _patternKeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_patternKeys);
}

 final  bool allowPermanent;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApprovalRequestEventCopyWith<ApprovalRequestEvent> get copyWith => _$ApprovalRequestEventCopyWithImpl<ApprovalRequestEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApprovalRequestEvent&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.command, command) || other.command == command)&&(identical(other.description, description) || other.description == description)&&(identical(other.patternKey, patternKey) || other.patternKey == patternKey)&&const DeepCollectionEquality().equals(other._patternKeys, _patternKeys)&&(identical(other.allowPermanent, allowPermanent) || other.allowPermanent == allowPermanent));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,command,description,patternKey,const DeepCollectionEquality().hash(_patternKeys),allowPermanent);

@override
String toString() {
  return 'TypedGatewayEvent.approvalRequest(sessionId: $sessionId, command: $command, description: $description, patternKey: $patternKey, patternKeys: $patternKeys, allowPermanent: $allowPermanent)';
}


}

/// @nodoc
abstract mixin class $ApprovalRequestEventCopyWith<$Res> implements $TypedGatewayEventCopyWith<$Res> {
  factory $ApprovalRequestEventCopyWith(ApprovalRequestEvent value, $Res Function(ApprovalRequestEvent) _then) = _$ApprovalRequestEventCopyWithImpl;
@useResult
$Res call({
 String? sessionId, String command, String description, String? patternKey, List<String> patternKeys, bool allowPermanent
});




}
/// @nodoc
class _$ApprovalRequestEventCopyWithImpl<$Res>
    implements $ApprovalRequestEventCopyWith<$Res> {
  _$ApprovalRequestEventCopyWithImpl(this._self, this._then);

  final ApprovalRequestEvent _self;
  final $Res Function(ApprovalRequestEvent) _then;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,Object? command = null,Object? description = null,Object? patternKey = freezed,Object? patternKeys = null,Object? allowPermanent = null,}) {
  return _then(ApprovalRequestEvent(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,patternKey: freezed == patternKey ? _self.patternKey : patternKey // ignore: cast_nullable_to_non_nullable
as String?,patternKeys: null == patternKeys ? _self._patternKeys : patternKeys // ignore: cast_nullable_to_non_nullable
as List<String>,allowPermanent: null == allowPermanent ? _self.allowPermanent : allowPermanent // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class ClarifyRequestEvent implements TypedGatewayEvent {
  const ClarifyRequestEvent({required this.sessionId, required this.question, final  List<String>? choices, required this.requestId}): _choices = choices;
  

 final  String? sessionId;
 final  String question;
 final  List<String>? _choices;
 List<String>? get choices {
  final value = _choices;
  if (value == null) return null;
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  String requestId;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClarifyRequestEventCopyWith<ClarifyRequestEvent> get copyWith => _$ClarifyRequestEventCopyWithImpl<ClarifyRequestEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClarifyRequestEvent&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other._choices, _choices)&&(identical(other.requestId, requestId) || other.requestId == requestId));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,question,const DeepCollectionEquality().hash(_choices),requestId);

@override
String toString() {
  return 'TypedGatewayEvent.clarifyRequest(sessionId: $sessionId, question: $question, choices: $choices, requestId: $requestId)';
}


}

/// @nodoc
abstract mixin class $ClarifyRequestEventCopyWith<$Res> implements $TypedGatewayEventCopyWith<$Res> {
  factory $ClarifyRequestEventCopyWith(ClarifyRequestEvent value, $Res Function(ClarifyRequestEvent) _then) = _$ClarifyRequestEventCopyWithImpl;
@useResult
$Res call({
 String? sessionId, String question, List<String>? choices, String requestId
});




}
/// @nodoc
class _$ClarifyRequestEventCopyWithImpl<$Res>
    implements $ClarifyRequestEventCopyWith<$Res> {
  _$ClarifyRequestEventCopyWithImpl(this._self, this._then);

  final ClarifyRequestEvent _self;
  final $Res Function(ClarifyRequestEvent) _then;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,Object? question = null,Object? choices = freezed,Object? requestId = null,}) {
  return _then(ClarifyRequestEvent(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,choices: freezed == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<String>?,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StatusUpdate implements TypedGatewayEvent {
  const StatusUpdate({required this.sessionId, this.kind, this.text});
  

 final  String? sessionId;
 final  String? kind;
 final  String? text;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatusUpdateCopyWith<StatusUpdate> get copyWith => _$StatusUpdateCopyWithImpl<StatusUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatusUpdate&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,kind,text);

@override
String toString() {
  return 'TypedGatewayEvent.statusUpdate(sessionId: $sessionId, kind: $kind, text: $text)';
}


}

/// @nodoc
abstract mixin class $StatusUpdateCopyWith<$Res> implements $TypedGatewayEventCopyWith<$Res> {
  factory $StatusUpdateCopyWith(StatusUpdate value, $Res Function(StatusUpdate) _then) = _$StatusUpdateCopyWithImpl;
@useResult
$Res call({
 String? sessionId, String? kind, String? text
});




}
/// @nodoc
class _$StatusUpdateCopyWithImpl<$Res>
    implements $StatusUpdateCopyWith<$Res> {
  _$StatusUpdateCopyWithImpl(this._self, this._then);

  final StatusUpdate _self;
  final $Res Function(StatusUpdate) _then;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,Object? kind = freezed,Object? text = freezed,}) {
  return _then(StatusUpdate(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UnknownEvent implements TypedGatewayEvent {
  const UnknownEvent({required this.type, required this.sessionId, required final  Map<String, dynamic> payload}): _payload = payload;
  

 final  String type;
 final  String? sessionId;
 final  Map<String, dynamic> _payload;
 Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}


/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownEventCopyWith<UnknownEvent> get copyWith => _$UnknownEventCopyWithImpl<UnknownEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownEvent&&(identical(other.type, type) || other.type == type)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&const DeepCollectionEquality().equals(other._payload, _payload));
}


@override
int get hashCode => Object.hash(runtimeType,type,sessionId,const DeepCollectionEquality().hash(_payload));

@override
String toString() {
  return 'TypedGatewayEvent.unknown(type: $type, sessionId: $sessionId, payload: $payload)';
}


}

/// @nodoc
abstract mixin class $UnknownEventCopyWith<$Res> implements $TypedGatewayEventCopyWith<$Res> {
  factory $UnknownEventCopyWith(UnknownEvent value, $Res Function(UnknownEvent) _then) = _$UnknownEventCopyWithImpl;
@useResult
$Res call({
 String type, String? sessionId, Map<String, dynamic> payload
});




}
/// @nodoc
class _$UnknownEventCopyWithImpl<$Res>
    implements $UnknownEventCopyWith<$Res> {
  _$UnknownEventCopyWithImpl(this._self, this._then);

  final UnknownEvent _self;
  final $Res Function(UnknownEvent) _then;

/// Create a copy of TypedGatewayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,Object? sessionId = freezed,Object? payload = null,}) {
  return _then(UnknownEvent(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
