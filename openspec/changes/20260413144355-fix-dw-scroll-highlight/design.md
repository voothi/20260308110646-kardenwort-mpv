## Context

The Drum Window (DW) mode uses a monochromatic monospace layout for precise word-level hit-testing. Currently, mouse wheel scrolling (`cmd_dw_scroll`) shifts the viewport but disrupts the logical cursor state (`cl, cw`) by manually clearing the word index and failing to re-synchronize the cursor with the new line/word under the mouse. This causes visual flicker (highlight disappearing) and broken selection ranges during drag operations.

## Goals / Non-Goals

**Goals:**
- Maintain stable word-highlighting during mouse wheel scrolling.
- Preserve and update active drag-selection ranges during scrolling.
- Unify mouse-to-cursor synchronization logic.

**Non-Goals:**
- Changing the keyboard navigation logic.
- Modifying the subtitle parsing or layout engine.

## Decisions

### 1. Refactor Mouse-to-Cursor Synchronization
Introduce a shared helper function `dw_sync_cursor_to_mouse()` that performs a hit-test based on current mouse coordinates and updates `FSM.DW_CURSOR_LINE` and `FSM.DW_CURSOR_WORD`. This logic is currently embedded in `dw_mouse_update_selection`.

### 2. Update `cmd_dw_scroll` Logic
- Remove the line `FSM.DW_CURSOR_WORD = -1`.
- Invoke `dw_sync_cursor_to_mouse()` after shifting `FSM.DW_VIEW_CENTER`. This ensures that even if the mouse hasn't moved, the cursor state is updated to reflect the new subtitle data occupying the same screen space.

### 3. Selection Range Stability
By keeping `cl, cw` synchronized in real-time with the scroll, the `draw_dw` function's selection range logic (which compares `cl, cw` to `al, aw`) will automatically produce the correct visual output for the new viewport state.

## Risks / Trade-offs

- **Hit-Test Performance**: Running a hit-test on every scroll event is negligible performance-wise (simple math on < 20 lines of text).
- **Auto-Pause Interaction**: If scrolling happens while paused, we must ensure the OSD updates immediately (already handled by `master_tick` or explicit `update()` calls).
