## 1. Configuration Update

- [ ] 1.1 Update `kardenwort-nav_cooldown` from 0.5s to 0.2s in mpv.conf
- [ ] 1.2 Verify configuration change is applied correctly

## 2. Diagnostics Property Restoration

- [ ] 2.1 Initialize `user-data/kardenwort/last_osd` property at script startup
- [ ] 2.2 Update `last_osd` property in `show_osd()` function
- [ ] 2.3 Verify IPC diagnostics contract works for tests

## 3. Dual-Track Anchoring in Time Seek

- [ ] 3.1 Add secondary target index computation in `cmd_seek_time()`
- [ ] 3.2 Add immediate `FSM.ACTIVE_IDX` anchoring before seek
- [ ] 3.3 Add immediate `FSM.SEC_ACTIVE_IDX` anchoring before seek
- [ ] 3.4 Add inline comment explaining the purpose of immediate anchoring

## 4. Dual-Track Anchoring in Replay Operations

- [ ] 4.1 Add secondary replay start index computation in `cmd_replay_sub()`
- [ ] 4.2 Add dual-track anchoring for Autopause OFF mode in `cmd_replay_sub()`
- [ ] 4.3 Add dual-track anchoring for Autopause ON mode in `cmd_replay_sub()`
- [ ] 4.4 Add dual-track anchoring in `tick_loop()` for loop iterations
- [ ] 4.5 Add dual-track anchoring in `tick_scheduled_replay()` for scheduled iterations

## 5. Test Implementation

- [ ] 5.1 Create `test_20260512223046_shift_ad_seek_anchor.py` test file
- [ ] 5.2 Add structural test for `cmd_seek_time` dual-track anchoring
- [ ] 5.3 Add runtime test for Shift+A/D dual-track synchronization
- [ ] 5.4 Create `test_20260512223306_replay_repeat_dual_sync.py` test file
- [ ] 5.5 Add test for repeated Replay in Autopause ON mode
- [ ] 5.6 Add test for repeated Replay in Autopause OFF mode

## 6. Documentation

- [ ] 6.1 Update docs/conversation.log with conversation history
- [ ] 6.2 Verify all changes are documented in conversation log

## 7. Validation

- [ ] 7.1 Run Shift+A/D seek anchor tests: `python -m pytest tests/acceptance/test_20260512223046_shift_ad_seek_anchor.py -q`
- [ ] 7.2 Run replay repeat dual sync tests: `python -m pytest tests/acceptance/test_20260512223306_replay_repeat_dual_sync.py -q`
- [ ] 7.3 Run configurable replay messages tests: `python -m pytest tests/acceptance/test_20260512220652_configurable_replay_messages.py -q`
- [ ] 7.4 Verify all tests pass (9 tests total)
- [ ] 7.5 Validate with manual mpv runtime playback for fast Shift+A/D scrubbing in DM mode
