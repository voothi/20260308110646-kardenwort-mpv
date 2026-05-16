## Why

The project needed a dedicated "Secondary Only" subtitle mode to allow users to focus on translations or supplementary text while keeping primary subtitles internally synchronized for mining and navigation. Additionally, the Drum Window's null-activation logic required hardening to ensure stable line resolution across state transitions, preventing lookahead-derived context from overriding actual player position.

## What Changes

- **Secondary Only Mode**: Introduced a new state where only the secondary subtitle track is visible, while the primary track remains active in the background for FSM logic.
- **Subtitle Visibility Cycling**: Refactored `cmd_toggle_sub_vis` to cycle through three states: Primary Only, Both, and Secondary Only (Top).
- **DW Resolution Hardening**: Modified `dw_resolve_null_activation_line` to prioritize `FSM.DW_ACTIVE_LINE` and `FSM.ACTIVE_IDX` over lookahead context during null activations.
- **Error Recovery**: Added `xpcall` and state rollback to `cmd_toggle_drum_window` to ensure the UI doesn't get stuck in a "DOCKED" state if a Lua error occurs during initialization.
- **Input Configuration**: Updated `input.conf` to bind the new visibility cycling and secondary-only mode.

## Capabilities

### New Capabilities
- `secondary-only-mode`: Implementation of a display-only filter for secondary tracks that maintains full FSM synchronization with primary tracks.

### Modified Capabilities
- `drum-window`: Hardened line resolution for null pointers and implemented atomic error recovery for window toggling.
- `display`: Updated visibility cycling logic to incorporate the new "Secondary Only" state.

## Impact

- `scripts/kardenwort/main.lua`: Major logic updates for visibility states and DW resolution.
- `input.conf`: Updated keyboard mappings for the new functionality.
- `tests/acceptance/test_20260514001942_dm_dw_state_edges.py`: New structural tests for DW line resolution.
