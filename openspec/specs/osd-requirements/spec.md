# Specification: Global OSD Requirements

## Visual Parity Across Modes
All OSD overlays (Drum Window, Drum Mode, Tooltip) must render text with identical brightness, sharpness, and font weight when using the same styling parameters.

### Scenario: Switching from Drum Mode to Drum Window
- **WHEN** the user opens the Drum Window ('w')
- **THEN** the active subtitle text should appear identical in brightness to its previous state in Drum Mode ('c')
- **AND** the sharpness of the text should remain consistent.

## Semi-Automatic Calibration
Mouse interaction hit-zones must automatically synchronize with the visual layout defined by spacing parameters.

### Scenario: Adjusting Visual Spacing
- **WHEN** the user sets `kardenwort-dw_vsp` to a negative value or toggles `kardenwort-dw_double_gap`
- **THEN** the clickable word zones must automatically shift their vertical positions to remain perfectly aligned with the new visual positions of the words.
- **AND** no manual re-calibration of `line_height_mul` should be required for basic structural changes.

## Precise Tooltip Centering
The tooltip active line must be perfectly centered on the target playback line's midpoint when `tooltip_y_offset_lines=0`.

### Scenario: Displaying Tooltip for an Active Subtitle
- **WHEN** a translation tooltip is triggered for a specific line
- **AND** `tooltip_y_offset_lines` is set to `0`
- **THEN** the vertical center of the tooltip's active line should align exactly with the vertical center of the target line in the primary window.

