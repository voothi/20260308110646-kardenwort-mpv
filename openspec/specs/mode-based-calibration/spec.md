# Spec: Mode-Based Calibration

## Context
Different font sizes require different multiplier sets.

## Requirements
- Organize `mpv.conf` to group font size with its corresponding multipliers.
- Provide clear labels for different calibration "Modes".
- Ensure that updating the mode settings correctly overrides the script's internal defaults.

### Semi-Automatic Calibration Engine
The calibration engine synchronizes the logical mouse hit-zones with the visual layout defined in `mpv.conf`.

1.  **Vertical Line Height (`vline_h`)**: `(font_size * line_height_mul) + vsp`
2.  **Inter-Subtitle Gap (`sub_gap`)**: `(font_size * block_gap_mul) + (double_gap ? vline_h : 0)`

### Global Standards (Consolas 34)
The following constants are enforced for perfect 1:1 accuracy:
- `line_height_mul`: **0.87**
- `block_gap_mul`: **-0.27** (Compensates for `double_gap=yes`)

## Verification
- Switch from "Mode 1" (default) to "Mode 2" (calibrated for font 34) in `mpv.conf`.
- Verify that selection accuracy is improved at the higher font size.
