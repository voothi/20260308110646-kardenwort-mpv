## 1. Technical Debt Cleanup

- [ ] 1.1 Remove `dw_nav_activation_repeat_is_locked` and related state from `main.lua`.
- [ ] 1.2 Remove `dw_get_live_playback_index_for_activation` and `dw_get_raw_current_index_for_activation` redundancy.
- [ ] 1.3 Clean up navigation binding wrappers in `manage_dw_bindings`.

## 2. Deterministic Engine Implementation

- [ ] 2.1 Implement `dw_create_nav_event_snapshot(evt)` helper.
- [ ] 2.2 Refactor `cmd_dw_line_move` to use snapshot-based index resolution.
- [ ] 2.3 Refactor `cmd_dw_word_move` to use snapshot-based index resolution.
- [ ] 2.4 Implement hard-locked initial activation for first-step arrows.

## 3. Requirement Alignment

- [ ] 3.1 Implement middle-word priority for first null-pointer UP activation.
- [ ] 3.2 Ensure Book Mode parity for snapshot resolution.

## 4. Validation

- [ ] 4.1 Update `test_20260514001942_dm_dw_state_edges.py` with specific boundary race tests.
- [ ] 4.2 Verify zero-lag UP activation at the first ~100ms of a subtitle.
- [ ] 4.3 Run full regression suite to ensure no breakage of existing selection logic.
