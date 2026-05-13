# vscode-text-navigation-tests Specification

## Purpose
TBD - created by archiving change 20260513102658-vscode-text-navigation-tests. Update Purpose after archive.
## Requirements
### Requirement: Word-Level Navigation
The system SHALL support incremental token-level movement using Arrow keys in Drum Window and Drum Mode text navigation paths.

#### Scenario: Navigate to next token
- **GIVEN** the cursor is positioned on a valid logical token
- **WHEN** the user triggers RIGHT token movement
- **THEN** the cursor SHALL move to the next logical token.

#### Scenario: Navigate to previous token
- **GIVEN** the cursor is positioned on a valid logical token
- **WHEN** the user triggers LEFT token movement
- **THEN** the cursor SHALL move to the previous logical token.

### Requirement: Line Boundary Transition
The system SHALL transition across subtitle boundaries when token navigation moves beyond start/end of line.

#### Scenario: Right movement at end of line
- **GIVEN** the cursor is on the last logical token of a subtitle line
- **WHEN** RIGHT token movement is executed
- **THEN** the cursor SHALL move to the first logical token of the next subtitle line.

#### Scenario: Left movement at start of line
- **GIVEN** the cursor is on the first logical token of a subtitle line
- **WHEN** LEFT token movement is executed
- **THEN** the cursor SHALL move to the last logical token of the previous subtitle line.

### Requirement: Shift Selection Extension
The system SHALL preserve and extend anchor-based selection when Shift-modified movement is used.

#### Scenario: Shift movement initializes anchor
- **GIVEN** there is no active anchor
- **WHEN** the user performs Shift-modified token movement
- **THEN** the system SHALL set anchor position at the original cursor location before movement.

#### Scenario: Non-shift movement collapses anchor
- **GIVEN** an anchor exists from prior Shift-modified navigation
- **WHEN** the user performs non-Shift navigation
- **THEN** the system SHALL collapse the anchor state.

### Requirement: Ctrl Jump Navigation
The system SHALL support configurable multi-token jumps for Ctrl-modified horizontal navigation.

#### Scenario: Ctrl jump uses configured jump size
- **GIVEN** `dw_jump_words` is configured
- **WHEN** Ctrl-modified RIGHT or LEFT movement is executed
- **THEN** the cursor SHALL move by the configured logical token jump distance.

#### Scenario: Ctrl+Shift jump extends selection
- **GIVEN** Shift is held together with Ctrl jump movement
- **WHEN** jump movement is executed
- **THEN** the system SHALL keep anchor state and extend selection range across jumped tokens.

### Requirement: Vertical Sticky-X Navigation
The system SHALL preserve horizontal intent during UP/DOWN movement across subtitles and wrapped visual lines.

#### Scenario: Vertical movement preserves sticky X intent
- **GIVEN** the cursor has an established horizontal position reference
- **WHEN** UP or DOWN movement crosses to another line
- **THEN** the destination token SHALL be chosen by nearest horizontal alignment to the sticky X reference.

#### Scenario: Multi-line subtitle vertical movement
- **GIVEN** the current subtitle spans multiple visual lines
- **WHEN** vertical movement is executed
- **THEN** movement SHALL navigate within subtitle visual lines before transitioning to another subtitle.

