## ADDED Requirements

### Requirement: Literal TSV Term Reconstruction
The Anki export system SHALL reconstruct the `source_word` field using literal token concatenation from the subtitle stream, preserving the original whitespace and punctuation.
- **Source**: Tokens MUST be retrieved using `build_word_list_internal(text, true)` to ensure spaces are treated as distinct tokens.
- **Normalization**: No regex-based space collapsing (e.g., `gsub("%s+", " ")`) SHALL be applied to the final reconstructed string.

#### Scenario: Preserving literal spacing
- **WHEN** the subtitle contains "word1  word2" (two spaces)
- **AND** both words are selected for export
- **THEN** the `source_word` field SHALL contain exactly "word1  word2".

### Requirement: Manual Gap Ellipsis Injection
The system SHALL inject a hardcoded, space-padded ellipsis string when a logical gap is detected between non-contiguous selected words.
- **Marker**: ` ... ` (literal string: space, dot, dot, dot, space).
- **Placement**: This marker MUST be inserted between the concatenated tokens of the preceding and succeeding words.

#### Scenario: Ellipsis in non-contiguous selection
- **WHEN** the user selects "word1" and "word4" with a gap between them
- **THEN** the `source_word` field SHALL be "word1 ... word4".
