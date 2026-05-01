## 1. Infrastructure and Initialization

- [x] 1.1 Add `DW_TOOLTIP_HIT_ZONES` to the `FSM` state machine table.
- [x] 1.2 Initialize `DW_TOOLTIP_HIT_ZONES` as an empty table in the script initialization section.

## 2. Hit-Zone Population in Tooltip Rendering

- [x] 2.1 Update `draw_dw_tooltip` to clear `FSM.DW_TOOLTIP_HIT_ZONES` at the start of a fresh (non-cached) render.
- [x] 2.2 Refactor the tooltip rendering loop to calculate the precise OSD coordinates (x_start, y_top, y_bottom) for each visual line.
- [x] 2.3 Record word-level bounding boxes (Hit Zones) within each visual line, accounting for the `an6` right-aligned layout (starting at X=1800).
- [x] 2.4 Store the calculated hit zones in the `DW_TOOLTIP_DRAW_CACHE` and ensure they are restored correctly when serving from cache to maintain O(1) performance.

## 3. Hit Detection and Interaction

- [x] 3.1 Implement `dw_tooltip_hit_test(osd_x, osd_y)` to perform coordinate-based lookups against `FSM.DW_TOOLTIP_HIT_ZONES`.
- [x] 3.2 Update `lls_hit_test_all` to call `dw_tooltip_hit_test` when the tooltip is active (`FSM.DW_TOOLTIP_LINE ~= -1`).
- [x] 3.3 Ensure that hitting a word in the tooltip correctly returns the `sub_idx` (from `Tracks.sec.subs`) and the `logical_word_idx`.

## 4. Verification and Hardening

- [x] 4.1 Verify that clicking a Russian word in the tooltip updates the primary Drum Window selection immediately.
- [x] 4.2 Confirm that Shift-Selection and Ctrl-Selection (Paired Set) work correctly through the tooltip interface.
- [x] 4.3 Validate that hit detection remains accurate across various window aspect ratios by verifying `dw_get_mouse_osd` integration.
- [x] 4.4 Perform a regression test to ensure that tooltip hit zones do not interfere with main window interaction when they overlap or are near each other.
