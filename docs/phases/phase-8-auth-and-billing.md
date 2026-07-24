# Phase 8 — Auth (OAuth) & billing & multi-gateway

**Goal:** support hosted/gated gateways (OAuth), in-app credits/billing, and
managing multiple gateway connections — the pieces needed to point the app at a
real shared/hosted Hermes, not just a loopback dev gateway.

**Reference:** `reference/01-gateway-protocol.md` §2.2 (OAuth/ticket);
`reference/02-rpc-index.md` §Billing; `apps/desktop/electron/connection-config.cjs`
(cookie/ticket model), `gatewayTypes.ts` `Billing*` (:56).

## OAuth mode

### P8-01 — Detect & drive the OAuth gate
When `/api/status` reports `auth_required:true`, run the OAuth flow: sign in via
the gateway's provider (`auth_providers`), establish the session cookie, and for
each WS connect **mint a single-use ticket** (`POST /api/auth/ws-ticket` →
`{ticket, ttl_seconds:30}`), then connect `/api/ws?ticket=…`.

### P8-02 — Cookie session lifecycle
Handle access/refresh cookie semantics (`hermes_session_at` ~15min /
`hermes_session_rt` ~24h rotating; the gateway transparently rotates AT from RT
on the next request — `connection-config.cjs:26-38`). Detect a dead session and
prompt re-login; don't force needless re-logins while an RT is live.

### P8-03 — Auth-mode-aware transport
Generalize the transport config so token mode and OAuth mode are both first-class
(the abstraction was designed for this in Phase 0). REST auth = cookie in OAuth
mode / `X-Hermes-Session-Token` in token mode; WS = `?ticket=` vs `?token=`.

## Billing & credits

### P8-04 — Billing state & credits
`billing.state` (balance, card, monthly cap, auto-reload, presets),
`credits.view` (Nous credit view). A billing screen. Remember: billing handlers
return structured `{ok,error,...}` envelopes even on failure — branch on the
typed code.

### P8-05 — Charge & auto-reload
`billing.charge` + `billing.charge_status` (poll), `billing.auto_reload`
(thresholds). `billing.step_up` (device-flow to grant charge scope) consuming the
`billing.step_up.verification` event (show the verification URL/code).

## Multi-gateway

### P8-06 — Connection manager
Save multiple gateway connections (name + URL + token/OAuth + auth mode); switch
between them; per-connection secure token storage. This is where the **profile ↔
gateway** idea can land: model each saved connection as (optionally) a profile's
dedicated gateway, so picking a connection = picking a profile's backend — the
"real" fix for the Phase 1 profile caveat.

**Exit criteria:** the app connects to a hosted OAuth-gated Hermes, manages
credits/billing, and juggles several saved gateways.

> Open question #1 (roadmap): whether the Hermes team prefers per-profile
> gateways vs a live profile-relaunch RPC determines P8-06's exact shape.
