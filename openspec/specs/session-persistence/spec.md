# session-persistence Specification

## Purpose
Ensures seamless continuity between media consumption sessions by automatically tracking the user's progress and restoring the playback state upon application launch. This eliminates the cognitive load of manual file navigation and ensures the user can immediately resume their immersion workflow.

## Requirements

### Requirement: Save last played media path
The system SHALL automatically record the absolute path of the currently playing media file whenever a file is successfully loaded and playback begins.

#### Scenario: File load event
- **WHEN** a media file is successfully loaded into the player
- **THEN** the absolute path of the file is persisted to the local session state file

### Requirement: Save session on application shutdown
The system SHALL verify that the last played media path is recorded during the application's shutdown sequence to ensure the most recent session state is captured.

#### Scenario: Normal shutdown
- **WHEN** the user initiates a quit command or closes the player
- **THEN** the current media path is synchronized with the session state file

### Requirement: Auto-resume on empty startup
The system SHALL automatically load the last recorded media path if MPV is launched without explicit file arguments and the internal playlist is empty.

- **WHEN** MPV starts and no media path is provided via the command line or file associations
- **THEN** the system retrieves the path from the session state file and initiates a `loadfile` command

#### Scenario: Session Resume
- **WHEN** mpv is started with the `resume-last-file` script.
- **THEN** it should automatically load the last played file and seek to the last position.
