## MODIFIED Requirements

### Requirement: Literal TSV Term Reconstruction
The Anki export system SHALL reconstruct the phrase field using literal token concatenation from the subtitle stream, preserving the original whitespace and punctuation **only for tokens explicitly contained within the user's selection range.**
- **Removal**: The requirement to append "Last-line trailing tokens" (lookahead) is REMOVED.

#### Scenario: Strictly literal selection
- **WHEN** the subtitle contains "word1  word2."
- **AND** the user selects "word1" and "word2" but NOT the period
- **THEN** the `source_word` field SHALL contain exactly "word1  word2" (no period).
