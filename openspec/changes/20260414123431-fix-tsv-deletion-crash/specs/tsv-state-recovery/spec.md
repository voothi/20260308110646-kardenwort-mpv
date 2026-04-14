## ADDED Requirements

### Requirement: Active TSV File Existence Verification
The system SHALL verify the existence and readability of the currently active TSV record file before attempting to parse it or before opening UI elements that depend on its data.

#### Scenario: Active File Missing on Startup Opening
- **WHEN** the user attempts to open the Drum Window
- **AND** the active TSV record file has been deleted or cannot be found
- **THEN** the system SHALL recreate an empty TSV file with the correct headers in its place
- **AND** open the Drum Window seamlessly with an empty record state without crashing or freezing.

### Requirement: Resilient TSV Parsing
The system SHALL gracefully handle standard parsing routines over empty or newly initialized TSV files without throwing exceptions.

#### Scenario: Parsing an Empty File
- **WHEN** the system begins iterating through the TSV file rows
- **AND** the file contains only headers or is completely empty
- **THEN** the parsing routine SHALL return an empty result set
- **AND** NOT produce Lua runtime errors regarding string matching or nil values.

#### Scenario: Unrecoverable File IO Error
- **WHEN** the system fails to read or recreate the TSV file due to IO errors (e.g., file lock, permissions)
- **THEN** the system SHALL abort the dependent UI operations gracefully
- **AND** display an OSD error indicating the failure.
