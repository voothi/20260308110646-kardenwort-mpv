## ADDED Requirements

### Requirement: Drum Scrolloff Parameter Documentation
User-facing configuration documentation SHALL define a dedicated Drum Mode mini viewport margin option.

#### Scenario: Documenting the DM mini option
- **WHEN** a user reads configuration docs for Drum Mode and Drum Window
- **THEN** docs SHALL list `kardenwort-drum_scrolloff`
- **AND** docs SHALL state it applies to DM mini viewport behavior (`DRUM=ON`, `DRUM_WINDOW=OFF`)
- **AND** docs SHALL state `0` means no reserved top/bottom margin lines.
