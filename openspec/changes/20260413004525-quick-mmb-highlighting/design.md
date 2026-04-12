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
- **Export Logic reuse**: The existing export logic (currently in `cmd_dw_export_anki`) will be moved into a standalone function or passed as the callback to the new MMB handler.
- **Selection Persistence**: Maintain the logic where a single click (Anchor == Cursor) clears the anchor for LMB, but since the "up" callback for MMB happens before/during this, the export logic will correctly identify whether to export a phrase or a single word.

## Risks / Trade-offs

- **Risk: Accidental Exports**: Users might accidentally export text when trying to move the mouse with MMB (if they use it for something else). However, since MMB's primary and only function in this context according to `input.conf` is export, this is consistent.
- **Trade-off: Shared State**: Both LMB and MMB will now manipulate the same `DW_CURSOR` and `DW_ANCHOR` state variables. This is desired as they represent the single global selection in the Drum Window.
