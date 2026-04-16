## Why

Users often select text (highlighting it in yellow) for study and analysis while navigating the audio track using the `a` and `d` keys. Currently, this manual navigation unconditionally resets the selection state, forcing the user to re-select text after every seek. Making the selection persist during manual navigation (both in Book Mode and Standard Mode) is essential for a fluid study and comprehension workflow.

## What Changes

- Modified `cmd_dw_seek_delta` logic to prevent resetting the selection `ANCHOR` and `CURSOR` state during manual seeks.
- Ensured that manual navigation via `a`/`d` keys preserves the active yellow highlight in the Drum Window globally, improving consistency with standard playback behavior.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `book-mode-navigation`: Add requirement for selection persistence during manual seek navigation.

## Impact

- `lls_core.lua`: Update `cmd_dw_seek_delta` and state management logic.
- Drum Window behavior: selection will persist during `a`/`d` seeks while Book Mode is ON.
