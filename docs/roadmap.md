# Roadmap

The plan to build a cross-platform (mobile + desktop) Flutter client for Hermes
Agent, from an MVP demo to full desktop/TUI parity. Read
`reference/00-overview.md` first for the mental model, then this.

## Guiding principles

- **Connect-only client.** The app attaches to a running gateway (URL + token).
  It never spawns or bundles the Python backend. (Phase 8+ may add QoL like
  adopting a served token, but not embedding a backend.)
- **Token ("plaintext") auth for loopback dev; username/password for gated
  gateways.** OAuth mode is designed-for but deferred to Phase 8. (Auth model
  updated post-MVP: the gateway replaced session-token-only auth with
  OAuth-or-user/pass — see `reference/01-gateway-protocol.md` §2.)
- **Vertical slices that demo.** Every phase ends with something runnable and
  showable, not just plumbing.
- **Decomposable tickets.** Tickets are small, ordered, and independently
  implementable — see `reference/05-conventions.md`.
- **Grounded in the contract.** No invented protocol; everything maps to
  `reference/`.

## Phase overview

| Phase | Theme | Outcome | Depends on |
|------:|-------|---------|-----------|
| **0** | Foundation | Flutter project scaffolded; transport core (RPC + REST clients); connects to a gateway and prints `gateway.ready`. | — |
| **1** | **MVP** (demo target) | Connect (URL+token) → chat with streaming + tool cards → model picker → profile dropdown → plugins list → kanban board (read+move) → approvals/clarify. | 0 |
| **2** | Session depth | Full session management: history, resume, list, rename, branch, delete, compress, usage, multi-session switching, reconnect resilience. | 1 |
| **3** | Agent transparency | Slash commands + autocomplete; subagent/delegation visualization; steer; sudo/secret prompts; interrupt controls. | 1 |
| **4** | Config & models | Provider key management; reasoning/fast toggles; tools & toolsets config; MCP reload; projects/workspaces; full config editor. | 1 |
| **5** | Automation & plugins | Cron scheduler UI; full kanban (fleet/runs/boards/orchestration); plugins hub (enable/disable); background tasks; process control; handoff. | 1, 4 |
| **6** | Memory & learning | Learning timeline (/journey) view/edit; insights/analytics; project facts; git rollback/checkpoints. | 2 |
| **7** | Rich I/O | Image/PDF/file attachments (mobile-native); voice (record/TTS); paste handling. | 1 |
| **8** | Auth & billing | OAuth mode (ticket flow, cookie session); credits & billing (state/charge/auto-reload/step-up); multi-gateway connection manager. | 1 |
| **9** | Platform polish | Desktop window chrome; deep links; notifications; command palette; browser/preview control; theming (Hermes skin); optional pet mascot; store packaging. | most |

## The MVP (Phase 1) — explicit scope for the demo

Everything you named, and nothing that isn't needed to make those sing:

- **Connect** to a gateway with plaintext/token auth (URL + token entry;
  `/api/status` probe; `gateway.ready` handshake).
- **Chat** with streaming assistant output (deltas → live bubble) and
  **tool-call** display (start/complete cards, results, diffs).
- **Interactive prompts** that a real turn hits: **approvals** and **clarify**
  (without these, tool-using turns stall).
- **Model selection** (`model.options` → picker → `config.set{key:"model"}`).
- **Profile selection** (dropdown from REST `/api/profiles`; see caveat below).
- **Plugins**: list installed plugins; open the **kanban** board (read board,
  tap card for detail, move card between columns).
- **Sessions**: create, list, switch, interrupt (the minimum to make chat
  usable across more than one conversation).

### Known caveat baked into the MVP — profiles

There is **no in-session profile-switch RPC** (confirmed: no `profile.*`
`@method` exists in `tui_gateway/server.py`). A profile is a whole HERMES_HOME
directory; switching means the gateway runs under a different HERMES_HOME.

For the MVP, the profile dropdown will:
- **List** profiles from `GET /api/profiles` and show the active one from
  `GET /api/profiles/active` (real data).
- Let the user **pick** one and call `POST /api/profiles/active` (which sets the
  sticky pointer future launches read).
- **Honestly signal** that selecting a profile does **not** hot-swap the running
  gateway's profile — because the gateway can't do that live. Copy: e.g. "Active
  profile for new gateway launches." This satisfies the "at least a dropdown that
  lists profiles even if it doesn't connect to the right place yet" requirement
  without lying to the user.

A future enhancement (Phase 8, connection manager): treat each profile as its
own gateway connection (the desktop app runs a per-profile backend pool), so
picking a profile connects to that profile's backend. Requires either
per-profile gateways or a gateway-side "relaunch under profile" affordance —
noted as an **open question** for the Hermes team.

## Open questions for the Hermes team

These surfaced while grounding the plan; none block the MVP, but resolving them
improves later phases (tracked in each relevant phase doc too):

1. **In-app profile switching.** Would the team add a gateway RPC to relaunch/
   retarget under a different profile, or is per-profile gateways the intended
   model? (Affects Phase 8.)
2. **A dedicated "set default model" RPC.** Today it's `config.set{key:"model"}`
   with flags encoded in the value string; a typed `model.set` would be cleaner
   for clients. (Affects Phase 1/4.)
3. **Skin color-key schema.** Exact keys in `resolve_skin()` for the optional
   "match Hermes" theme. (Affects Phase 9 — `design/theming.md`.)
4. **Session status enum.** Handlers emit `idle`/`streaming` while
   `gatewayTypes.ts` declares `idle|starting|waiting|working`; confirm the wire
   superset. (Affects Phase 2.)

## Sequencing notes

- Phases 2–4 can proceed in **parallel** once Phase 1 lands (they touch
  different features over the same transport). 3 and 4 are the highest-value
  parity work.
- Phase 7 (rich I/O) and Phase 8 (auth/billing) are independent of the parity
  phases and can slot in when mobile ergonomics or hosted-gateway support become
  priorities.
- Phase 9 is a rolling "polish" bucket; pull items forward as feedback dictates.
