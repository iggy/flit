# Reference: Conventions for implementers

**Read this once before implementing any ticket.** These rules exist so that
tickets can be picked up independently — including by a smaller model — and
still compose into a coherent app.

## Golden rules

1. **Never invent protocol.** Every RPC method name, param, result field, and
   event payload field must come from `docs/reference/` (which is cited to
   `hermes-agent` source). If a shape you need isn't documented, **stop and add
   an open question to the ticket** — do not guess a field name.
2. **Trust Python over TypeScript.** Where a shape differs between the Python
   handler and `ui-tui/src/gatewayTypes.ts`, the Python handler wins. Known
   divergences are listed in `00-overview.md`.
3. **Stay in your layer.** Presentation watches providers; it never touches a
   client or DTO directly. Data never imports Flutter. See `04-app-architecture.md`.
4. **One ticket = one vertical slice or one layer artifact.** Don't expand scope.
   If you discover a dependency, note it; don't silently implement it.
5. **DTOs translate; domain models are clean.** Wire quirks (polymorphic
   `result`, snake_case, the two session ids) are absorbed in `data/dto` and the
   repository. The `domain/` model the UI sees is tidy.

## Ticket format

Every ticket in `docs/phases/*` follows:

- **Goal** — one sentence.
- **Inputs** — which reference sections / prior tickets it depends on.
- **Deliverables** — the exact files to create/modify.
- **Acceptance** — observable criteria (a test passes, a screen renders X).
- **Notes/pitfalls** — the gotchas specific to this ticket.

Tickets are sized so a single focused session can complete one. IDs are stable
(`P1-03`) so they can be referenced across docs and commits.

## Coding standards

- **Dart style:** `dart format`; `flutter analyze` must be clean (treat lints as
  errors in CI). Prefer `final`; immutable models.
- **Naming:** files `snake_case.dart`; types `UpperCamelCase`; providers end in
  `Provider` / notifiers in `Notifier`.
- **Serialization:** `json_serializable` for DTOs. Snake_case wire → Dart via
  `@JsonKey(name: 'session_id')` or a `fieldRename`. Keep DTOs in `data/dto`;
  never expose a DTO above the data layer.
- **Errors:** repositories return typed results (a `Result<T, GatewayError>` or
  throw a typed `GatewayException`); never let a raw `DioException` /
  socket error leak into a provider. Map JSON-RPC error `{code,message}` to
  `GatewayError`.
- **Nullability:** wire fields are often optional. DTO fields that the docs mark
  optional are nullable in Dart; provide sane defaults when folding into domain
  models.
- **No secrets in logs.** Redact tokens and WS query strings everywhere.

## Testing expectations

- **Unit-test the event fold** (turn lifecycle → `List<ChatMessage>`). This is
  the most bug-prone code; feed it the exact frame sequences from
  `03-mvp-wire-shapes.md` §7 and assert the resulting message list.
- **Unit-test the RPC client** against a fake WS that emits canned frames,
  including: multiple frames in one message; an event arriving before a response;
  a parse-error frame; a timeout.
- **Golden/widget tests** for the chat bubble, tool card, and approval prompt.
- Every ticket's acceptance criteria say what to test. Don't mark a ticket done
  with failing or absent tests where tests are specified.

## Definition of done (per ticket)

- [ ] Deliverable files exist and match the ticket.
- [ ] `flutter analyze` clean; `dart format` applied.
- [ ] Specified tests written and passing.
- [ ] No invented protocol; any deviation from the reference is documented.
- [ ] Acceptance criteria demonstrably met.

## Working against a real gateway

Phase 0 documents standing up a local gateway (`hermes dashboard`). For most
tickets you can develop against **recorded frames** (fixtures captured from a
real turn) so you don't need a live backend — capture once, replay in tests.
Live verification happens at phase-end integration tickets.
