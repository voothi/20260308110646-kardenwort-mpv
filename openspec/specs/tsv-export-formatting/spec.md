# TSV Export Formatting

## Purpose
Formalize the requirements for literal, space-preserving term reconstruction in Anki exports to ensure predictable and high-quality mining data.
## Requirements
### Requirement: Literal TSV Term Reconstruction
The Anki export system SHALL reconstruct the phrase field using literal token concatenation from the subtitle stream, preserving the original whitespace and punctuation **only for tokens explicitly contained within the user's selection range.**
- **Removal**: The requirement to append "Last-line trailing tokens" (lookahead) is REMOVED.

#### Scenario: Strictly literal selection
- **WHEN** the subtitle contains "word1  word2."
- **AND** the user selects "word1" and "word2" but NOT the period
- **THEN** the `source_word` field SHALL contain exactly "word1  word2" (no period).

### Requirement: Manual Gap Ellipsis Injection
The system SHALL inject a hardcoded, space-padded ellipsis string when a logical gap is detected between non-contiguous selected words.
- **Marker**: ` ... ` (literal string: space, dot, dot, dot, space).
- **Placement**: This marker MUST be inserted between the concatenated tokens of the preceding and succeeding words.

#### Scenario: Ellipsis in non-contiguous selection
- **WHEN** the user selects "word1" and "word4" with a gap between them
- **THEN** the `source_word` field SHALL be "word1 ... word4".

