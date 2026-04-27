# Technical Specification: OSD Uniformity and Calibration

## 1. Unified Spacing Logic
The project utilizes a "Semi-Automatic" calibration model where visual spacing parameters directly drive the mouse interaction map. This applies to all LLS modes (`srt`, `dw`, `drum`, `tooltip`).

### 1.1 Vertical Line Height (`vline_h`)
The height of a single logical line (including its internal multiplier) is defined as:
```lua
vline_h = (font_size * line_height_mul) + vsp
```

### 1.2 Inter-Subtitle Gap (`sub_gap`)
The spacing between distinct subtitle blocks (or context lines) is defined as:
```lua
sub_gap = (font_size * block_gap_mul) + (double_gap ? vline_h : 0)
```

## 2. Global Uniformity Standard (GUS)
To ensure 100% visual parity across all overlays, the following canonical values are enforced as the system default for the `Consolas` font family:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `font_name` | `Consolas` | Primary monospace font. |
| `font_size` | `34` | Base text size. |
| `line_height_mul` | `0.87` | Vertical line compression for Consolas. |
| `block_gap_mul` | `-0.27` | Migration value to preserve legacy 0.6 gap with `double_gap=yes`. |
| `double_gap` | `true` | Standardized blank line separation. |
| `vsp` | `0` | Default vertical spacing pixels. |

## 3. Rendering Standards
All LLS renderers must utilize the following ASS tags to ensure identical brightness and layout behavior:
- **Color**: `{\1c&HFFFFFF&}` (Primary color tag for consistent layer treatment).
- **Wrapping**: `{\q2}` (No Wrap) to prevent layout softening.
- **Opacity**: `calculate_ass_alpha` utility for all `\1a`, `\3a`, and `\4a` tags.

## 4. Tooltip Centering
When `tooltip_y_offset_lines = 0`, the tooltip must align its vertical center to the vertical center of the target line.
- **Target Midpoint**: `osd_y` (The Y position of the target line in the primary OSD).
- **Tooltip Midpoint**: Calculated as `block_height / 2`, where `block_height` includes all context lines and gaps.
- **Positioning**: Use `{\an6}` (Right-Center) or `{\an4}` (Left-Center) with `\pos(x, final_y)` where `final_y = osd_y`.

## 5. Hit-Zone Map Generation
Metadata for mouse interaction (`FSM.DW_HIT_ZONES` and `drum_hit_zones`) must be generated using the exact same `vline_h` and `sub_gap` constants used in the rendering functions to ensure 1:1 pixel accuracy.
