# Spec: Pointer Auto-Reset Triggers

## Context
Changing the visual context should clear specific word selections to prevent misleading highlights.

## Requirements
- Reset `FSM.DW_CURSOR_WORD` to `-1` whenever the user scrolls the Drum Window (mouse wheel).
- Reset `FSM.DW_CURSOR_WORD` to `-1` whenever a new subtitle is jumped to via the Search Mode result selection.
- Reset `FSM.DW_CURSOR_WORD` to `-1` whenever the user double-clicks a subtitle to seek (in Book Mode OFF / Drum Mode C).

## Verification
- Highlight a word in the Drum Window.
- Scroll the window up or down.
- Verify that the word highlight disappears.
- Perform a search and select a result; verify that no word is highlighted in the new context.
