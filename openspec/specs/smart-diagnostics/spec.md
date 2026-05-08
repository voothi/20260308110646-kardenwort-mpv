# smart-diagnostics Specification

## Purpose
TBD - created by archiving change 20260502082941-smart-logging-and-diagnostics. Update Purpose after archive.
## Requirements
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

### Requirement: Early Startup Safety
The diagnostic system SHALL remain functional even if script options or other global state are not yet fully initialized.

#### Scenario: Logging during early initialization
- **WHEN** `Diagnostic.info` is called before the `Options` table is populated
- **THEN** the system SHALL output the message to the console using a default verbosity level without throwing a Lua error.

### Requirement: Lifecycle Noise Reduction
The system SHALL ensure that routine lifecycle events that do not require user intervention are logged at a non-intrusive level.

#### Scenario: Opening and closing the Drum Window during startup
- **WHEN** the script opens or closes the Drum Window as part of an automated state sync
- **THEN** the system SHALL log these events at the `Debug` level, ensuring they do not appear in the default `Info` view.

### Requirement: Layout-Agnostic Diagnostic Access
The system SHALL ensure that diagnostic tools remain accessible regardless of the user's keyboard layout.

- **THEN** the system SHALL trigger the `console/enable` command, mirroring the behavior of the English backtick (`) key.

### Requirement: System - SRT Hardening, Logging, and Session Resume
Core system utilities must be robust and efficient as per archives 20260505004553, 20260502082941, and 20260502005934.

#### Scenario: Smart Logging
- **WHEN** the system is running normally.
- **THEN** it should suppress redundant "spam" messages while maintaining diagnostic capability.

