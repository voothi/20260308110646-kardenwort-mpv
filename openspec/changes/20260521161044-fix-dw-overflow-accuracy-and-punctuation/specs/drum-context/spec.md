## ADDED Requirements

### Requirement: Drum Mode Punctuation Selection
The system SHALL support interactive click targeting, highlight coloring, and Anki exporting of sentence-ending punctuation (such as `.`, `?`, `!`) in Drum Mode (DM), matching the selection capabilities available in Drum Window (DW) mode.

#### Scenario: Clicking Punctuation in Drum Mode
- **WHEN** the user clicks on a punctuation token at the end of a subtitle in Drum Mode (DM)
- **THEN** the system SHALL accurately target and select the punctuation token using its fractional logical index
- **AND** the token SHALL turn yellow/pink and be eligible for export operations.
