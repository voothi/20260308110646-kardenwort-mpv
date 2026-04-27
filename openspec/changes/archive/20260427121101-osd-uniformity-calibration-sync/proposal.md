# Proposal: OSD Uniformity and Semi-Automatic Calibration

## Problem
The current OSD system (Drum Window, Drum Mode, Tooltip) suffers from visual and logical inconsistencies:
1. **Brightness Discrepancy**: Some modes appear brighter or thicker than others despite sharing identical font and opacity settings.
2. **Spacing Mismatch**: Vertical intervals between lines differ between the Drum Window and Tooltip.
3. **Calibration Fragility**: Changing visual spacing (e.g., toggling `double_gap` or `vsp`) currently breaks mouse interaction unless manual multipliers are meticulously recalculated.
4. **Lack of Uniformity**: Configuration parameters are not standardized across all modes, leading to confusion when trying to achieve a consistent look.

## Proposed Change
Implement a "Semi-Automatic Calibration" system and enforce visual parity across all OSD components.

### Key Features
1. **Semi-Automatic Calibration**: Update the hit-testing logic (`dw_build_layout`, `dw_hit_test`, and `draw_drum`) to automatically factor in visual settings like `vsp` and `double_gap`. This ensures the mouse "just works" regardless of the styling.
2. **Visual Parity**: Unify internal rendering tags (`\1c`, `\1a`, `\q2`) across all modes to resolve brightness and sharpness differences.
3. **Global Uniformity Standard**: Enforce 100% value parity across all modes. By default, `srt`, `dw`, `drum`, and `tooltip` will share identical font (Consolas), size (34), and spacing (`line_height_mul=0.87`, `double_gap=yes`).
4. **Interval Synchronization**: Lock the vertical spacing logic of the Tooltip to match the Drum Window's behavior.
5. **Precision Tooltip Centering**: Implement logic to ensure that `tooltip_y_offset_lines=0` centers the tooltip's active line exactly on the middle of the target "white line".
6. **The Migration Formula**: Introduce `block_gap_mul` support to all modes. For `Consolas 34` with `double_gap=yes`, a value of `-0.27` preserves legacy click accuracy while utilizing the new "smart" logic.

## Benefits
- **User-Centric Configuration**: Users can style the OSD declaratively in `mpv.conf` without worrying about breaking technical calibration.
- **Visual Excellence**: A consistent, premium look across all modes with no mysterious brightness or sharpness jumps.
- **Robustness**: Reduces the manual tuning required when switching fonts or font sizes.
- **Single Source of Truth**: Calibration is now centralized; adjusting visuals automatically updates the interaction map.
