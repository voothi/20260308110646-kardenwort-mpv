# config-documentation Specification

## Purpose
TBD - created by archiving change 20260310025029-release-v1-2-8. Update Purpose after archive.
## Requirements
### Requirement: Categorized Configuration Structure
The `input.conf` file SHALL be organized into logical functional groups to improve readability.

#### Scenario: Auditing input configuration
- **WHEN** the user opens `input.conf`
- **THEN** they SHALL find clearly delineated sections for Navigation, Language Layouts, and Feature Toggles.

### Requirement: Inline Behavioral Instructions
Every keybinding in the configuration SHALL include a descriptive comment explaining its purpose and any specialized behavior.

#### Scenario: Discovering feature nuances
- **WHEN** the user inspects the `LEFT` arrow binding in `input.conf`
- **THEN** they SHALL find a comment explaining that it is fixed to 2 seconds for precise phrase navigation.

### Requirement: Drum Scrolloff Parameter Documentation
User-facing configuration documentation SHALL define a dedicated Drum Mode mini viewport margin option.

#### Scenario: Documenting the DM mini option
- **WHEN** a user reads configuration docs for Drum Mode and Drum Window
- **THEN** docs SHALL list `kardenwort-drum_scrolloff`
- **AND** docs SHALL state it applies to DM mini viewport behavior (`DRUM=ON`, `DRUM_WINDOW=OFF`)
- **AND** docs SHALL state `0` means no reserved top/bottom margin lines.

