## 1. Core Options & Logic Alignment

- [x] 1.1 Standardize `Options` table for all modes (add missing bold/size/spacing params).
- [x] 1.2 Update `calculate_ass_alpha` or usage sites to ensure `\1a` and `\4a` consistency.

## 2. Renderer Unification

- [x] 2.1 Standardize on `\1c`, `\3c`, and `\q2` in `draw_drum` (Drum Mode C / SRT).
- [x] 2.2 Standardize on `\1c`, `\3c`, and `\q2` in `draw_dw` (Drum Window).
- [x] 2.3 Standardize on `\1c`, `\3c`, and `\q2` in `draw_dw_tooltip`.
- [x] 2.4 Incorporate sophisticated Tooltip Centering logic for `y_offset_lines=0`.
- [x] 2.5 Audit `format_highlighted_word` for consistent tag usage. (Completed via standardizing the base color tags).

## 3. Semi-Automatic Calibration

- [x] 3.1 Update `dw_build_layout` to incorporate `dw_vsp` and `dw_double_gap` into `vline_h` and `sub_gap`.
- [x] 3.2 Update `dw_hit_test` to reflect the same spacing logic for vertical clamping.
- [x] 3.3 Update `draw_drum` hit-zone logic to account for `double_gap` and `vsp` in metadata creation.

## 4. Configuration & Verification

- [x] 4.1 Update `mpv.conf` with synchronized defaults for all OSD modes.
- [x] 4.2 Verify visual parity (brightness/sharpness) by toggling between Modes C and W.
- [x] 4.3 Verify click accuracy after changing `vsp` values in the Drum Window.
