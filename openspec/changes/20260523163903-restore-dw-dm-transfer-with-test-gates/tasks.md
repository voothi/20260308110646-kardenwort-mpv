## 1. Test-First Recovery Gate

- [x] 1.1 Restore the transferred regression tests from `a89c364c` into the current branch (`tests/unit/test_dw_pure_logic.py`, `tests/acceptance/test_20260521133435_dw_top_alignment.py`, `tests/acceptance/test_20260522162418_tooltip_window_degradation.py`, `tests/acceptance/test_20260522163656_tag_walk_regressions.py`, and updates to `tests/acceptance/test_20260509102214_spec_depth_pass2.py`).
- [x] 1.2 Run the targeted pytest suites to establish baseline behavior on rollback code before restoring `main.lua`.

## 2. Main.lua Functionality Transfer

- [x] 2.1 Restore `scripts/kardenwort/main.lua` from `a89c364c` and verify the helper-function inventory is present (`dw_calculate_block_top`, `dw_vline_height`, `dw_get_str_width_proportional`, `get_dw_drag_threshold_px`, `get_dw_mouse_auto_scroll_interval`, `dw_pointer_exceeded_drag_threshold`, `dw_resolve_neighbor_word`, `resolve_tooltip_target_line`, `validate_callback`).
- [x] 2.2 Validate DW/DM transparency safeguards in `draw_dw_tooltip`, including the DM + `background-box` neutralization path that prevents double-dark accumulation.
- [x] 2.3 Validate restored DW layout/hit-test behavior for clamping, wrap-line spacing, and cached hit-zone dispatch.

## 3. Regression Verification

- [x] 3.1 Run `tests/unit/test_dw_pure_logic.py` and resolve any transfer-level breakage.
- [x] 3.2 Run acceptance suites for top alignment, tooltip degradation, and tag-walk regressions, then resolve any transfer-level breakage.
- [x] 3.3 Run `tests/acceptance/test_20260509102214_spec_depth_pass2.py` to ensure no spec-depth regression from the transfer.

## 4. Finalization

- [x] 4.1 Mark all completed tasks and provide a concise manual verification checklist for DW/DM transparency and long wrapped subtitle rendering.
