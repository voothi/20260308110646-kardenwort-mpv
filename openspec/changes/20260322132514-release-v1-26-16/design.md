# Design: Smart Font Scaling Integration

## System Architecture
The scaling engine is embedded within `lls_core.lua` and utilizes mpv's property observation system to maintain subtitle legibility across window resizes.

### Components
1.  **Scaling Engine**:
    - Calculates `perfect_comp` based on the ratio between current window height and a 1080p baseline.
    - Applies the `comp_scale` formula using the user-defined `font_scale_strength`.
2.  **Configuration Manager**:
    - Reads `font_scale_strength` from `script-opts`.
    - Allows enabling/disabling the feature via `font_scaling_enabled`.
3.  **Property Observer**:
    - Monitors `osd-dimensions` to trigger scaling recalculations on window resize.
    - Monitors `track-list` to re-apply scaling when switching subtitle tracks (ensuring `.ass` files are bypassed).

## Implementation Strategy
- **Baseline Logic**: Use 1080px as the reference height where scaling is `1.0`.
- **Formula Application**: 
  - `perfect_comp = 1080 / current_height`
  - `comp_scale = 1.0 + (perfect_comp - 1.0) * strength`
- **Exclusion Logic**: Detect `.ass` tracks and skip scaling to avoid breaking embedded styles and positioning tags.
- **Cleanup**: Remove `scripts/fixed_font.lua` to prevent duplicate scaling logic.
