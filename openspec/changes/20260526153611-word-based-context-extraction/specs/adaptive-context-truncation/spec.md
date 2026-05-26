## MODIFIED Requirements

### Requirement: Adaptive Word-Count Truncation
The context extraction system SHALL dynamically adjust the word-count truncation window based on the length of the selected term. If the system is operating in `word` context mode (`anki_context_mode="word"`), this subsequent truncation step SHALL NOT apply, as the word count has already been explicitly bounded by the extraction phase padding parameters (`anki_context_words_before` and `anki_context_words_after`).

#### Scenario: Exporting a long term
- **WHEN** the selected term length in words plus a standard buffer exceeds the default `anki_context_max_words`
- **AND** `anki_context_mode` is `"sentence"`
- **THEN** the system SHALL increase the effective truncation limit for that specific export to ensure surrounding context is preserved

#### Scenario: Word mode bypasses truncation
- **WHEN** `anki_context_mode` is `"word"`
- **THEN** the adaptive word-count truncation step SHALL be skipped entirely
