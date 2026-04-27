# Specification: VSP (Vertical Spacing Pixels) Support

## Overview
VSP allows for fine-grained pixel-level adjustment of vertical line spacing, bypassing the proportional constraints of `line_height_mul`.

## Visual Implementation
VSP is implemented using the `{\vsp%g}` ASS tag in the primary style block of the OSD overlay.

### Behavior
- **Positive VSP**: Increases the gap between lines by the specified pixel amount.
- **Negative VSP**: Decreases the gap, potentially causing text overlap if the value is too low.

## Calibration Integration
The "Semi-Automatic" engine must account for VSP in all hit-testing calculations:
- `vline_h` (Logical line height) must include `+ Options.xx_vsp`.
- `sub_gap` (Block separation) must include `+ Options.xx_vsp` if `double_gap` is enabled, as the blank line itself is affected by the VSP tag.

## Consistency
All LLS modes (`srt`, `dw`, `drum`, `tooltip`) must expose a `vsp` configuration option to maintain architectural parity.
