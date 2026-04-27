## ADDED Requirements

### Requirement: Visual Parity Across Modes
All OSD overlays (Drum Window, Drum Mode, Tooltip) must render text with identical brightness, sharpness, and font weight when using the same styling parameters.

#### Scenario: Switching from Drum Mode to Drum Window
- **WHEN** the user opens the Drum Window ('w')
- **THEN** the active subtitle text should appear identical in brightness to its previous state in Drum Mode ('c')
- **AND** the sharpness of the text should remain consistent.

### Requirement: Semi-Automatic Calibration
Mouse interaction hit-zones must automatically synchronize with the visual layout defined by spacing parameters.

#### Scenario: Adjusting Visual Spacing
- **WHEN** the user sets `lls-dw_vsp` to a negative value or toggles `lls-dw_double_gap`
- **THEN** the clickable word zones must automatically shift their vertical positions to remain perfectly aligned with the new visual positions of the words.
- **AND** no manual re-calibration of `line_height_mul` should be required for basic structural changes.
