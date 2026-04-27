# Specification: Semi-Automatic Calibration Engine

## Overview
The calibration engine synchronizes the logical mouse hit-zones with the visual layout defined in `mpv.conf`.

## The Spacing Formula
The vertical interval between logical lines is calculated dynamically:

### 1. Vertical Line Height (`vline_h`)
```lua
vline_h = (font_size * line_height_mul) + vsp
```

### 2. Inter-Subtitle Gap (`sub_gap`)
```lua
sub_gap = (font_size * block_gap_mul) + (double_gap ? vline_h : 0)
```

## Global Standards
For the **Consolas 34** environment, the following constants are enforced for perfect 1:1 accuracy:
- `line_height_mul`: **0.87**
- `block_gap_mul`: **-0.27** (Compensates for `double_gap=yes`)

## Implementation
- **Mode W**: Logic resides in `dw_build_layout` and `dw_hit_test`.
- **Mode C / SRT**: Logic resides in `draw_drum` (metadata generation) and `calculate_osd_line_meta`.
