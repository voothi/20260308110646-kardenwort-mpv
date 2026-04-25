# Spec: Deactivated Pointer Logic

## Context
A persistent word pointer can interfere with context-level copying and visual clarity upon window opening.

## Requirements
- Initialize `FSM.DW_CURSOR_WORD` to `-1` whenever the Drum Window is opened.
- The `tick_drum` rendering engine must NOT highlight any word if `FSM.DW_CURSOR_WORD` is `-1`.
- The arrow key handlers (`UP`, `DOWN`, `LEFT`, `RIGHT`) must set `FSM.DW_CURSOR_WORD` to a valid index (e.g., `1` or the first visible word) if it is currently `-1`.

## Verification
- Open the Drum Window (`w`).
- Verify that no word is highlighted in red.
- Press `RIGHT` arrow.
- Verify that the first word of the active line is now highlighted.
