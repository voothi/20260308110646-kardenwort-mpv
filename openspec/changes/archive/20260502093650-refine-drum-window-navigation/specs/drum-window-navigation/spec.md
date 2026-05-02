## ADDED Requirements

### Requirement: Targeted Vertical Navigation
The Drum Window SHALL implement word-aware vertical navigation that prioritizes valid word tokens over punctuation and whitespace during line transitions.

#### Scenario: Jumping over symbolic lines
- **WHEN** the user is on a line with words and presses DOWN
- **AND** the next line contains only punctuation (e.g., "...")
- **THEN** the system SHALL jump to the first line below the current one that contains at least one token where `is_word` is true.

#### Scenario: Word-only vertical targeting
- **WHEN** the user navigates UP or DOWN
- **THEN** the yellow navigation pointer SHALL exclusively snap to tokens where `is_word` is true.
- **AND** if the target line contains multiple words, the one closest to the current horizontal X-center SHALL be selected.

### Requirement: Precision Horizontal Navigation
The Drum Window SHALL maintain character-level precision for horizontal navigation and mouse interaction to support surgical selection of all logical tokens (including punctuation and symbols).

#### Scenario: Selecting punctuation via keyboard
- **WHEN** the user is on a word and presses RIGHT
- **AND** the next token is a punctuation marker (e.g., a bracket "[")
- **THEN** the yellow pointer SHALL land on and highlight the punctuation token.

#### Scenario: Selecting punctuation via mouse
- **WHEN** the user clicks on a punctuation token in the Drum Window
- **THEN** the yellow pointer SHALL land on and highlight that specific punctuation token.
