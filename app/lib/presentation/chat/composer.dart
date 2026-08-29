/// The composer (ticket P1-07): a multiline text field with a Send button.
/// While the active session is streaming/working, submitting non-empty text
/// steers the running turn (P3-07) instead of starting a new turn. The Stop
/// button calls `session.interrupt`. Disabled with a hint when there is no
/// active session.
///
/// P3-02: inline slash autocomplete — when text starts with `/` (no space yet),
/// show completions above the field; tapping a suggestion replaces the text.
///
/// P3-03: slash dispatch — text starting with `/` is routed to command.dispatch
/// instead of submitPrompt; dispatch results fan out to prefill/send/exec/skill.
///
/// A send the gateway acknowledges as `queued` is tracked in
/// [promptQueueProvider] and shown above the field, because Stop DISCARDS the
/// queue rather than just stopping the turn (see prompt_queue.dart).
///
/// Key handling: Enter submits (when the field is effectively used
/// single-line, the common chat case); Shift+Enter inserts a newline.
library;

import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flit/application/attachments/attachment_providers.dart';
import 'package:flit/application/chat/composer_prefill.dart';
import 'package:flit/application/chat/message_list_notifier.dart';
import 'package:flit/application/chat/prompt_queue.dart';
import 'package:flit/application/providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/sessions/desktop_contract.dart';
import 'package:flit/application/sessions/session_list.dart';
import 'package:flit/application/slash/slash_providers.dart';
import 'package:flit/application/voice/client_voice_providers.dart';
import 'package:flit/application/voice/voice_providers.dart';
import 'package:flit/core/debug/voice_debug.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/attachment.dart';
import 'package:flit/domain/models/chat_message.dart';
import 'package:flit/domain/models/command_dispatch.dart';
import 'package:flit/domain/models/prompt_submit_status.dart';
import 'package:flit/domain/models/slash_completion.dart';
import 'package:flit/domain/models/steer_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Key of the composer's text field (widget tests target it directly).
const Key composerFieldKey = Key('composer_field');

/// Key of the send button.
const Key composerSendKey = Key('composer_send');

/// Key of the stop button (shown while a turn is in flight).
const Key composerStopKey = Key('composer_stop');

/// Key of the steer button (shown while a turn is in flight).
const Key composerSteerKey = Key('composer_steer');

/// Key of the queued-prompts notice (shown while the gateway holds queued
/// submissions for the active session).
const Key composerQueuedNoticeKey = Key('composer_queued_notice');

class Composer extends ConsumerStatefulWidget {
  const Composer({super.key});

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);

  /// P3-02: slash suggestions (null when none; empty list triggers no overlay).
  List<CompletionItem>? _suggestions;

  /// Request generation counter to ignore stale async completeSlash results.
  int _completionRequestGen = 0;

  /// P7: local thumbnail bytes keyed by attachment path (server-side path).
  final Map<String, Uint8List> _localThumbs = <String, Uint8List>{};

  /// P7: track voice error to detect changes (avoid snackbar spam).
  String? _lastVoiceError;

  /// P7 rework: track client-capture voice error to detect changes.
  String? _lastClientVoiceError;

  /// P7: track whether we've done the initial voice status refresh.
  bool _voiceStatusRefreshed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// P3-02: trigger autocomplete on text change.
  void _onTextChanged() {
    final text = _controller.text;
    // Trigger only when text starts with `/` and has no space yet.
    if (text.startsWith('/') && !text.contains(' ')) {
      _fetchCompletions(text);
    } else {
      setState(() {
        _suggestions = null;
      });
    }
  }

  /// P3-02: fetch completions from the repository, guarding against overlapping requests.
  Future<void> _fetchCompletions(String text) async {
    final repo = ref.read(slashRepositoryProvider);
    if (repo == null) {
      return;
    }
    _completionRequestGen++;
    final thisGen = _completionRequestGen;
    try {
      final result = await repo.completeSlash(text);
      if (thisGen == _completionRequestGen && mounted) {
        setState(() {
          _suggestions = result.items;
        });
      }
    } on Object {
      // Silently ignore completion failures (e.g., disconnected mid-request).
      if (thisGen == _completionRequestGen && mounted) {
        setState(() {
          _suggestions = null;
        });
      }
    }
  }

  /// P3-02: replace field text with the selected completion item.
  void _applySuggestion(CompletionItem item) {
    _controller.text = item.text;
    _controller.selection = TextSelection.collapsed(offset: item.text.length);
    setState(() {
      _suggestions = null;
    });
    _focusNode.requestFocus();
  }

  /// Enter → submit; Shift+Enter → let the editable insert a newline.
  /// The handler lives on the focus NODE so it runs before the editable's
  /// own Enter handling (which would otherwise consume the event).
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final shiftHeld =
        pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
    if (shiftHeld) {
      return KeyEventResult.ignored;
    }
    _submit();
    return KeyEventResult.handled;
  }

  void _submit() {
    final liveId = ref.read(activeSessionProvider).liveId;
    if (liveId == null) {
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    // P3-03: route slash commands to dispatch.
    if (text.startsWith('/')) {
      _controller.clear();
      setState(() {
        _suggestions = null;
      });
      unawaited(_dispatchSlash(liveId, text));
      return;
    }
    final working = ref
        .read(messageListProvider(liveId))
        .messages
        .any((message) => message.streaming);
    _controller.clear();
    setState(() {
      _suggestions = null;
    });
    if (working) {
      unawaited(_steer(liveId, text));
      return;
    }
    // User messages are appended by the CALLER, never by the fold
    // (04-app-architecture.md).
    ref.read(messageListProvider(liveId).notifier).appendUserMessage(text);
    unawaited(_send(liveId, text));
  }

  Future<void> _send(String liveId, String text) async {
    try {
      final result = await ref
          .read(chatRepositoryProvider)
          ?.submitPrompt(liveId, text);
      // P7: clear staged attachments after successful send (gateway auto-consumes).
      ref.read(stagedAttachmentsProvider.notifier).clear();
      _localThumbs.clear();
      // The session was busy when the prompt landed (gateway 0.20
      // `_handle_busy_submit`): surface how it was disposed instead of
      // letting it look like a failed send or a phantom stream.
      if (result != null && mounted) {
        switch (result.status) {
          case PromptSubmitStatus.queued:
            // Remember it: the gateway drops the whole queue on interrupt
            // (see prompt_queue.dart), and nothing on the wire reports it.
            ref.read(promptQueueProvider(liveId).notifier).enqueue(text);
            _showSnackBar('Queued — will run after the current turn');
          case PromptSubmitStatus.steered:
            _showSnackBar('Steered into the current turn');
          case PromptSubmitStatus.redirected:
            _showSnackBar('Current turn redirected to your message');
          case PromptSubmitStatus.streaming:
            break;
        }
      }
    } on Object catch (error) {
      _showError('Failed to send', error);
    }
  }

  Future<void> _stop(String liveId) async {
    // Interrupt DISCARDS the gateway's queued prompts (prompt_queue.dart), and
    // the turn's terminal frame can beat the response back — bracket the call
    // so whichever arrives first reports the loss.
    // Improved: also explicitly cancel any streaming message state and force
    // a terminal state update, so the UI reflects the interruption immediately
    // rather than waiting for the gateway's response.
    final queue = ref.read(promptQueueProvider(liveId).notifier);
    queue.beginInterrupt();
    try {
      await ref.read(sessionRepositoryProvider)?.interrupt(liveId);
      queue.dropAll();
      // Refresh the live session badges (working → idle after settlement).
      ref.invalidate(activeSessionListProvider);
    } on Object catch (error) {
      _showError('Failed to stop', error);
    } finally {
      queue.endInterrupt();
    }
  }

  Future<void> _steer(String liveId, String text) async {
    try {
      final outcome = await ref
          .read(sessionRepositoryProvider)
          ?.steer(liveId, text);
      if (outcome == SteerOutcome.rejected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Steer rejected by the agent')),
        );
      }
    } on Object catch (error) {
      _showError('Failed to steer', error);
    }
  }

  void _showError(String prefix, Object error) {
    if (!mounted) {
      return;
    }
    final detail = switch (error) {
      // Gateway 0.20: truncation refused without the confirm flags (4028/4029),
      // disk full on persist (5070), and unclassifiable storage write failure
      // (5071) — surface the actionable part rather than the raw RPC message.
      GatewayRpcException(code: 4028 || 4029) =>
        'refused: resubmit with truncation confirmed',
      GatewayRpcException(code: 5070) =>
        'disk full — free some space and try again',
      GatewayRpcException(code: 5071) => 'session storage could not be written',
      GatewayException() => error.message,
      _ => '$error',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$prefix: $detail')));
  }

  /// P3-03: dispatch a slash command and handle the discriminated result.
  Future<void> _dispatchSlash(
    String liveId,
    String raw, [
    int depth = 0,
  ]) async {
    if (depth > 3) {
      _showSnackBar('Command alias loop detected');
      return;
    }
    final repo = ref.read(slashRepositoryProvider);
    if (repo == null) {
      return;
    }
    // Split name and arg: first whitespace-delimited token vs. remainder.
    final parts = raw.trim().split(RegExp(r'\s+'));
    final name = parts.first;
    final arg = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    try {
      final result = await repo.dispatch(
        name: name,
        arg: arg,
        sessionId: liveId,
      );
      if (!mounted) {
        return;
      }

      switch (result) {
        case DispatchPrefill():
          // Populate the composer field.
          _controller.text = result.message;
          _controller.selection = TextSelection.collapsed(
            offset: result.message.length,
          );
          _focusNode.requestFocus();
          _showSnackBar(result.notice);
        case DispatchSend():
          // Submit message as a user turn.
          if (result.notice != null) {
            _showSnackBar(result.notice!);
          }
          ref
              .read(messageListProvider(liveId).notifier)
              .appendUserMessage(result.message);
          unawaited(_send(liveId, result.message));
        case DispatchExec():
          // Show rendered output.
          _showSnackBar(result.output);
        case DispatchSkill():
          // Show skill message.
          _showSnackBar('${result.name}: ${result.message}');
        case DispatchAlias():
          // Resolve alias one hop (recursively).
          final targetWithArg = arg.isEmpty
              ? result.target
              : '${result.target} $arg';
          unawaited(_dispatchSlash(liveId, targetWithArg, depth + 1));
        case DispatchUnknown():
          _showSnackBar('Unknown command result: ${result.rawType}');
      }
    } on Object catch (error) {
      _showError('Command failed', error);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// P7: show the attachment picker bottom sheet.
  void _showAttachmentPicker(String liveId) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                key: const Key('composer_attach_image'),
                leading: const Icon(Icons.photo),
                title: const Text('Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(_pickImage(liveId));
                },
              ),
              ListTile(
                key: const Key('composer_attach_pdf'),
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF'),
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(_pickPdf(liveId));
                },
              ),
              ListTile(
                key: const Key('composer_attach_file'),
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('File'),
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(_pickFile(liveId));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Refuse a base64 payload the connected gateway cannot receive, and say
  /// why (optional-doc §3). Below desktop contract v5 the gateway's WS frame
  /// cap is 16 MiB, and an oversized frame doesn't error — it drops the
  /// socket, which looks like a random disconnect. Returns true when the
  /// attach may proceed (including whenever the contract is unknown).
  bool _contractAllowsAttachment(int base64Length) {
    final contract = ref.read(desktopContractProvider);
    if (contract.allowsAttachment(base64Length)) {
      return true;
    }
    _showSnackBar(
      'Too large for this gateway (max '
      '${_formatBytes(contract.attachmentLimitBytes!)} encoded) — '
      'update your Hermes gateway to attach files this big.',
    );
    return false;
  }

  /// Bytes as whole MiB — the only magnitude the frame cap is expressed in.
  String _formatBytes(int bytes) => '${bytes ~/ (1024 * 1024)} MiB';

  /// P7: pick an image from the gallery and attach it.
  Future<void> _pickImage(String liveId) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) {
      _showError('Not connected', 'No attachment repository');
      return;
    }
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.gallery);
      if (xFile == null) {
        return; // User cancelled.
      }
      final bytes = await xFile.readAsBytes();
      final b64 = base64Encode(bytes);
      if (!_contractAllowsAttachment(b64.length)) {
        return;
      }
      final result = await repo.attachImageBytes(
        liveId,
        contentBase64: b64,
        filename: xFile.name,
      );
      ref.read(stagedAttachmentsProvider.notifier).addImage(result);
      setState(() {
        _localThumbs[result.path] = bytes;
      });
    } on Object catch (error) {
      _showError('Failed to attach image', error);
    }
  }

  /// P7: pick a PDF file and attach it.
  Future<void> _pickPdf(String liveId) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) {
      _showError('Not connected', 'No attachment repository');
      return;
    }
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['pdf'],
      );
      final pickedFile = result?.files.single;
      if (pickedFile == null) {
        return; // User cancelled.
      }
      final pdfBytes = await pickedFile.readAsBytes();
      final b64 = base64Encode(pdfBytes);
      if (!_contractAllowsAttachment(b64.length)) {
        return;
      }
      final pdfResult = await repo.attachPdf(
        liveId,
        contentBase64: b64,
        filename: pickedFile.name,
      );
      // Add the page images to staged (PDF pages are images).
      ref.read(stagedAttachmentsProvider.notifier).addPdfPages(pdfResult.pages);
      // Store the PDF bytes for each page (use the same bytes for all pages).
      for (final page in pdfResult.pages) {
        setState(() {
          _localThumbs[page.path] = pdfBytes;
        });
      }
    } on Object catch (error) {
      _showError('Failed to attach PDF', error);
    }
  }

  /// P7: pick any file and attach it.
  Future<void> _pickFile(String liveId) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) {
      _showError('Not connected', 'No attachment repository');
      return;
    }
    try {
      final result = await FilePicker.pickFiles();
      final pickedFile = result?.files.single;
      if (pickedFile == null) {
        return; // User cancelled.
      }
      final dataUrl =
          'data:application/octet-stream;base64,${base64Encode(await pickedFile.readAsBytes())}';
      if (!_contractAllowsAttachment(dataUrl.length)) {
        return;
      }
      final fileResult = await repo.attachFile(
        liveId,
        dataUrl: dataUrl,
        name: pickedFile.name,
      );
      ref.read(stagedAttachmentsProvider.notifier).addFile(fileResult);
    } on Object catch (error) {
      _showError('Failed to attach file', error);
    }
  }

  /// P7: remove an image attachment.
  Future<void> _removeImage(String liveId, String path) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) {
      return;
    }
    try {
      await repo.detachImage(liveId, path);
      ref.read(stagedAttachmentsProvider.notifier).removeImage(path);
      setState(() {
        _localThumbs.remove(path);
      });
    } on Object catch (error) {
      _showError('Failed to remove image', error);
    }
  }

  /// P7: toggle mic recording.
  ///
  /// Client-side capture (Android/Linux against gateways with /api/audio)
  /// records on-device and transcribes through the gateway REST route; the
  /// legacy server-side `voice.record` path stays for older gateways and
  /// platforms without local capture.
  void _toggleMic(String liveId) {
    final mode = ref.read(composerVoiceModeProvider);
    voiceDebug('composer._toggleMic mode=${mode.name} liveId=$liveId');
    if (mode == ComposerVoiceMode.clientCapture) {
      _toggleClientMic();
      return;
    }
    final controller = ref.read(voiceControllerProvider.notifier);
    final state = ref.read(voiceControllerProvider);
    if (!state.modeEnabled) {
      // Enable mode and start recording.
      voiceDebug('composer.serverVoice enableThenStartRecording');
      unawaited(
        controller.enableMode().then((_) => controller.startRecording(liveId)),
      );
    } else if (state.recording) {
      // Stop recording.
      voiceDebug('composer.serverVoice stopRecording');
      unawaited(controller.stopRecording(liveId));
    } else {
      // Start recording.
      voiceDebug('composer.serverVoice startRecording');
      unawaited(controller.startRecording(liveId));
    }
  }

  /// P7 rework: device-capture mic toggle — record locally, stop to
  /// transcribe, transcript lands in the composer draft.
  void _toggleClientMic() {
    final controller = ref.read(clientVoiceControllerProvider.notifier);
    final state = ref.read(clientVoiceControllerProvider);
    voiceDebug('composer._toggleClientMic phase=${state.phase.name}');
    switch (state.phase) {
      case ClientVoicePhase.idle:
        unawaited(controller.start());
      case ClientVoicePhase.recording:
        unawaited(controller.stopAndTranscribe());
      case ClientVoicePhase.transcribing:
        voiceDebug('composer._toggleClientMic ignored while transcribing');
    }
  }

  /// P7: toggle TTS. On the client-capture path the button SPEAKS the latest
  /// assistant reply through /api/audio/speak; on the legacy path it toggles
  /// the server-side auto-TTS flag as before.
  void _toggleTts() {
    if (ref.read(composerVoiceModeProvider) ==
        ComposerVoiceMode.clientCapture) {
      final client = ref.read(clientVoiceControllerProvider.notifier);
      if (ref.read(clientVoiceControllerProvider).speaking) {
        client.stopSpeaking();
        return;
      }
      final fold = ref.read(
        messageListProvider(ref.read(activeSessionProvider).liveId ?? ''),
      );
      final lastReply = fold.messages.lastWhere(
        (message) =>
            message.role == MessageRole.assistant && message.text.isNotEmpty,
        orElse: () => const ChatMessage(role: MessageRole.assistant, text: ''),
      );
      final text = lastReply.text.trim();
      if (text.isEmpty) {
        return;
      }
      unawaited(client.speak(text));
      return;
    }
    final controller = ref.read(voiceControllerProvider.notifier);
    unawaited(controller.toggleTts());
  }

  @override
  Widget build(BuildContext context) {
    final liveId = ref.watch(activeSessionProvider).liveId;
    final fold = liveId == null ? null : ref.watch(messageListProvider(liveId));
    // A turn is in flight while its assistant message is still streaming —
    // the fold flips `streaming` off on the terminal event (protocol §6).
    final working = fold?.messages.any((message) => message.streaming) ?? false;

    // P3-03: consume prefill once (from slash launcher selection).
    ref.listen(composerPrefillProvider, (previous, next) {
      if (next != null) {
        _controller.text = next;
        _controller.selection = TextSelection.collapsed(offset: next.length);
        _focusNode.requestFocus();
        ref.read(composerPrefillProvider.notifier).clear();
      }
    });

    // P7 rework: consume a voice transcript once — APPENDED to the draft so a
    // dictation pass extends whatever was already typed.
    ref.listen(composerPrefillFromVoiceProvider, (previous, next) {
      voiceDebug(
        'composer.prefillFromVoice previous=${previous?.length} '
        'next=${next?.length}',
      );
      if (next != null) {
        final existing = _controller.text;
        final merged = existing.isEmpty ? next : '$existing ${next.trim()}';
        _controller.text = merged;
        _controller.selection = TextSelection.collapsed(offset: merged.length);
        _focusNode.requestFocus();
        voiceDebug(
          'composer.prefillFromVoice applied mergedLength=${merged.length}',
        );
        ref.read(composerPrefillFromVoiceProvider.notifier).clear();
      }
    });

    // A dropped queue is reported wherever the interrupt came from — the Stop
    // button here or the drawer's — because the queued messages are gone for
    // good and only the user can resend them.
    if (liveId != null) {
      ref.listen(promptQueueProvider(liveId), (previous, next) {
        if (next.dropped == 0) {
          return;
        }
        _showSnackBar(
          'Stopped — ${next.dropped} queued '
          '${next.dropped == 1 ? 'message' : 'messages'} discarded',
        );
        ref.read(promptQueueProvider(liveId).notifier).acknowledgeDropped();
      });
    }

    // P7: watch staged attachments.
    final stagedAttachments = ref.watch(stagedAttachmentsProvider);

    // P7: listen for voice errors (separate from watching state for UI).
    // Only show errors when voice repository is available (avoid noise in tests).
    ref.listen(voiceControllerProvider, (previous, next) {
      final voiceRepo = ref.read(voiceRepositoryProvider);
      if (voiceRepo != null &&
          next.error != null &&
          next.error != _lastVoiceError) {
        _lastVoiceError = next.error;
        if (mounted) {
          _showSnackBar('Voice: ${next.error}');
        }
      }
    });

    // P7 rework: client-capture voice errors.
    ref.listen(clientVoiceControllerProvider, (previous, next) {
      if (next.error != null && next.error != _lastClientVoiceError) {
        _lastClientVoiceError = next.error;
        if (mounted) {
          _showSnackBar('Voice: ${next.error}');
        }
      } else if (next.error == null) {
        _lastClientVoiceError = null;
      }
    });

    // P7: watch voice state for UI.
    final voiceState = ref.watch(voiceControllerProvider);
    // P7 rework: device-capture state drives the mic button when active.
    final voiceMode = ref.watch(composerVoiceModeProvider);
    final clientVoiceModeActive = voiceMode == ComposerVoiceMode.clientCapture;
    final clientVoice = clientVoiceModeActive
        ? ref.watch(clientVoiceControllerProvider)
        : null;

    // P7: refresh voice status on first build (only when voice repo is available).
    if (!_voiceStatusRefreshed && ref.read(voiceRepositoryProvider) != null) {
      _voiceStatusRefreshed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(voiceControllerProvider.notifier).refreshStatus();
      });
    }

    final queued = liveId == null
        ? const PromptQueue()
        : ref.watch(promptQueueProvider(liveId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // P3-02: suggestion overlay (shown above the field when non-empty).
          if (_suggestions != null && _suggestions!.isNotEmpty)
            _buildSuggestionOverlay(),
          if (!queued.isEmpty) _buildQueuedNotice(queued),
          // P7: attachment chips row (shown above the field when non-empty).
          if (stagedAttachments.images.isNotEmpty ||
              stagedAttachments.files.isNotEmpty)
            _buildAttachmentsRow(stagedAttachments, liveId),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              // P7: attach button (left of text field).
              IconButton(
                key: const Key('composer_attach'),
                tooltip: 'Attach',
                onPressed: liveId == null
                    ? null
                    : () => _showAttachmentPicker(liveId),
                icon: const Icon(Icons.attach_file),
              ),
              Expanded(
                child: TextField(
                  key: composerFieldKey,
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: liveId != null,
                  minLines: 1,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: liveId == null
                        ? 'No active session'
                        : 'Message Hermes…',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // P7: mic button. Client capture (Android/Linux + /api/audio
              // gateway) records locally; otherwise the legacy server-side
              // voice.record flow drives it.
              IconButton(
                key: const Key('composer_mic'),
                tooltip: clientVoice != null
                    ? switch (clientVoice.phase) {
                        ClientVoicePhase.recording =>
                          'Recording — tap to transcribe',
                        ClientVoicePhase.transcribing => 'Transcribing…',
                        ClientVoicePhase.idle => 'Voice',
                      }
                    : (voiceState.recording ? voiceState.micState : 'Voice'),
                onPressed: liveId == null ? null : () => _toggleMic(liveId),
                icon: Icon(
                  (clientVoice?.transcribing ?? false) ||
                          (!clientVoiceModeActive &&
                              voiceState.micState == 'transcribing')
                      ? Icons.hourglass_top
                      : Icons.mic,
                  color:
                      (clientVoice?.recording ?? false) ||
                          (!clientVoiceModeActive && voiceState.recording)
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              // P7: TTS toggle button. Client capture: speak/stop the latest
              // reply; legacy path: toggle server-side auto-TTS.
              IconButton(
                key: const Key('composer_tts'),
                tooltip: clientVoiceModeActive
                    ? (clientVoice?.speaking ?? false
                          ? 'Stop speaking'
                          : 'Speak last reply')
                    : 'Text-to-speech',
                onPressed:
                    liveId != null &&
                        ((clientVoiceModeActive &&
                                ref.watch(audioRoutesProvider).value == true) ||
                            (!clientVoiceModeActive && voiceState.modeEnabled))
                    ? _toggleTts
                    : null,
                icon: Icon(
                  (clientVoice?.speaking ?? false) || voiceState.ttsEnabled
                      ? Icons.volume_up
                      : Icons.volume_off,
                ),
              ),
              if (working && liveId != null) ...<Widget>[
                IconButton.filled(
                  key: composerSteerKey,
                  tooltip: 'Steer',
                  onPressed: _submit,
                  icon: const Icon(Icons.alt_route),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: composerStopKey,
                  tooltip: 'Stop',
                  onPressed: () => unawaited(_stop(liveId)),
                  icon: const Icon(Icons.stop),
                ),
              ] else
                IconButton.filled(
                  key: composerSendKey,
                  tooltip: 'Send',
                  onPressed: liveId == null ? null : _submit,
                  icon: const Icon(Icons.send),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// The "waiting behind this turn" line: what a `queued` ack left pending,
  /// and a warning that Stop throws it away rather than just stopping.
  Widget _buildQueuedNotice(PromptQueue queue) {
    final theme = Theme.of(context);
    final count = queue.texts.length;
    return Padding(
      key: composerQueuedNoticeKey,
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.schedule,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'message' : 'messages'} queued behind '
              'this turn — Stop discards them',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// P3-02: build the suggestion list overlay above the field.
  Widget _buildSuggestionOverlay() {
    final suggestions = _suggestions!;
    return Container(
      key: const Key('slash_suggestions'),
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final item = suggestions[index];
            return ListTile(
              key: ValueKey('slash_suggestion_${item.display}'),
              dense: true,
              title: Text(
                item.display,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              subtitle: item.meta.isNotEmpty ? Text(item.meta) : null,
              onTap: () => _applySuggestion(item),
            );
          },
        ),
      ),
    );
  }

  /// P7: build the attachments row (thumbnails + chips).
  Widget _buildAttachmentsRow(StagedAttachments attachments, String? liveId) {
    return Container(
      key: const Key('composer_attachments'),
      margin: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            // Image attachments (including PDF pages).
            for (var i = 0; i < attachments.images.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildImageChip(attachments.images[i], i, liveId),
              ),
            // File attachments.
            for (final file in attachments.files)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFileChip(file),
              ),
          ],
        ),
      ),
    );
  }

  /// P7: build an image attachment chip (thumbnail + token estimate + delete).
  Widget _buildImageChip(ImageAttachment image, int index, String? liveId) {
    final bytes = _localThumbs[image.path];
    final tokenEstimate = image.tokenEstimate;
    return Stack(
      children: <Widget>[
        Container(
          key: ValueKey('attachment_$index'),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: bytes != null
                ? Image.memory(bytes, width: 48, height: 48, fit: BoxFit.cover)
                : const Icon(Icons.image),
          ),
        ),
        if (tokenEstimate != null)
          Positioned(
            bottom: 2,
            left: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '~$tokenEstimate tok',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: liveId == null
                ? null
                : () => unawaited(_removeImage(liveId, image.path)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// P7: build a file attachment chip (icon + name).
  Widget _buildFileChip(FileAttachment file) {
    return Tooltip(
      message: file.refText,
      child: Chip(
        avatar: const Icon(Icons.insert_drive_file),
        label: Text(file.name, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
