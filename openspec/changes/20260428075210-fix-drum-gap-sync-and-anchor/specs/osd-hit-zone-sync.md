## ADDED Requirements

### Requirement: Visual-Logical Calibration Parity
All fine-tuning parameters that shift OSD hit-zones (specifically `drum_upper_gap_adj`) MUST be explicitly synchronized with the visual text rendering. The system SHALL use the `\vsp` ASS tag in the OSD separator logic to ensure that visible subtitles move in exact pixel parity with their corresponding mouse interaction zones.

#### Scenario: Visual Feedback for drum mode c
- **WHEN** the user sets `drum_upper_gap_adj` to `30`.
- **THEN** the visible upper context lines in Drum Mode MUST shift downwards by 30 pixels per gap, matching the relocation of the click-sensitive hit-zones.

### Requirement: Multi-Pivot Calibration
Calibration logic MUST NOT be limited to context lines above the center. The system SHALL support vertical offset correction for the active center line regardless of the OSD block's anchor position (`\an2` vs `\an8`). This ensures that cumulative drift originating from the anchor point (e.g., the bottom edge) can be corrected for the focal reading line.

#### Scenario: Correcting Bottom-Up Drift
- **WHEN** the OSD is bottom-anchored (`sub-pos=95`) and the active center line text appears below its logical hit-zone.
- **THEN** the system SHALL allow the user to apply a vertical adjustment that shifts the center line hit-zone downwards to restore alignment.
