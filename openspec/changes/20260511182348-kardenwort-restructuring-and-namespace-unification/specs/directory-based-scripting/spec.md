## ADDED Requirements

### Requirement: Directory-Based Namespace
The system SHALL organize core script logic within a dedicated subdirectory inside the `scripts/` folder to ensure namespace isolation.

#### Scenario: Script loading via main.lua
- **WHEN** mpv loads the `scripts/kardenwort/` directory
- **THEN** it SHALL execute `main.lua` as the entry point
- **AND** the script name in the property list SHALL be `kardenwort`.

### Requirement: Encapsulated Modules
The system SHALL place all auxiliary logic (utilities, secondary features) within the same namespace directory.

#### Scenario: Requiring internal modules
- **WHEN** `main.lua` cakardenwort `require 'utils'` or `require 'resume'`
- **THEN** it SHALL load the corresponding files from `scripts/kardenwort/`
- **AND** it SHALL NOT conflict with scripts of the same name in the root `scripts/` directory.
