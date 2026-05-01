## Context

The Kardenwort UI spans multiple modes: Drum Mode (C), Drum Window (W), and Regular SRT. The shared state `FSM.DW_CURSOR_LINE` and `FSM.DW_CURSOR_WORD` allows for a unified pointer, but implementation-level "state reset" logic in the toggle handlers currently prevents seamless transitions. Specifically, opening the Drum Window unconditionally resets the word indicator.

## Goals / Non-Goals

**Goals:**
- Preserve `FSM.DW_CURSOR_WORD` when transitioning from Drum Mode (C) or SRT to Drum Window (W).
- Ensure `FSM.DW_VIEW_CENTER` is updated to match `FSM.DW_CURSOR_LINE` when opening the window with an active pointer.
- Maintain consistent rendering of the yellow indicator across all OSD layers.

**Non-Goals:**
- Modifying the Pink selection set behavior.
- Changing the primary subtitle rendering font or layout.

## Decisions

- **Preservation over Reset**: Remove `FSM.DW_CURSOR_WORD = -1` from `cmd_toggle_drum_window`'s opening logic.
- **Adaptive Viewport Alignment**: Add a conditional check in `cmd_toggle_drum_window`: if `FSM.DW_CURSOR_LINE ~= -1`, set `FSM.DW_VIEW_CENTER = FSM.DW_CURSOR_LINE` to ensure the highlighted word is immediately visible.
- **Shared Indicator Logic**: Audit `tick_drum_osd` to ensure it renders the yellow highlight even when `FSM.DRUM == "OFF"`, provided `FSM.DW_CURSOR_WORD ~= -1` (Regular SRT mode support).

## Risks / Trade-offs

- **Viewport Jump**: If a user has a pointer active on a distant line and opens the window, the window will jump to that line. This is the desired behavior for synchronization but might be unexpected if the user intended to open the window at the current playback position. Rationale: Synchronization is prioritized for logical continuity.
