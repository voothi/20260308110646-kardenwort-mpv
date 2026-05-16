## 1. Verification of Implementation

- [ ] 1.1 Verify Secondary-Only mode OSD rendering logic in `master_tick` to ensure primary suppression works.
- [ ] 1.2 Confirm `cmd_toggle_secondary_only_mode` correctly handles track availability and ensures secondary SID is selected.
- [ ] 1.3 Verify `dw_resolve_null_activation_line` priority logic in `scripts/kardenwort/main.lua` matches the specification.
- [ ] 1.4 Confirm `xpcall` recovery in `cmd_toggle_drum_window` correctly rolls back `FSM.DRUM_WINDOW` state.

## 2. Testing and Regression

- [ ] 2.1 Run automated acceptance tests: `tests/acceptance/test_20260514001942_dm_dw_state_edges.py`.
- [ ] 2.2 Verify `input.conf` bindings for `toggle-secondary-only` and `toggle-sub-visibility`.
- [ ] 2.3 Perform manual regression check on standard SRT-OSD visibility and Drum Mode transitions.
