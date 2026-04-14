## ADDED Requirements

### Requirement: Quick Open Record File
The system must provide a convenient way to open the current TSV record file in the operating system's default editor without leaving the application.

#### Scenario: Open record file via hotkey
- **WHEN** The Drum Window is active and the user presses 'o' (or 'щ' on RU layout)
- **THEN** The system identifies the current TSV record file path
- **THEN** The system verifies the file existence
- **THEN** The system opens the file using the OS default application
- **THEN** The system provides visual feedback via OSD (e.g., "Opening record file...")
