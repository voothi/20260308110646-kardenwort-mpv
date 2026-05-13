## 1. Instrumentation

- [ ] 1.1 Add `test-set-scrolloff` IPC hook to `scripts/kardenwort/main.lua` to allow dynamic scrolloff overrides during tests.
- [ ] 1.2 Add `test-corrupt-layout-cache` IPC hook to `scripts/kardenwort/main.lua` to simulate malformed cache entries (missing `height`).

## 2. Scrolloff Regression Tests

- [ ] 2.1 Implement `test_drum_scrolloff_clamping` in `tests/acceptance/test_layout_robustness.py` to verify `drum_scrolloff=0` stability.
- [ ] 2.2 Implement `test_dw_scrolloff_clamping` in `tests/acceptance/test_layout_robustness.py` to verify margin clamping in small windows.

## 3. Layout Robustness Regression Tests

- [ ] 3.1 Implement `test_layout_rebuild_on_cache_mismatch` in `tests/acceptance/test_layout_robustness.py` to verify the fix for the `nil` arithmetic crash.

## 4. Verification

- [ ] 4.1 Run the new test suite and verify that the layout engine survives cache corruption.
- [ ] 4.2 Perform a final audit of the `master_tick` performance to ensure diagnostic hooks don't introduce lag.
