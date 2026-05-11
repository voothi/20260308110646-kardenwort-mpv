## 1. FSM Refactoring

- [x] 1.1 Modify `cmd_toggle_drum` to explicitly deactivate Drum Window if it is currently active.
- [x] 1.2 Modify `cmd_toggle_drum_window` to explicitly deactivate Drum Mode if it is currently active.
- [x] 1.3 Remove the early return block in `cmd_toggle_drum` that previously blocked activation when DW was ON.
- [x] 1.4 Standardize the "Baseline Toggle" logic: pressing a mode's key while that mode is active MUST return the system to SRT (Single) mode.

## 2. Key Binding and Ignore List

- [x] 2.1 Implement a `register_ignore_keys()` function in `lls_core.lua` to suppress accidental key presses.
- [x] 2.2 Update `input.conf` to use the refined mode switching logic for `z/x` and `я/ч`.
- [x] 2.3 Ensure the Russian layout expansion logic correctly handles the new mode switching and ignored keys.

## 3. Verification

- [x] 3.1 Test SRT to Drum Mode (DM) transition and back.
- [x] 3.2 Test SRT to Drum Window (DW) transition and back.
- [x] 3.3 Test direct transition from DW to DM using the `x` key.
- [x] 3.4 Test direct transition from DM to DW using the `z` key.
- [x] 3.5 Verify that ignored keys are suppressed in both English and Russian layouts.
