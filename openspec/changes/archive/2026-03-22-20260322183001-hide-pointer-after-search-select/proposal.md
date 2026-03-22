# Proposal: Hide Pointer After Search Selection

## Summary
Ensure that the Drum Window pointer remains inactive (`-1`) after a user selects a subtitle from the search results.

## Problem
Currently, when a search result is selected (via `ENTER` or mouse click), the Drum Window jumps to the selected line but automatically highlights the first word (`DW_CURSOR_WORD = 1`). This is inconsistent with the recently implemented behavior where the pointer starts inactive when opening the window or scrolling.

## Proposed Solution
Modify the search selection logic in `lls_core.lua` to set `FSM.DW_CURSOR_WORD = -1` instead of `1` when a result is chosen. This ensures that the pointer remains hidden until the user interacts with the arrow keys.

## Benefits
-   **Consistency**: Aligns search navigation with window opening and scrolling behavior.
-   **Improved UX**: Prevents accidental word-level copying right after a search leap.
