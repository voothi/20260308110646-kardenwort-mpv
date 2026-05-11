## ADDED Requirements

### Requirement: OSD Vertical Proximity Snapping
The hit-testing engine SHALL implement vertical proximity snapping for Drum Mode (OSD) interactions to ensure parity with Drum Window behavior.
- **Snap Logic**: Mouse interactions occurring in the vertical gap between subtitle lines SHALL snap to the nearest line vertically, provided the cursor is horizontally aligned with that line's text bounds.
- **Threshold**: Snapping SHALL only occur if the vertical distance to the nearest line is within a reasonable proximity (e.g., 60 pixels), preventing accidental triggers from unrelated screen areas.

#### Scenario: Right-click in the gap between context lines in Drum Mode
- **WHEN** Drum Mode is ON
- **AND** the user right-clicks in the vertical gap between two visible subtitle lines
- **THEN** the system SHALL trigger the tooltip for the nearest word on the closest line.
- **AND** the interaction SHALL NOT be ignored.

#### Scenario: Click strictly between lines in Drum Mode
- **WHEN** in Drum Mode
- **AND** the user clicks LMB in the gap between lines
- **THEN** the system SHALL update the logical cursor to the nearest word vertically.
