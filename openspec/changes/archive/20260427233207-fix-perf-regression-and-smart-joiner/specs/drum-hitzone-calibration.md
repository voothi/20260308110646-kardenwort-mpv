# Specification: Drum Mode Hit-Zone Calibration

## Problem Statement
In single-gap mode (`drum_double_gap=no`), the vertical spacing between subtitles rendered by `libass` (using `\N`) does not perfectly match the mathematical height (`font_size * drum_line_height_mul`) used for hit-zone calculation. This results in a cumulative "drift" where hit-zones for upper context lines move further away from the visual text.

## Requirements
1. **Vertical Alignment**: Mouse clicks on a word in any Drum Mode line must accurately register the correct `word_idx`.
2. **Cumulative Correction**: The correction must be cumulative for lines above the center, as the drift increases with distance from the bottom anchor.
3. **Configuration**: The user must be able to fine-tune this offset via `drum_upper_gap_adj`.
4. **Anchor Integrity**: Adjustments to upper lines must NOT shift the position of the active (center) line or any lower context lines.

## Technical Solution
- Introduce `Options.drum_upper_gap_adj` (default 0).
- In the hit-zone loop of `draw_drum`, if `abs_idx < center_idx` and `not d_gap`, add `adj` to the line gap.
- Add the total sum of `adj` to the `total_h` calculation to ensure the `y_start` offset correctly shifts the top of the block while keeping the bottom stationary.
