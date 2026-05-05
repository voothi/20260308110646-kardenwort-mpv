## ADDED Requirements

### Requirement: Symmetrical Seek Keys
The system SHALL map the alternative 2-second seek commands to equivalent physical keys across English and Russian keyboard layouts.

#### Scenario: Seeking in Russian layout with directional feedback
- **WHEN** the user presses `Ф` or `В`
- **THEN** the system SHALL execute `lls-seek_time_backward` or `lls-seek_time_forward` respectively.
- **THEN** the system SHALL display the directional OSD feedback (Left for `Ф`, Right for `В`).
