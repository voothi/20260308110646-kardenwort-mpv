# Proposal: 20260516204609-document-and-test-dw-esc-mode

## Context
Recent improvements between `v1.82.12` and `20260516204543` introduced the `DW Esc Mode` feature for the Drum Window (DW). This feature allows users to cycle between different behaviors when hitting Escape or exiting specific states within the DW. Currently, these changes are implemented but lack formal documentation, architectural specifications, and comprehensive "omnidirectional" tests to ensure stability and correctness across different usage scenarios.

## What Changes
- **Documentation & Specs**: Create formal specifications as an architect, detailing the logic of `DW Esc Mode` cycling and the specific behavior of each mode (`auto_follow_current`, `neutral_last_selection`, `neutral_current_subtitle`).
- **Omnidirectional Tests**: Develop a suite of tests that verify the feature from multiple angles (keyboard input, OSD feedback, state transitions) to ensure "surgical precision" in its operation.
- **Reference Material**: Update internal documentation to reflect the new `DW Esc Mode` options and their respective OSD labels.

## Capabilities

### New Capabilities
- `dw-esc-mode`: Defines and manages the escape behavior within the Drum Window navigation system, allowing users to choose how the focus/state is handled upon exit/escape.

### Modified Capabilities
- `drum-window-navigation`: Enhanced with configurable escape behavior and OSD status updates.

## Impact
- **Logic**: `scripts/kardenwort/main.lua` (cycling logic, OSD labels, state management).
- **Configuration**: `mpv.conf` (new keybinding `dw_key_cycle_esc_mode`).
- **User Interface**: OSD feedback for mode transitions.
