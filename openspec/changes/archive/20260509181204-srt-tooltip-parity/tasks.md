## 1. Refactor Tooltip Eligibility

- [x] 1.1 Rename `is_drum_tooltip_mode_eligible` to `is_osd_tooltip_mode_eligible` in `scripts/lls_core.lua`.
- [x] 1.2 Update call sites of the renamed function (lines 4408, 4450, 4491).
- [x] 1.3 Implement the new eligibility logic in `is_osd_tooltip_mode_eligible` to support SRT OSD.

## 2. Validation

- [x] 2.1 Create a regression test `tests/acceptance/test_20260509181204_srt_tooltip_parity.py` that verifies tooltip eligibility in SRT mode.
- [x] 2.2 Verify that the tooltip correctly follows the active line and selection in SRT mode via the test.
- [x] 2.3 Ensure no regressions in Drum Mode and Drum Window tooltip behavior.
