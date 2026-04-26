## Context
The "Drum Mode" (Mode C) and "Drum Window" (Mode W) share internal state for the yellow word indicator (`FSM.DW_CURSOR_LINE`, `FSM.DW_CURSOR_WORD`, etc.). However, synchronization of `FSM.DW_ACTIVE_LINE` (which is used to anchor the cursor after it is cleared with `Esc`) currently only occurs inside `tick_dw`, which is disabled when the Drum Window is closed. This causes Mode C to use stale positioning data for its cursor navigation.

## Goals / Non-Goals

**Goals:**
- Synchronize `FSM.DW_ACTIVE_LINE` with the currently playing subtitle line even when the Drum Window is closed, provided Drum Mode is active.
- Ensure `cmd_dw_esc` provides immediate visual feedback for both Drum Window and Drum Mode OSD.
- Maintain Mode C's independent scrolling behavior (it follows video time, not cursor position).
- Prevent crashes during mode transitions caused by parameter mismatches.

**Non-Goals:**
- Change the rendering logic of `draw_drum` or `draw_dw`.
- Modify how subtitles are loaded or parsed.

## Decisions

1. **Move `FSM.DW_ACTIVE_LINE` update to a shared scope**: The active line index will be calculated once per tick in `master_tick` and stored in `FSM.DW_ACTIVE_LINE` if either Drum Mode or Drum Window is active. This ensures that `cmd_dw_esc` always has a fresh line to sync the cursor to.
   
2. **Conditional OSD Updates in `cmd_dw_esc`**: Add a check for `FSM.DRUM == "ON"` in `cmd_dw_esc` to call `drum_osd:update()`.

3. **Harden `tick_dw` Signature and Call Sites**: 
   - Update `tick_dw` to accept `active_idx` as an explicit parameter to avoid redundant lookups.
   - Add a nil check for `active_idx` inside `tick_dw` to prevent crashes in the layout engine.
   - Update `cmd_toggle_drum_window` to calculate and pass the correct `active_idx` during the initial render.

4. **Retain Sticky-X and Navigation Logic**: The existing `cmd_dw_line_move` and `cmd_dw_word_move` logic already handles "middle of line" and "start/end of line" when the cursor is fresh (thanks to `FSM.DW_CURSOR_X = nil` and `FSM.DW_CURSOR_WORD = -1` being set by `Esc`).

## Risks / Trade-offs

**Risks:**
- Minimal. The logic reuses existing property values and lookups already occurring in the tick loop.
