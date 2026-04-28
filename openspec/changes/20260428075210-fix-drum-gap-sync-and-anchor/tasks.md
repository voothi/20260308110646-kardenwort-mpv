## 1. Core Logic Refactoring

- [ ] 1.1 Update `get_separator(prev_is_active)` in `lls_core.lua` to accept an `adj` parameter.
- [ ] 1.2 Implement `\vsp` injection logic within `get_separator` for single-gap mode: `{\vsp(vsp_base + adj)}\N{\vsp(vsp_base)}`.

## 2. Anchor-Aware Gap Adjustment

- [ ] 2.1 Refactor `adj` calculation in `draw_drum` hit-zone loop to apply cumulatively starting from the anchor (`\an2` vs `\an8`).
- [ ] 2.2 Ensure the Center (Active) line is included in the cumulative shift if it is displaced relative to the anchor point.

## 3. Visual-Logical Integration

- [ ] 3.1 Pass the anchor-aware `adj` into the `get_separator` calls during the `all_text` assembly loop in `draw_drum`.
- [ ] 3.2 Synchronize the `total_h` calculation to ensure the starting `y_pixel` position remains consistent between rendering and hit-testing.

## 4. Verification & Calibration

- [ ] 4.1 Verify that setting `drum_upper_gap_adj=30` visibly shifts the Drum Mode text downwards.
- [ ] 4.2 Verify that the center-line hit-zone correctly tracks the center-line text in bottom-anchored mode (`sub-pos=95`).
- [ ] 4.3 Confirm that `drum_double_gap=yes` behavior remains unaffected by these changes.
