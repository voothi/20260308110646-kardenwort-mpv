## ADDED Requirements

### Requirement: Semantic Copy Mode Labels
The context copy system SHALL use human-readable labels to identify the current copy target during the selection cycle.

#### Labels:
- `A (Primary/Target)`
- `B (Secondary/Translation)`
- `Fixed to Primary (Single Track)`

#### Scenario: Cycling copy mode
- **WHEN** the user presses the copy-cycle hotkey (`z`)
- **THEN** the OSD SHALL display the descriptive label corresponding to the new mode.
