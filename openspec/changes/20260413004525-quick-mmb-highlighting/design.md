# Design - Quick MMB Highlighting

## Context

Current mouse interaction in the Drum Window uses `MBTN_LEFT` for selection (via `make_mouse_handler`) and `MBTN_MID` for export (via `cmd_dw_export_anki`). The LMB handler supports dragging, auto-scrolling at edges, and selection tracking. The MMB handler is currently a simple button state toggle that triggers an export on release, but it does not support its own dragging logic, forcing users to select with LMB first.

## Goals / Non-Goals

**Goals:**
- Unify mouse selection logic between LMB and MMB.
- Add drag-to-select support to the Middle Mouse Button.
- Auto-trigger Anki export upon MMB release.

**Non-Goals:**
- Changing RMB behavior (translation tooltip).
- Modifying search mode mouse bindings.

## Decisions

- **Refactor `make_mouse_handler`**: Modify the existing factory function in `lls_core.lua` to accept an optional `on_up_callback`. This allows the MMB handler to reuse the complex dragging, auto-scroll, and boundary detection logic currently locked in the LMB handler.
- **Callback Integration**: The `on_up_callback` will be executed after the standard dragging teardown (removing key bindings, killing timers) but before the function returns.
- **Export Logic reuse**: The existing export logic (currently in `cmd_dw_export_anki`) will be moved into a standalone function `dw_anki_export_selection` which is passed as the callback to the updated MMB handler.
- **Selection Persistence (SCM Protection)**: To preserve the "SCM" commitment behavior, `make_mouse_handler` will include an "Inside Selection" check using a new helper function `is_inside_dw_selection`. If MMB `down` occurs inside an existing selection, the cursor/anchor will NOT be moved, allowing the existing range to be exported upon release.
- **Immediate Visual Feedback**: `make_mouse_handler` will trigger `drum_osd:update()` on the `down` event to ensure the Red selection highlight appears immediately upon button press, matching the LMB behavior.
- **Single-click clearing**: Maintain the logic where a single click (Anchor == Cursor) clears the anchor for LMB selection. For MMB, since the callback happens after this clearing, the export logic will correctly handle the single-word case (Anchor is -1) or the Commit case (Anchor matches previous state).

## Risks / Trade-offs

- **Risk: Accidental Exports**: Users might accidentally export text when trying to move the mouse with MMB (if they use it for something else). However, since MMB's primary and only function in this context according to `input.conf` is export, this is consistent.
- **Trade-off: Shared State**: Both LMB and MMB will now manipulate the same `DW_CURSOR` and `DW_ANCHOR` state variables. This is desired as they represent the single global selection in the Drum Window.
