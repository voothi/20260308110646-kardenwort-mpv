## Why

In Drum Mode and SRT mode, paired selection using `f` or `Ctrl+LMB` successfully selects the items, but fails to provide the expected "Pink" visual feedback indicating they are part of the `ctrl_pending_set`. This creates a confusing user experience because users cannot tell which words are currently selected for multi-word export outside of the Drum Window. Fixing this ensures consistent visual feedback across all reading modes.

## What Changes

- Ensure `ctrl_pending_set` (pink selection) visual feedback works correctly outside of Drum Window (e.g., Book Mode, windowless mode, SRT mode).
- Unify the rendering logic or state synchronization for multiselect so that it triggers OSD/subtitle updates in all modes when a word is toggled into the paired selection set.
- Add comprehensive automated tests to verify paired selection rendering in all modes.

## Capabilities

### New Capabilities

### Modified Capabilities
- `ctrl-multiselect`: Explicitly require visual feedback for paired selections in all rendering modes (Drum Window, Book Mode, Windowless Mode, SRT Mode).

## Impact

- Core rendering components handling Book/SRT mode displays (e.g., `src/lls_core.lua`, `src/fsm/`).
- Regression testing harness (`tests/acceptance/`).
