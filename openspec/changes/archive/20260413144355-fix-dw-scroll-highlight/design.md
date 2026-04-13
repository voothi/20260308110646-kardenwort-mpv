## Context

The Drum Window (DW) mode uses a monochromatic monospace layout for precise word-level hit-testing. Previously, mouse wheel scrolling (`cmd_dw_scroll`) shifted the viewport but disrupted the logical cursor state (`cl, cw`). Direct synchronization of the cursor during scrolling initially caused regressions where selections would "stick" to the mouse or the active yellow highlight would snap to the pointer unexpectedly.

## Goals / Non-Goals

**Goals:**
- Maintain stable word-highlighting during mouse wheel scrolling.
- Preserve and update active drag-selection ranges during scrolling.
- Prevent non-active hover highlights from snapping to the mouse during scroll events.

**Non-Goals:**
- Changing the keyboard navigation logic.
- Implementing automatic mouse-hover tracking (hover highlight remains locked to user-initiated clicks/selection).

## Decisions

### 1. Refactor Mouse-to-Cursor Synchronization
Introduce a shared helper function `dw_sync_cursor_to_mouse()` that performs a hit-test based on current mouse coordinates and conditionally updates `FSM.DW_CURSOR_LINE` and `FSM.DW_CURSOR_WORD`.

### 2. State-Aware Synchronization Guard
To prevent unintended "stretching" of selection ranges or "hover snapping" (moving the yellow highlight without a click), the `dw_sync_cursor_to_mouse()` updates the logical cursor status **ONLY** when `FSM.DW_MOUSE_DRAGGING` is true.
- If dragging: `cl, cw` updates to the current mouse position, expanding/contracting the selection range as the content scrolls.
- If not dragging: `cl, cw` remains fixed on its previous text index, moving along with the text as it scrolls, while the OSD is refreshed to maintain visual positioning.

### 3. Update `cmd_dw_scroll` Logic
- Remove the line `FSM.DW_CURSOR_WORD = -1`.
- Invoke `dw_sync_cursor_to_mouse()` after shifting `FSM.DW_VIEW_CENTER` to ensure the OSD and cursor state are reconciled.

## Risks / Trade-offs

- **Interaction Fidelity**: This maintains the project's design philosophy where the "active word" only changes through explicit interaction (clicks/selection/keyboard), not passive hover or scrolling.
