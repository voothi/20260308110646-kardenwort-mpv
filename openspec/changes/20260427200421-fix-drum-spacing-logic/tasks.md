## 1. Preparation and Core Logic

- [x] 1.1 Review commit root `4c4bfca22b51e522a579d4605ec5357edeb4df4c` and analyze changes in branches `93db0ae538d990e0463a9a689db9eff704b1a0ea` and `828967d07419d361540e1750712b9eefd63cca84`.
- [x] 1.2 Define `calculate_sub_gap(prefix, font_size, lh_mul, vsp)` helper function in `lls_core.lua` to centralize gap height logic, ensuring the logic covers branches' changes.
- [x] 1.3 Identify all rendering loops in `draw_drum`, `draw_dw`, and `draw_tooltip` that use hardcoded `\N` or `\N\N` separators.

## 2. Rendering Updates

- [x] 2.1 Update `draw_drum` to use `calculate_sub_gap` for both hit-zone calculations and visual OSD separators.
- [x] 2.2 Update `draw_dw` to synchronize the visual `separator` with the `sub_gap` used in the layout engine.
- [x] 2.3 Update `draw_tooltip` to use the unified gap logic.
- [x] 2.4 Inject `{\vsp}` tags into subtitle separators to reflect the `block_gap_mul` fine-tuning visually.

## 3. Semi-automatic Adjustment and UI

- [x] 3.1 Update the semi-automatic adjustment mechanism to correctly calculate coefficients when in double interval mode.
- [x] 3.2 Ensure the semi-automatic adjustment mechanism functions properly when `drum_double_gap=no`.
- [x] 3.3 Update `cmd_toggle_drum` to show the active mode and gap state (e.g., "Drum Mode: ON [Double Gap: YES]").
- [x] 3.4 Add similar feedback to any other gap-toggling keybindings if they exist.

## 4. Verification

- [x] 4.1 Verify that the semi-automatic adjustment mechanism calculates correctly and scales subtitles precisely when double interval mode is set.
- [x] 4.2 Verify that `drum_double_gap=no` correctly switches the visual separator and hit-zones simultaneously without breaking the semi-auto adjustments.
- [x] 4.3 Verify that setting `drum_block_gap_mul` to a negative value visually compresses subtitles and that mouse clicks still hit the correct words.
- [x] 4.4 Ensure no regressions in "Regular Mode" (SRT style) when `srt_double_gap` is toggled.

## Progress Tracking & Calibration Anchors

- **20260427205535**: Initial proposal to merge branch logic and fix `drum_double_gap=no`.
- **20260427211802**: First implementation attempt with unified `calculate_sub_gap`.
- **20260427213340**: Identified cumulative error drift in single-gap mode click accuracy.
- **20260427215548**: Discovery that `block_gap_mul` was being applied twice to single-gaps.
- **20260427220327**: Reverted to stable `212448` merge for re-calibration testing.
- **20260427222353**: Experimented with stripping `\vsp` to isolate rendering jitter.
- **20260427222821**: Confirmed that `\vsp` stripping alone didn't solve the math mismatch.
- **20260427223931**: **SUCCESS**: Implemented decoupled hit-zone gap (0 for single-gap) and restored `/2` `\vsp` scaling for double-gap.
- **20260427225351**: Finalized `mpv.conf` with explicit `lls-drum_vsp` and `lls-srt_vsp` declarations.

