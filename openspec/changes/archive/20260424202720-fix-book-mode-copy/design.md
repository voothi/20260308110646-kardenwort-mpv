## Context

In `lls_core.lua`, the `cmd_dw_seek_delta` function handles manual navigation (`a`/`d`). Currently, it contains a conditional block that only updates the viewport (`FSM.DW_VIEW_CENTER`) and the manual selection cursor (`FSM.DW_CURSOR_LINE`) if `FSM.BOOK_MODE` is OFF.

While the viewport *should* remain stationary in Book Mode, the manual cursor focus should still follow the user's manual navigation steps to ensure that subsequent actions (like `Ctrl+C` copying) target the correct subtitle.

## Goals / Non-Goals

**Goals:**
- Synchronize `FSM.DW_CURSOR_LINE` with the seek target in Book Mode during manual seeks.
- Preserve existing word or range selections during seeks.
- Keep `FSM.DW_VIEW_CENTER` stationary in Book Mode.

**Non-Goals:**
- Automatic cursor follow during normal playback in Book Mode (already handled by `tick_dw`).
- Modification of the clipboard extraction logic itself.

## Decisions

### 1. Decouple Viewport update from Cursor update in `cmd_dw_seek_delta`
The logic will be split: `FSM.DW_VIEW_CENTER` will remain gated by `not FSM.BOOK_MODE`, but the update for `FSM.DW_CURSOR_LINE` will be moved to a shared block (or duplicated for Book Mode) that depends only on the absence of a selection anchor (`FSM.DW_ANCHOR_LINE == -1`).

**Rationale**: This fulfills both the "Stationary Viewport" requirement (don't scroll) and the "Functional Navigation" requirement (update focus for copying).

### 2. Preserve `FSM.DW_ANCHOR_LINE` check
The update to `FSM.DW_CURSOR_LINE` must remain guarded by `FSM.DW_ANCHOR_LINE == -1`.

**Rationale**: This ensures that if a user has intentionally highlighted a range or word (which sets `ANCHOR_LINE`), the focus remains on that study material even if they seek the audio elsewhere.

## Risks / Trade-offs

- **[Risk]** The cursor (yellow highlight) might move off-screen if the user seeks far beyond the stationary viewport. → **Mitigation**: This is expected behavior in Book Mode. Users who want to see the target line should turn Book Mode OFF or scroll manually.
