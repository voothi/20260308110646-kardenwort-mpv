## ADDED Requirements

### Requirement: Symmetrical Seek Keys
The system SHALL map the alternative 2-second seek commands to equivalent physical keys across English and Russian keyboard layouts.

#### Scenario: Seeking in Russian layout
- **WHEN** the user presses `Ф` or `В`
- **THEN** the system SHALL execute an exact 2-second seek (equivalent to `Shift+A` and `Shift+D`).
