## 1. Test Environment Setup

- [ ] 1.1 Create `tests/acceptance/test_archived_changes.py`
- [ ] 1.2 Import necessary fixtures (`mpv`, `mpv_dual`) and utilities (`query_lls_state`)
- [ ] 1.3 Verify existing fixtures can be used for the new test cases

## 2. Implement Acceptance Tests

- [ ] 2.1 Implement `test_natural_progression_skip`: Verify `ACTIVE_IDX` advances in overlap zones.
- [ ] 2.2 Implement `test_seek_bindings_repeatable`: Verify `repeatable` flag in `input-bindings`.
- [ ] 2.3 Implement `test_movie_mode_autopause_boundary`: Verify autopause timing in small-gap scenarios.
- [ ] 2.4 Implement `test_fsm_gap_visibility`: Verify `cmd_toggle_sub_vis` works with Drum Window open.
- [ ] 2.5 Implement `test_fsm_gap_sec_pos_sync`: Verify `FSM.native_sec_sub_pos` synchronization.

## 3. Verification and Cleanup

- [ ] 3.1 Run `pytest tests/acceptance/test_archived_changes.py` and ensure all pass.
- [ ] 3.2 Run the full acceptance test suite to ensure no regressions.
- [ ] 3.3 Verify test results against the [Testing Plan](file:///C:/Users/voothi/.gemini/antigravity/brain/15f926b2-809b-4a05-a2d1-9eca40134b53/testing_plan_archived_changes.md).
