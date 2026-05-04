## Context

The subtitle copying mechanism (`get_clipboard_text_smart`) heavily relies on the internal state `FSM.DW_CURSOR_LINE` to identify which subtitle to copy. Currently, the synchronization of this cursor to the actively playing subtitle (`active_idx`) resides exclusively in `tick_dw`, which only executes when the dedicated Drum Window is open (`FSM.DRUM_WINDOW == "DOCKED"`). 

When the user operates purely in the on-screen Drum Mode (`FSM.DRUM == "ON"`) and navigates continuously using the Spacebar (Autopause ON), `tick_dw` is bypassed. Consequently, if the cursor state was previously set by a manual interaction (e.g., `a`/`d` or a mouse click), it remains stuck at that index while the video plays on. This leads to `Ctrl+C` copying a stale subtitle rather than the current on-screen text.

## Goals / Non-Goals

**Goals:**
- Guarantee that `FSM.DW_CURSOR_LINE`, `FSM.DW_CURSOR_WORD`, and `FSM.DW_VIEW_CENTER` robustly track the active playback subtitle whenever `FSM.DW_FOLLOW_PLAYER` is true.
- Unify the cursor synchronization logic across both Drum Mode and Drum Window Mode.

**Non-Goals:**
- No alterations to manual selection states (e.g., word selections, pink highlighting, ranges).
- No changes to the actual clipboard formatting or filtering logic.

## Decisions

**Migrate Cursor Synchronization to `master_tick`**
- **Decision:** Extract the "follow player" cursor synchronization block from `tick_dw` and relocate it to the global `master_tick` loop, immediately after `active_idx` is calculated.
- **Rationale:** `master_tick` runs universally and maintains the authoritative `active_idx`. Centralizing the follow logic ensures that any subsystem dependent on the cursor (clipboard, tooltips, rendering) always references the synchronized playback state, regardless of whether the Drum Window UI is rendered.
- **Alternatives Considered:** We considered modifying `get_clipboard_text_smart` to explicitly ignore `FSM.DW_CURSOR_LINE` if `FSM.DW_FOLLOW_PLAYER` was true. However, fixing the state at its source (the tick loop) is architecturally cleaner and prevents potential desync bugs in other features (like hover tooltips) that might also reference a stale cursor.

## Risks / Trade-offs

- **Risk: Redundant Execution** - Leaving remnants of the sync logic in `tick_dw` could cause conflicting updates or double-execution.
- **Mitigation:** Carefully remove the redundant synchronization lines from `tick_dw`. The `tick_dw` function will be refactored to focus solely on OSD data generation and Book Mode scroll enforcement, relying purely on the state prepared by `master_tick`.
