## ADDED Requirements

### Requirement: Secondary Position State Persistence
The system SHALL maintain a persistent record of the user's desired secondary subtitle position (`FSM.native_sec_sub_pos`) to prevent high-frequency state polling from overwriting manual commands.

#### Scenario: Toggling secondary position
- **WHEN** the user presses the `y` key while Drum Mode is active
- **THEN** the system SHALL update `FSM.native_sec_sub_pos` and ensure the master tick loop does not revert the native mpv property.

### Requirement: Memory Array Flushing on Track Change
The system SHALL immediately clear internal subtitle data arrays when a track is disabled or the source file path changes.

#### Scenario: Disabling secondary track
- **WHEN** the user cycles SID to 0
- **THEN** the system SHALL flush the corresponding memory array to prevent "ghost" rendering in Drum Mode.

### Requirement: Context-Aware Feature Guarding
The system SHALL validate the current media and subtitle state before executing format-specific features.

#### Scenario: Blocking repositioning on ASS tracks
- **WHEN** the user attempts to toggle secondary position (`y`) on an ASS track
- **THEN** the system SHALL block the command and display a compatibility warning OSD.
