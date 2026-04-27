## 1. Preparation and Core Logic

- [ ] 1.1 Review commit root `4c4bfca22b51e522a579d4605ec5357edeb4df4c` and analyze changes in branches `93db0ae538d990e0463a9a689db9eff704b1a0ea` and `828967d07419d361540e1750712b9eefd63cca84`.
- [ ] 1.2 Define `calculate_sub_gap(prefix, font_size, lh_mul, vsp)` helper function in `lls_core.lua` to centralize gap height logic, ensuring the logic covers branches' changes.
- [ ] 1.3 Identify all rendering loops in `draw_drum`, `draw_dw`, and `draw_tooltip` that use hardcoded `\N` or `\N\N` separators.

## 2. Rendering Updates

- [ ] 2.1 Update `draw_drum` to use `calculate_sub_gap` for both hit-zone calculations and visual OSD separators.
- [ ] 2.2 Update `draw_dw` to synchronize the visual `separator` with the `sub_gap` used in the layout engine.
- [ ] 2.3 Update `draw_tooltip` to use the unified gap logic.
- [ ] 2.4 Inject `{\vsp}` tags into subtitle separators to reflect the `block_gap_mul` fine-tuning visually.

## 3. Semi-automatic Adjustment and UI

- [ ] 3.1 Update the semi-automatic adjustment mechanism to correctly calculate coefficients when in double interval mode.
- [ ] 3.2 Ensure the semi-automatic adjustment mechanism functions properly when `drum_double_gap=no`.
- [ ] 3.3 Update `cmd_toggle_drum` to show the active mode and gap state (e.g., "Drum Mode: ON [Double Gap: YES]").
- [ ] 3.4 Add similar feedback to any other gap-toggling keybindings if they exist.

## 4. Verification

- [ ] 4.1 Verify that the semi-automatic adjustment mechanism calculates correctly and scales subtitles precisely when double interval mode is set.
- [ ] 4.2 Verify that `drum_double_gap=no` correctly switches the visual separator and hit-zones simultaneously without breaking the semi-auto adjustments.
- [ ] 4.3 Verify that setting `drum_block_gap_mul` to a negative value visually compresses subtitles and that mouse clicks still hit the correct words.
- [ ] 4.4 Ensure no regressions in "Regular Mode" (SRT style) when `srt_double_gap` is toggled.
