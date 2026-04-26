# Proposal: Fix Yellow Word Indicator Consistency

## Summary
Align the yellow word indicator behavior in Mode C (Drum Mode) with Mode W (Drum Window) after pressing `Esc`. Ensure that the cursor correctly synchronizes with the active subtitle line and follows the expected pattern for arrow key navigation (middle of line for Up/Down, first/last word for Left/Right).

## Motivation
Currently, in Mode C, the yellow word indicator does not consistently appear in the same pattern as in Mode W after clearing it with `Esc`. This is due to `FSM.DW_ACTIVE_LINE` only being updated while the Drum Window is open, leading to stale cursor positioning when navigating in Mode C. Additionally, `cmd_dw_esc` only updates the Drum Window overlay, causing a delay in Mode C visual feedback.

## What Changes
- Update the master tick loop to keep `FSM.DW_ACTIVE_LINE` synchronized with playback even when the Drum Window is closed (specifically when Drum Mode is ON).
- Modify `cmd_dw_esc` to trigger an update for `drum_osd` when in Drum Mode, ensuring immediate visual feedback when the cursor is cleared.
- Ensure Mode C maintains its "no-scroll" behavior (subtitles don't scroll behind the pointer), which is the desired behavior for this mode.

## Capabilities

### New Capabilities
- none

### Modified Capabilities
- drum-window: Update cursor synchronization and escape behavior to be consistent across modes.

## Impact
- `scripts/lls_core.lua`: Modification to `master_tick`, `cmd_dw_esc`, and potentially `tick_dw` to ensure consistent state tracking.
- No changes to `input.conf` or `mpv.conf` are required as this is an internal logic fix.
