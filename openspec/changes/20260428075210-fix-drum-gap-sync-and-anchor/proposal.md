## Why

The `drum_upper_gap_adj` parameter (drum mode c) is currently non-functional for visual rendering and ineffective for center-line calibration in bottom-anchored layouts. This creates a "blind" adjustment experience where hit-zones move without visual feedback, and the most critical line (the active subtitle) cannot be calibrated against vertical drift when the layout is anchored to the bottom.

## What Changes

- **Visual Sync**: Integrate `drum_upper_gap_adj` into the OSD rendering engine via the `\vsp` ASS tag, ensuring the visible text moves in perfect parity with the logical hit-zones.
- **Anchor Logic Overhaul**: Refactor the hit-zone calculation to allow calibration of the center (active) line relative to the anchor, or introduce a global offset to resolve block-wide vertical drift.
- **Bi-Directional Adjustment**: Potentially introduce a lower-gap adjustment or expand the upper-gap logic to handle cumulative drift that originates from either the top or bottom of the OSD block.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `osd-hit-zone-sync`: Update requirements to enforce visual-to-logical parity for all calibration parameters and ensure active-line calibratability regardless of anchor position.

## Impact

- `lls_core.lua`: Significant logic updates to `draw_drum` and hit-zone generation.
- `mpv.conf`: Documentation and possible introduction of new fine-tuning parameters.
- User Experience: Improved click accuracy and intuitive visual feedback during calibration.
