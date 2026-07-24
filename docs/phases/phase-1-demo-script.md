# Phase 1 — Demo script (P1-17)

Run this against a real token-auth gateway to verify the MVP end to end.
Each step lists the expected result. If a step fails, that's a bug — file it
against the named ticket.

## 0. Setup

- A running Hermes gateway in token mode (`/api/status` reports
  `auth_required: false`), reachable from this machine. Have its **URL** and
  **session token** ready. The gateway must have the **kanban plugin
  installed and enabled** for steps 8–9, and at least one provider
  authenticated for step 6.
- Run the app:
  ```sh
  cd app
  export PATH="$HOME/flutter/bin:$PATH"
  flutter run -d linux        # or: flutter run -d <your-device>
  ```

## 1. Connect (P0-07 / P1-16)

1. The app opens on **Connect to Hermes**. Enter the gateway URL and token →
   **Connect**.
2. Expect: probe card shows the gateway version, `running: true`,
   `auth: token`; the state chip goes Connecting → Connected; a toast says
   **"Connected to Hermes vX.Y.Z"**; the app lands on the chat screen within
   one transition.
3. Negative checks (repeat with bad input): an unreachable URL → a clear
   "could not reach" message; a wrong token → "The gateway rejected the
   token (close 4401)"; both recoverable (no hang, no crash).

## 2. Chat with streaming + tool cards (P1-07)

4. A session auto-creates ("Starting a session…" → composer enables).
5. Send: `List the files in the current directory.`
6. Expect: your bubble appears at once; the assistant bubble streams in
   (typing indicator while streaming); a **tool card** appears for the
   shell call, flips running → done, and expands to show the result; the
   final message renders as markdown.

## 3. Approval (P1-08)

7. Send: `Delete the file /tmp/definitely-not-important.txt` (create it
   first: `touch /tmp/definitely-not-important.txt`).
8. If the gateway asks for approval: an **approval card** appears inline with
   the command and description → tap **Approve**. Expect the turn to
   continue and complete. (Deny should abort the action gracefully.)

## 4. Clarify (P1-08)

9. Send something ambiguous, e.g. `Deploy it` with no context. If the agent
   asks a clarifying question: a **clarify card** appears (choice chips or
   free text) → answer → the turn continues.

## 5. Interrupt (P1-07)

10. Send a long-running prompt (e.g. `Count to 1000000 with a shell loop`)
    and tap **Stop** mid-turn. Expect the turn to end with an
    "interrupted" caption; the composer returns to Send.

## 6. Model picker (P1-11/12)

11. Tap the model button (app bar, shows the current model). Expect providers
    grouped with auth badges; the current model checked; providers without a
    key disabled with a "needs key" hint.
12. Pick a different model on an authenticated provider. Expect the sheet to
    close and the app-bar label to update (via the follow-up `session.info`).
    If the model is flagged expensive, a confirm dialog appears first —
    Continue proceeds.

## 7. Profiles dropdown (P1-13)

13. Tap the person icon. Expect real profiles listed with the active one
    checked and the caption **"Active profile for new gateway launches"**.
14. Pick another profile. Expect the honest snackbar: it applies to NEW
    gateway launches, the running gateway is unchanged.

## 8. Sessions (P1-10)

15. Open the drawer (hamburger). Expect the live section showing the current
    session with a status badge, history below, and the gateway version in
    the footer.
16. **New session** → a fresh empty chat. Send a message in it.
17. Switch back to the first session from history. Expect the previous
    conversation re-rendered (resumed + seeded history).

## 9. Plugins + kanban (P1-14/15)

18. Tap the puzzle icon (app bar). Expect installed plugins with versions;
    kanban shows **Open board**.
19. Open the board: fixed columns (triage → done) with task cards (title,
    assignee, summary, badges). Tap a card → detail sheet (body, comments).
20. Move a card to another column via its menu. Expect the move to apply
    instantly (optimistic) and persist — pull to refresh and confirm.

## 10. Reconnect (P1-16)

21. With a conversation open, break the network (or restart the gateway).
    Expect the app-bar chip → **Reconnecting**; the visible conversation is
    NOT wiped.
22. Restore the network. Expect the chip → Connected; the session re-binds
    via `session.resume` and history is intact. If the session was reaped
    server-side, a fresh session is created instead.

## Sign-off

- [ ] All steps pass on Linux desktop.
- [ ] All steps pass on one mobile target/emulator (Phase 9 brings up the
      Android toolchain; until then desktop-only is acceptable).
- [ ] `flutter analyze` clean; `flutter test` all green (247+ tests).
