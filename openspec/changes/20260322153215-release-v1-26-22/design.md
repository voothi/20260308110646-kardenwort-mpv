# Design: Drum Window Hit-Test Calibration

## System Architecture
The hit-test engine in `lls_core.lua` is updated to incorporate the new multiplier parameters into its coordinate-to-word mapping logic.

### Components
1.  **Hit-Test Engine**:
    - Calculates the bounding boxes of lines and words.
    - Applies `dw_vline_h_mul` to the calculated vertical line height.
    - Applies `dw_sub_gap_mul` to the vertical space between discrete subtitle blocks.
    - Applies `dw_char_width` to determine character boundaries in monospace text.
2.  **Configuration Authority (`mpv.conf`)**:
    - Grouped settings allow users to define "Modes" (e.g., Mode 1 for font 30, Mode 2 for font 34).

## Implementation Strategy
- **Coordinate Mapping**: 
  - `visual_y = raw_y * vline_h_mul`
  - `gap_offset = sub_index * sub_gap_mul`
- **Monospace Assumption**: Selection accuracy relies on the `Consolas` monospace font; `dw_char_width` provides the necessary horizontal compensation for this specific typeface.
- **Mode Switching**: Use commented sections in `mpv.conf` to act as templates for different font size/multiplier pairings.
