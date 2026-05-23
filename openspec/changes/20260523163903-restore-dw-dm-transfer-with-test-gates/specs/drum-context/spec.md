## ADDED Requirements

### Requirement: Drum Mode Punctuation Selection Parity
The system SHALL support interactive click targeting, highlight coloring, and export eligibility of sentence-ending punctuation (such as `.`, `?`, `!`) in Drum Mode (DM), matching Drum Window token interaction behavior.

#### Scenario: Clicking Punctuation in Drum Mode
- **WHEN** the user clicks on a punctuation token at the end of a subtitle in Drum Mode
- **THEN** the system SHALL accurately target and select the punctuation token using its logical index mapping
- **AND** the token SHALL receive the same selection/highlight lifecycle as word tokens.
