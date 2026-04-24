## Why

In "Book Mode", manual navigation through subtitles using the `a` and `d` keys correctly seeks the video and updates the active playback highlight, but fails to update the manual cursor focus (`FSM.DW_CURSOR_LINE`). This results in `Ctrl+C` (copy) operations targeting the subtitle that was active before entering Book Mode, rather than the one the user has just navigated to, breaking the "Stationary Viewport" interaction model.

## What Changes

- Update manual seek handlers (`a`/`d`) to synchronize the manual cursor focus (`FSM.DW_CURSOR_LINE`) with the new seek target in Book Mode.
- Ensure this update only occurs when no persistent selection (anchor) is active, preserving the "persist selection" feature.
- Maintain the stationary viewport by ensuring `FSM.DW_VIEW_CENTER` remains unchanged during these manual seeks in Book Mode.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `book-mode-navigation`: Update the manual navigation requirement to include cursor focus synchronization during seeks while maintaining viewport stability.

## Impact

- `scripts/lls_core.lua`: Logic modification in `cmd_dw_seek_delta`.
