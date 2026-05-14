## ADDED Requirements

### Requirement: Deterministic Event Snapshotting SHALL be implemented
The system SHALL capture a complete state snapshot (Active Line Index, Playback Timestamp, Pause State, and Keyboard Repeat Status) at the exact moment a navigation key-event (`down` or `press`) is received.

#### Scenario: Capturing snapshot on UP
- **WHEN** the user presses the UP key while playback is active
- **THEN** the system SHALL immediately store a temporary `EVENT_SNAPSHOT` containing the current `time-pos` and the resolved playback index
- **AND** this snapshot SHALL be the exclusive source of truth for the subsequent navigation resolution.

### Requirement: Snapshot Isolation SHALL be maintained
The system SHALL ensure that the `EVENT_SNAPSHOT` remains unchanged during the processing of a single navigation event, regardless of player movement or engine tick updates occurring during that event.

#### Scenario: Rapid playback during UP processing
- **WHEN** the user presses UP at `time-pos` T
- **AND** the player moves to `time-pos` T + 50ms before the navigation logic completes
- **THEN** the navigation logic SHALL still resolve using the original snapshot `time-pos` T.
