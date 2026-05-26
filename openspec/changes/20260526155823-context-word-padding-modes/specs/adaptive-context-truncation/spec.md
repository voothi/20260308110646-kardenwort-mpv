## MODIFIED Requirements

### Requirement: Adaptive Word-Count Truncation
The context extraction system SHALL dynamically adjust the word-count truncation window based on the length of the selected term and any explicit word padding required by sentence-based extraction.

#### Scenario: Exporting a long term
- **WHEN** the selected term length in words plus a standard buffer exceeds the default `anki_context_max_words`
- **AND** sentence-based extraction is active
- **THEN** the system SHALL increase the effective truncation limit for that specific export to ensure surrounding context is preserved

#### Scenario: Sentence extension padding raises the effective limit
- **WHEN** sentence-based extraction is active
- **AND** the selected span plus `anki_context_words_before` and `anki_context_words_after` exceeds `anki_context_max_words`
- **THEN** the system SHALL increase the effective truncation limit for that specific export so the selected span and requested padding are preserved when those words exist in the source

### Requirement: Adaptive Span Padding for Wide Selections
When the highlighted span itself is wider than the allowed word limit, the system SHALL fall back to a tight-crop representation of the span with natural padding. If explicit context word padding is active, the tight crop SHALL use at least the configured before/after word padding for the corresponding side.

#### Scenario: Exporting a wide selection
- **WHEN** the detected word span between the first and last selected words is greater than or equal to `anki_context_max_words`
- **AND** sentence-based extraction is active
- **THEN** the system SHALL return only the words within that span plus a small fixed padding on each side
- **AND** clamp this padded range to the sentence boundaries

#### Scenario: Wide selection with explicit padding
- **WHEN** the detected word span between the first and last selected words is greater than or equal to `anki_context_max_words`
- **AND** sentence-based extraction is active
- **THEN** the system SHALL return the words within that span plus at least `anki_context_words_before` words before the first selected word and `anki_context_words_after` words after the last selected word when available
- **AND** clamp this padded range to the joined context boundaries
