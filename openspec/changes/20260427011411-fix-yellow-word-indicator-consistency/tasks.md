## 1. State Synchronization

- [ ] 1.1 Extract active subtitle line lookup logic from `tick_dw` into a shared context or update `master_tick` to perform this lookup when `FSM.DRUM == "ON"`.
- [ ] 1.2 Update `FSM.DW_ACTIVE_LINE` in the tick loop even if `FSM.DRUM_WINDOW` is "OFF".

## 2. Escape Behavior Refinement

- [ ] 2.1 Modify `cmd_dw_esc` in `scripts/lls_core.lua` to call `drum_osd:update()` if `FSM.DRUM == "ON"`.
- [ ] 2.2 Verify that `cmd_dw_esc` correctly syncs `FSM.DW_CURSOR_LINE` to the fresh `FSM.DW_ACTIVE_LINE`.

## 3. Verification

- [ ] 3.1 Test Mode C: Press `Esc` then `Up` -> verify cursor appears in the middle of the line above the current playback line.
- [ ] 3.2 Test Mode C: Press `Esc` then `Right` -> verify cursor highlights the first word of the current playback line.
- [ ] 3.3 Test Mode W: Verify that existing navigation behavior is unchanged.
- [ ] 3.4 Verify that Mode C does not scroll subtitles during navigation.
