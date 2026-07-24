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
`voice.toggle` (status/on/off) and `voice.record` (VAD push-to-talk start/stop),
consuming `voice.status` (idle/listening/transcribing) and `voice.transcript`
events → drop the transcript into the composer. A mic button with live state.

### P7-06 — TTS playback
`voice.tts` — speak assistant replies aloud (optional toggle). Handle the
audio-available/stt-available capability flags from the toggle result.

**Exit criteria:** on a phone you can attach photos/files/PDFs, dictate a prompt
by voice, and optionally hear replies — all through the remote-friendly RPCs.
