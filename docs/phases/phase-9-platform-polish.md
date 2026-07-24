# Phase 9 — Platform polish & release

**Goal:** the last mile — native platform integration, the "match Hermes"
theming option, remaining power surfaces, and shippable builds. A rolling
bucket: pull items forward whenever feedback makes them the priority.

**Reference:** `reference/02-rpc-index.md` §Processes/browser, §Pet;
`design/theming.md`.

## Native platform integration

### P9-01 — Desktop window chrome
Native window sizing/state, title bar, tray/menu where useful; remember window
geometry (mirrors the desktop app's `window-state`).

### P9-02 — Deep links & routing
`go_router` deep links (open a session/board via URL); handle app links on
mobile.

### P9-03 — Notifications
Local notifications for `background.complete`, approvals needing attention, and
kanban terminal events (respect platform permission flows).

### P9-04 — Command palette
A cross-cutting command palette (sessions, models, slash commands, navigation) —
the desktop app's `command-palette`/`command-center`.

## Remaining power surfaces

### P9-05 — Browser & preview control
`browser.manage` (CDP connect/disconnect/status + `browser.progress` events) and
`preview.restart` (+ progress events) for agent-driven web/dev workflows.

### P9-06 — Pet mascot (optional / stretch)
The `pet.*` family (16 methods) — the cosmetic petdex sprite mascot. Renders
base64 spritesheets. Pure delight, zero function; do it only if there's appetite.

## Theming

### P9-07 — "Match Hermes" skin
Implement the skin path from `design/theming.md`: capture the `gateway.ready`
skin payload, map `skin.colors` → a Material `ColorScheme`, and swap themes.
**Blocked on** roadmap open question #3 (the exact skin color-key schema — read
`resolve_skin()` in `tui_gateway/server.py` first).

## Release

### P9-08 — CI, packaging & stores
CI (analyze + test + build per platform); packaging for desktop (AppImage/dmg/
msi as relevant) and mobile (Play/App Store); versioning; crash reporting;
in-app update check where applicable.

**Exit criteria:** the app feels native on each platform, optionally matches
Hermes branding, covers the remaining power surfaces, and ships from CI.
