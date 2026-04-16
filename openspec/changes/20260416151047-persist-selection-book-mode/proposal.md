## Why

In Book Mode, users often select text (highlighting it in yellow) for deep analysis while navigating the audio track with `a` and `d` keys. Currently, this navigation resets the selection state to gray, forcing the user to re-select text after every seek. Persisting the selection during manual navigation in Book Mode is essential for a fluid study workflow.

## What Changes

- Modified `cmd_dw_seek_delta` logic to prevent resetting selection `ANCHOR` and `CURSOR` state while in Book Mode.
- Ensured that manual navigation via `a`/`d` keys preserves the active yellow highlight in the Drum Window when Book Mode is enabled.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `book-mode-navigation`: Add requirement for selection persistence during manual seek navigation.

## Impact

- `lls_core.lua`: Update `cmd_dw_seek_delta` and state management logic.
- Drum Window behavior: selection will persist during `a`/`d` seeks while Book Mode is ON.
