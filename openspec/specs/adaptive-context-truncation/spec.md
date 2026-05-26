# adaptive-context-truncation Specification

## Purpose
Define how `extract_anki_context` computes sentence scope and word-count truncation so exported Anki context remains complete, bounded, and correctly aligned to the selected term.
## Requirements
### Requirement: Sentence Scoping via Punctuation Terminators
The sentence extraction phase of `extract_anki_context` SHALL locate the sentence containing the selection by scanning backward from `start_pos` and forward from `end_pos` for the nearest real sentence terminator. Real terminators are characters in `Options.anki_sentence_terminators` (default `".!?"`) that are not classified as abbreviations by the shared abbreviation handling in `subtitle-aware-sentence-extraction`. The scan SHALL traverse `\0` subtitle-line sentinels as whitespace. When no real terminator is found on either side, the entire joined context block SHALL be used as the sentence.

#### Scenario: Sentence scoping with terminators on both sides
- **WHEN** `extract_anki_context` receives a context string `"...Winterstiefel raus.\0Es kommt zu kräftigen Niederschlägen,\0die verbreitet als Schnee liegen\0bleiben. Autofahrer..."` and `start_pos` / `end_pos` mark the word `"verbreitet"`
- **THEN** the backward scan SHALL stop at `"raus."` and place `sent_start` immediately after that period
- **AND** the forward scan SHALL stop at `"bleiben."` and place `sent_end` immediately after that period
- **AND** the returned primary sentence SHALL be `"Es kommt zu kräftigen Niederschlägen, die verbreitet als Schnee liegen bleiben."`

#### Scenario: Backward scan skips abbreviations
- **WHEN** the context string contains `"Es liegt ca. 97 km von Plattling"` and the selection anchors to `"97"`
- **THEN** the backward scan SHALL detect that `"ca."` is an abbreviation
- **AND** the returned sentence SHALL include `"Es liegt ca. 97 km von Plattling"`

#### Scenario: Forward scan includes the terminating punctuation
- **WHEN** the forward scan reaches `[.!?]` followed by whitespace, NUL, or end-of-string
- **AND** the preceding token is not classified as an abbreviation
- **THEN** the terminator character SHALL be included as the last character of the returned sentence

#### Scenario: No terminator found in either direction
- **WHEN** the joined context block contains no `.`, `!`, or `?` whose preceding token is not an abbreviation
- **THEN** the entire joined context block SHALL be returned as the primary sentence with `\0` replaced by spaces
- **AND** word-count truncation in the subsequent step SHALL still apply

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

### Requirement: Increased Default Context Buffer
The system SHALL default to a higher word-count limit to accommodate complex sentence structures.

#### Scenario: Default export behavior
- **WHEN** an export is triggered without custom overrides
- **THEN** the system SHALL apply a default limit of 40 words

### Requirement: Non-Contiguous Term Context Anchor (Sequential Forward Search)
When the composed term cannot be found verbatim in the context block, the context extraction system SHALL find occurrences of each word in the term in their natural document order.

#### Scenario: Non-contiguous term spanning sentence boundaries
- **WHEN** `extract_anki_context` is called with a term containing multiple segments such as `"she's ... six ... four"`
- **THEN** the system SHALL anchor the search using the first word closest to the pivot center
- **AND** search for all subsequent words strictly forward from the previous match's end position
- **AND** use the absolute character offsets of the first and last matches to map the span into word indices

### Requirement: Precision Offset Mapping
The system SHALL ensure that character-relative spans are mapped to word indices by accounting for leading character stripping during sentence cleaning.

#### Scenario: Mapping selection to word indices
- **WHEN** a sentence is stripped of leading whitespace or punctuation, such as `"  Wait, how..."` becoming `"Wait, how..."`
- **THEN** the system SHALL calculate the actual start offset of the cleaned string within the source line
- **AND** derive word indices using relative character offsets based on this true origin

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

