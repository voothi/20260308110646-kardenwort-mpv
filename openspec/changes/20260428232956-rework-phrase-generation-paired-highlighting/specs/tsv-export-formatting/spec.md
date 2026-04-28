## MODIFIED Requirements

### Requirement: Manual Gap Ellipsis Injection
The system SHALL inject a hardcoded, space-padded ellipsis string when a logical gap is detected between non-contiguous selected words, and MUST NOT append a trailing ellipsis after the final selected word.
- **Marker**: ` ... ` (literal string: space, dot, dot, dot, space).
- **Placement**: This marker MUST be inserted between the concatenated tokens of the preceding and succeeding words.
- **Trailing Rule**: No ellipsis SHALL be added at the end of the reconstructed phrase.

#### Scenario: Ellipsis in non-contiguous selection
- **WHEN** the user selects "word1" and "word4" with a gap between them
- **THEN** the `source_word` field SHALL be "word1 ... word4".

#### Scenario: No trailing ellipsis
- **WHEN** the user selects "word1" and "word4" with a gap between them, and the sentence continues with "word5 word6"
- **THEN** the `source_word` field SHALL remain exactly "word1 ... word4", and NO trailing ellipsis SHALL be added.
