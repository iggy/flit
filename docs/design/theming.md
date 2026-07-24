# Design: Theming — Material 3 now, "match Hermes" later

**Decision (current):** ship **fresh Material 3** with dynamic color. It's the
fastest path to a polished, native-feeling demo on every platform, and it
doesn't couple the app's look to the gateway.

This doc records the **"match Hermes skin"** option so it's ready if brand
consistency becomes a sticking point later (e.g. after the coworker demo, if
someone says "it should look like the desktop app").

## Now: Material 3

- Single `ThemeData` (light + dark) built from a seed color in `core/theme/`.
- Use `ColorScheme.fromSeed`; support system light/dark.
- Chat surfaces: user bubble = primary container; assistant = surface; tool
  cards = a subtle outlined container; approvals = a tonal alert surface.
- Keep all colors/spacing behind a small `AppTheme` so a later skin swap is a
  single seam, not a refactor.

**Design the theme layer with the skin swap in mind:** every widget reads colors
from `Theme.of(context)` / an `AppTheme` extension — never hard-code hex. That
is the entire cost of keeping the door open.

## Later (optional): match the Hermes skin

The gateway already pushes a **skin** payload — for free — on the
`gateway.ready` event. Per `docs/reference/01-gateway-protocol.md` §4, the
`payload` of `gateway.ready` **is** the skin dict:

```jsonc
{
  "name": "hermes",
  "colors":   { /* named color roles → hex */ },
  "branding": { /* strings: product name, taglines */ },
  "banner_logo": "…", "banner_hero": "…",
  "tool_prefix": "", "help_header": "…"
}
```

(Source: `tui_gateway/server.py:1896` `resolve_skin()`, emitted at
`tui_gateway/ws.py:324`. Returns `{}` on failure — always have a fallback.)

### How the swap would work

1. Capture the skin from the `gateway.ready` event into a `SkinProvider`.
2. Map `skin.colors` role names → a Material `ColorScheme` (write the mapping
   once the actual key names are known — **open item**, see below).
3. If a skin is present and skinning is enabled, build `ThemeData` from it;
   otherwise fall back to the Material 3 seed theme.
4. Optionally show `branding` / `banner_logo` on the connect and empty-chat
   screens for an on-brand feel.

### Open items before implementing the skin path

- **Enumerate `skin.colors` keys.** `resolve_skin()` in
  `tui_gateway/server.py` (~line 1896) needs to be read to list the exact color
  role names and how the desktop app maps them (see
  `apps/desktop/src/themes/`). Until then, treat the skin as opaque.
- **Per-gateway skins.** Different gateways could push different skins; the theme
  must react to reconnects to a different backend.

**Effort estimate:** ~1 focused ticket once the color-key mapping is known.
Slot it into Phase 9 (platform polish) unless promoted earlier by feedback.
