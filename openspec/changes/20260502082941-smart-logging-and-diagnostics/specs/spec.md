## ADDED Requirements

### Requirement: Unified Logging Interface
The system SHALL provide a centralized diagnostic interface for all script-level console output, supporting multiple severity levels (Error, Warn, Info, Debug, Trace).

#### Scenario: Logging a successful TSV sync
- **WHEN** a periodic TSV sync completes successfully
- **THEN** the system SHALL log the event at the `Debug` level, ensuring it is hidden by default.

### Requirement: Log Deduplication
The system SHALL suppress duplicate log messages that occur within a single session or a specific time window to prevent console flooding.

#### Scenario: Repeated invalid keybindings
- **WHEN** multiple invalid keybindings are detected during a refresh
- **THEN** each unique invalid key SHOULD be logged as a warning exactly ONCE per session.

### Requirement: Configurable Verbosity
The system SHALL allow the user to define the minimum log level displayed in the console via the `lls-log_level` script option.

#### Scenario: Enabling verbose debugging
- **WHEN** the user sets `lls-log_level=debug` in `mpv.conf`
- **THEN** the system SHALL display all messages of level `Info` and above, plus `Debug` messages.

### Requirement: Startup Health Summary
The system SHALL perform a comprehensive configuration and dependency check during initialization and report a summary of any issues.

#### Scenario: Initialization with malformed keys
- **WHEN** the script starts and detects multiple malformed key strings in `mpv.conf`
- **THEN** it SHALL output a single structured block summarizing all detected errors before continuing execution.
