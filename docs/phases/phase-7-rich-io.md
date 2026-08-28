# Phase 7 — Rich input/output (mobile-native)

**Goal:** the multimodal ergonomics that make a *mobile* client shine —
attachments, voice, and paste — using the remote-friendly (bytes/base64) RPCs.

**Reference:** `reference/02-rpc-index.md` §Rich input, §Voice.

> **Mobile rule:** the app is a *remote* client, so use the **bytes/base64**
> variants, not the path-based ones. Host paths (`image.attach`) mean nothing on
> a phone.

## Attachments

### P7-01 — Image attach (bytes)
`image.attach_bytes` (base64 from a phone gallery/camera pick) → attach to the
composer; `image.detach` to remove; show thumbnails + token estimate from the
result.

### P7-02 — File attach
`file.attach` (remote data_url upload → returns an `@file:` ref) for arbitrary
files; render the ref in the composer.

### P7-03 — PDF attach
`pdf.attach` (base64 → gateway renders per-page PNGs and queues them as images);
show page count/preview.

### P7-04 — Drop / paste detection
`input.detect_drop` (desktop drag-drop path detection) and `clipboard.paste`
(server-side clipboard image) where the platform supports it. `paste.collapse`
for large text pastes.

## Voice

### P7-05 — Voice capture
Client-side push-to-talk on Android/Linux desktop: the app records from the
device microphone (`record` plugin, WAV 16 kHz mono), uploads the clip to the
gateway's `POST /api/audio/transcribe` (base64 data URL — the same released
route the Hermes desktop app uses), and drops the transcript into the
composer. Works against remote gateways with **no server-side mic or
PortAudio dependency**; auth rides the normal REST transport (token header /
session cookies / Bearer).

Gateways without the audio routes (probe answers 404) fall back to the legacy
server-side flow: `voice.toggle` (status/on/off) and `voice.record` (VAD
push-to-talk start/stop), consuming `voice.status`
(idle/listening/transcribing) and `voice.transcript` events. That path
records on the gateway host and therefore requires audio deps there.

### P7-06 — TTS playback
`POST /api/audio/speak` synthesizes text through the gateway's configured TTS
provider chain and returns base64 audio, played locally via audioplayers.
The composer's speaker button speaks the latest assistant reply; a second tap
stops playback. On gateways without the audio routes this falls back to the
legacy `voice.tts` auto-speak toggle (server-side playback). Handle the
audio-available/stt-available capability flags from the toggle result.

**Exit criteria:** on a phone you can attach photos/files/PDFs, dictate a
prompt by voice from your device mic, and hear replies locally — all through
the remote-friendly bytes/base64 contracts.
