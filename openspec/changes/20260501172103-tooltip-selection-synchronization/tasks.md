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

## 4. Verification and Hardening (Finalized)

- [x] 4.1 Verify that clicking a Russian word in the tooltip updates the primary Drum Window selection immediately.
- [x] 4.2 Confirm that Shift-Selection and Ctrl-Selection (Paired Set) work correctly through the tooltip interface.
- [x] 4.3 Implement and verify "Sticky Quick-View" to prevent flickering during RMB-hold vertical movement.
- [x] 4.4 Hardened interaction: Implemented `is_tooltip_hit` check to eliminate click-blinking.
- [x] 4.6 Regression test: Verified that hit-zones remain accurate and synchronized across all window aspect ratios.
- [x] 4.7 Refactor: Implemented "Two-Screen" (Pri/Sec) parameter schema in `Options` and `mpv.conf`.
- [x] 4.8 Optimization: Flattened hit-test dispatcher logic using track-aware `is_pri` flags.
- [x] 4.9 Aesthetics: Synchronized Tooltip background and border weight with Drum Mode secondary track standards.
- [x] 4.10 Audit: Verified all `mpv.conf` parameters are fully functional (no stubs).
