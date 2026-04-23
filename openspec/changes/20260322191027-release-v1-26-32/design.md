# Design: Improved Drum Window Navigation & Pointer Logic

## System Architecture
The changes refine the Drum Window's input handling and state transition logic within `lls_core.lua`.

### Components
1.  **Pointer State Manager**:
    - Initializes `DW_CURSOR_WORD` to `-1`.
    - Updates `cmd_dw_scroll` and search result handlers to reset `DW_CURSOR_WORD`.
    - Updates arrow key handlers to check if `DW_CURSOR_WORD` is `-1` and activate it (e.g., set to `1`).
2.  **Custom Navigator (`cmd_dw_seek_delta`)**:
    - Replaces the `sub-seek` binding for `a` and `d` while the Drum Window is active.
    - Queries `Tracks.pri.subs` to find the start time of the next/previous subtitle relative to the current position.
    - Executes an `absolute+exact` seek to the identified timestamp.

## Implementation Strategy
- **Default Inactivity**: By setting the cursor index to `-1`, the rendering engine (`tick_drum`) can skip drawing the word-level highlight until the index is non-negative.
- **Table-Based Seeking**: Since the script already maintains an internal table of all subtitles, using this table for navigation avoids the quirks of mpv's built-in `sub-seek` property logic during pauses.
- **Unified Triggers**: Ensure that any action that changes the primary context (scrolling, searching) also clears the specific word selection to maintain visual consistency.
