## 1. Core Logic: Fluid Navigation

- [ ] 1.1 **Autopause Suppression**: Update `tick_autopause` to return if `time_pos <= FSM.TIMESEEK_INHIBIT_UNTIL`.
- [ ] 1.2 **Seek Inhibit Flag**: Modify `cmd_seek_time` to set `FSM.TIMESEEK_INHIBIT_UNTIL` on backward seek and clear on forward seek.
- [ ] 1.3 **Jerk-Back Suppression**: Gate jerk-back logic in `master_tick` with the inhibit flag.
- [ ] 1.4 **Inhibit Clearing**: Implement the clearing condition in `master_tick` (`time_pos > FSM.TIMESEEK_INHIBIT_UNTIL`).
- [ ] 1.5 **State Resets**: Ensure `cmd_seek_time` resets `LOOP_MODE`, `REPLAY_REMAINING`, and `last_paused_sub_end`.

## 2. Test Harness: LlsProbe & Padding

- [ ] 2.1 **Method Resolution**: Update `_func_body` in the IPC harness to fallback to `LlsProbe.{name}`.
- [ ] 2.2 **Snapshot Update**: Expose `rewind_transit_active` and `rewind_transit_until` in `LlsProbe._snapshot`.
- [ ] 2.3 **Test Message**: Register `lls-test-seek-time` for test-driven seek triggering.
- [ ] 2.4 **Standardize Padding**: Update `test_20260509134903_timeseek_transit.py` with 200ms padding and updated boundary timestamps.

## 3. Verification

- [ ] 3.1 **Regression Run**: Execute the full acceptance suite (`pytest tests/acceptance/`) and ensure all tests (including the updated transit test) pass.
- [ ] 3.2 **Manual Smoke Test**: Verify that `Shift+a/d` in `PHRASE` mode feels fluid and doesn't jerk at boundaries.
