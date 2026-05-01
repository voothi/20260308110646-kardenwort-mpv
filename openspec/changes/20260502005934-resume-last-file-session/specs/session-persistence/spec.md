## ADDED Requirements

### Requirement: Save last played media path
The system SHALL automatically record the absolute path of the currently playing media file whenever a file is successfully loaded.

#### Scenario: File load event
- **WHEN** a media file is loaded and the `file-loaded` event triggers
- **THEN** the absolute path of the file is saved to the session state file

### Requirement: Save session on application shutdown
The system SHALL ensure the last played media path is recorded during application shutdown to capture the final session state.

#### Scenario: Normal shutdown
- **WHEN** the user quits MPV
- **THEN** the current media path is persisted to the session state file

### Requirement: Auto-resume on empty startup
The system SHALL automatically load the last recorded media path if MPV is launched without any file arguments and the playlist is empty.

#### Scenario: Launching MPV without arguments
- **WHEN** MPV starts and no path is provided in the command line
- **THEN** the system reads the session state file and loads the recorded media path
