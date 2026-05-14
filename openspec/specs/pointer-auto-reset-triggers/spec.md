# Spec: Pointer Auto-Reset Triggers

## Context
Changing the visual context should clear specific word selections to prevent misleading highlights.

## Requirements
- Do **not** reset `FSM.DW_CURSOR_WORD` when the user performs manual viewport scrolling (mouse wheel or keyboard scroll keys) in Drum Window / Drum Mode.
- Manual scroll SHALL preserve active pointer and selection continuity to keep focus on selected material.
- Reset `FSM.DW_CURSOR_WORD` to `-1` whenever a new subtitle is jumped to via the Search Mode result selection.
- Reset `FSM.DW_CURSOR_WORD` to `-1` whenever the user double-clicks a subtitle to seek (in Book Mode OFF / Drum Mode C).
- Selection Reset (via Esc or Mining) MUST restore auto-follow state:
    - Set `FSM.DW_FOLLOW_PLAYER = true`
    - Set `FSM.DW_SEEKING_MANUALLY = false`
    - Set `FSM.DW_SEEK_TARGET = -1`
    - Synchronize `FSM.DW_ACTIVE_LINE` to the live playback position to prevent stale viewport jumps.

## Verification
- Highlight a word in the Drum Window.
- Scroll the window up or down.
- Verify that the word highlight remains active.
- Perform a search and select a result; verify that no word is highlighted in the new context.

