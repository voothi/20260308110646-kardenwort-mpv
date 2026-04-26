# Implementation Tasks: Subtitle Rendering and Interactivity Fixes

## 1. Core Rendering & Positioning

- [x] 1.1 Ensure `auto_offset` logic in `tick_drum` (lls_core.lua:L4030) is correctly applied to prevent track overlap while respecting user relative adjustments.
- [x] 1.2 Update `master_tick` rendering triggers (lls_core.lua:L4110-4111) to allow `pri_use_osd` and `sec_use_osd` to be active if `FSM.DRUM == "ON"`, regardless of `FSM.native_sub_vis`.

## 2. Interaction & Hit-Testing

- [x] 2.1 Refine `dw_get_str_width` (lls_core.lua:L2226) to ensure character-aware iteration for all font types.
- [x] 2.2 Standardize width heuristics in `dw_get_str_width` to avoid over-estimation of Cyrillic character widths.
- [x] 2.3 Modify `cmd_dw_double_click` (lls_core.lua:L3936) to prevent triggering `cmd_toggle_drum_window()` when interacting with the OSD.

## 3. Validation

- [ ] 3.1 Verify that adjusting `sub-pos` with `r/t` moves the OSD tracks correctly without overlapping.
- [ ] 3.2 Test Drum Mode `c` with native subtitles hidden (`s` key) to ensure the OSD remains visible and interactive.
- [ ] 3.3 Validate mouse-word alignment for Russian text in OSD mode.
