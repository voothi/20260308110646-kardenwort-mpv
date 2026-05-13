## Context

The Kardenwort Drum Window (DW) implements a complex text navigation and selection system inspired by modern text editors like VSCode. This includes:
- Token-level navigation (Arrow keys).
- Multi-line subtitle support with vertical movement.
- Selection extension (Shift + Arrows).
- Jump navigation/selection (Ctrl + Arrows, Ctrl + Shift + Arrows).
- Line-to-line transitions (moving cursor past the last word of a line).

While the logic exists in `cmd_dw_word_move` and `cmd_dw_line_move`, it lacks comprehensive functional tests to prevent regressions during the v1.80.0 release cycle.

## Goals / Non-Goals

**Goals:**
- Implement a suite of acceptance tests covering all VSCode-inspired movement and selection patterns.
- Verify state transitions of `DW_CURSOR_LINE`, `DW_CURSOR_WORD`, `DW_ANCHOR_LINE`, and `DW_ANCHOR_WORD`.
- Ensure boundary conditions (first/last line, empty lines, multi-line subs) are handled correctly.
- Verify "Sticky-X" behavior (vertical navigation preserves horizontal position).

**Non-Goals:**
- Testing mouse drag selection (this is covered by geometry stability tests).
- Testing Anki export logic (covered elsewhere).

## Decisions

- **Test Framework**: Use `pytest` with the existing `conftest.py` infrastructure.
- **Verification Method**: 
    - Trigger movements via `mp.command("keypress ...")`.
    - Query FSM state via `script-message-to kardenwort state-query` and reading `user-data/kardenwort/state`.
- **Test Scenarios**:
    1. **Basic Movement**: LEFT/RIGHT/UP/DOWN.
    2. **Selection Extension**: Shift + LEFT/RIGHT/UP/DOWN.
    3. **Jump Movement**: Ctrl + LEFT/RIGHT.
    4. **Jump Selection**: Ctrl + Shift + LEFT/RIGHT.
    5. **Line Transition**: RIGHT at the end of a line moves to the next line's start.
    6. **Sticky-X**: DOWN from a long line to a short line and back to a long line.

## Risks / Trade-offs

- **Timing**: `keypress` events and `state-query` might require short sleeps to ensure the Lua event loop has processed the input.
- **Complexity**: Testing multi-line subtitles requires specific SRT fixtures with long lines that trigger wrapping.
