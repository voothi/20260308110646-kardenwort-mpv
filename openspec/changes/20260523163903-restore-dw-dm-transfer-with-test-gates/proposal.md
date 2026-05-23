## Why

The branch was intentionally rolled back to `e7003003` after accumulated DW/DM transparency regressions, but that rollback also removed a large, already-completed functionality set from `a89c364c`. We need a controlled transfer that restores those capabilities with stronger regression coverage, especially for DW/DM window transparency, click accuracy, and long-subtitle spacing.

## What Changes

- Transfer the completed implementation delta from `e7003003..a89c364c` for `scripts/kardenwort/main.lua` and the associated regression test suite.
- Apply a test-first gate for all affected behavior by restoring and running:
  - `tests/unit/test_dw_pure_logic.py`
  - `tests/acceptance/test_20260521133435_dw_top_alignment.py`
  - `tests/acceptance/test_20260522162418_tooltip_window_degradation.py`
  - `tests/acceptance/test_20260522163656_tag_walk_regressions.py`
  - updates to `tests/acceptance/test_20260509102214_spec_depth_pass2.py`
- Restore DW accuracy and layout behaviors:
  - dynamic block-top clamping and safe-area margin support,
  - customizable wrap spacing for long subtitle visual lines,
  - render-driven hit-zone caching and direct hit-test dispatch.
- Restore DM/DW tooltip stability and transparency behavior:
  - prevent double-dark layering in DM + `background-box`,
  - preserve tooltip spacing/layout integrity for wrapped translations,
  - keep tooltip render state/caches consistent after transitions.
- Restore punctuation interactivity parity (DM with DW-like token selection behavior).
- Reintroduce the validated function set from the completed branch, including newly introduced helpers:
  - `dw_calculate_block_top`
  - `dw_vline_height`
  - `dw_get_str_width_proportional`
  - `get_dw_drag_threshold_px`
  - `get_dw_mouse_auto_scroll_interval`
  - `dw_pointer_exceeded_drag_threshold`
  - `dw_resolve_neighbor_word`
  - `resolve_tooltip_target_line`
  - `validate_callback`

## Capabilities

### New Capabilities
*None*

### Modified Capabilities

- `drum-window`: Restore clamped layout, wrapped-line spacing control, and render-synchronized hit testing.
- `drum-window-tooltip`: Restore overflow-safe tooltip rendering and DM background-box transparency neutrality.
- `drum-context`: Restore punctuation interaction parity for DM token-level selection.

## Impact

- **Affected code:** `scripts/kardenwort/main.lua`
- **Affected tests:**  
  `tests/unit/test_dw_pure_logic.py`  
  `tests/acceptance/test_20260509102214_spec_depth_pass2.py`  
  `tests/acceptance/test_20260521133435_dw_top_alignment.py`  
  `tests/acceptance/test_20260522162418_tooltip_window_degradation.py`  
  `tests/acceptance/test_20260522163656_tag_walk_regressions.py`
- **Risk focus:** DW/DM transparency layering, tooltip vertical alignment with long wrapped lines, and pointer/click drift regressions.
