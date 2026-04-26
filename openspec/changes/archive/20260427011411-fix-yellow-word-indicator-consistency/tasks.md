## 1. State Synchronization

- [x] 1.1 Extract active subtitle line lookup logic from `tick_dw` into a shared context or update `master_tick` to perform this lookup when `FSM.DRUM == "ON"`.
- [x] 1.2 Update `FSM.DW_ACTIVE_LINE` in the tick loop even if `FSM.DRUM_WINDOW` is "OFF".

## 2. Escape Behavior Refinement

- [x] 2.1 Modify `cmd_dw_esc` in `scripts/lls_core.lua` to call `drum_osd:update()` if `FSM.DRUM == "ON"`.
- [x] 2.2 Verify that `cmd_dw_esc` correctly syncs `FSM.DW_CURSOR_LINE` to the fresh `FSM.DW_ACTIVE_LINE`.

## 3. Stability and Bug Fixes

- [x] 3.1 Harden `tick_dw` with nil checks for `active_idx`.
- [x] 3.2 Update `cmd_toggle_drum_window` to pass `active_idx` to `tick_dw`.

## 4. Verification

- [x] 4.1 Test Mode C: Press `Esc` then `Up` -> verify cursor appears in the middle of the line above.
- [x] 4.2 Test Mode C: Press `Esc` then `Right` -> verify cursor highlights the first word.
- [x] 4.3 Test Mode C: Press `Esc` then `Left` -> verify cursor highlights the last word.
- [x] 4.4 Test Mode W: Verify that existing navigation behavior is unchanged.
- [x] 4.5 Verify that Mode C does not scroll subtitles during navigation.
