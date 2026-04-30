## MODIFIED Requirements

### Requirement: Literal TSV Term Reconstruction
The Anki export system SHALL reconstruct the phrase field using literal token concatenation from the subtitle stream, preserving the original whitespace and punctuation **including closing punctuation tokens that are directly bonded (no intervening word token) to the last selected word on the final subtitle line of a multi-line range selection.**
- **Source**: Tokens MUST be retrieved using `build_word_list_internal(text, true)`.
- **Normalization**: No regex-based space collapsing SHALL be applied to the final reconstructed string.
- **Last-line trailing tokens**: On the final subtitle line only, fractional-index non-word tokens occurring after `p2_w` SHALL be appended until the next `is_word == true` token is reached.

#### Scenario: Preserving literal spacing with trailing punctuation
- **WHEN** the subtitle contains "word1  word2."
- **AND** both words are selected for export
- **THEN** the `source_word` field SHALL contain exactly "word1  word2.".
