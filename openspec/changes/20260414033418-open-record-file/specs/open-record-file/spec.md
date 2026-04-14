## ADDED Requirements

### Requirement: Quick Open Record File
The system must provide a convenient way to open the current TSV record file in a configurable external editor.

#### Scenario: Open record file via hotkey
- **WHEN** The Drum Window is active and the user presses 'o' (or 'щ' on RU layout)
- **THEN** The system identifies the current TSV record file path
- **THEN** The system verifies the file existence
- **THEN** The system launches the configured `record_editor` (from `mpv.conf`) with the file path as an argument
- **THEN** The system provides status updates via the mpv console and OSD feedback for error states
- **THEN** The Drum Window overlay remains stable and active throughout the process
