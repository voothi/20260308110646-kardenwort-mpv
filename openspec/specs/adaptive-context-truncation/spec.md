# adaptive-context-truncation Specification

## Purpose
Define how `extract_anki_context` computes sentence scope and truncation so exported context remains complete and correctly aligned.

## Requirements

### Requirement: Sentence Scoping via Punctuation Terminators
The sentence extraction phase of `extract_anki_context` SHALL locate the sentence containing the selection by scanning backward from `start_pos` and forward from `end_pos` for the nearest real sentence terminator (any character in `Options.anki_sentence_terminators`, default `".!?"`), where real means not classified as an abbreviation by the shared `is_abbreviation` helper.

#### Scenario: Sentence scoping with terminators on both sides
- **WHEN** `extract_anki_context` receives a context string containing `"...raus.\0Es kommt zu kräftigen Niederschlägen,\0die verbreitet als Schnee liegen\0bleiben. Autofahrer..."` and the selection is `"verbreitet"`
- **THEN** the backward scan SHALL stop at `"raus."`
- **AND** the forward scan SHALL stop at `"bleiben."` including the period
- **AND** the primary sentence SHALL be `"Es kommt zu kräftigen Niederschlägen, die verbreitet als Schnee liegen bleiben."`

#### Scenario: Backward scan skips abbreviations
- **WHEN** the context string contains `"Es liegt ca. 97 km von Plattling"` and the selection anchors to `"97"`
- **THEN** the scan SHALL treat `"ca."` as an abbreviation and skip it as a terminator.

#### Scenario: No terminator found in either direction
- **WHEN** no real terminator is found on both sides of the selection
- **THEN** the entire joined context block SHALL be used as the primary sentence.

### Requirement: Adaptive Word-Count Truncation
The context extraction system SHALL dynamically adjust the word-count truncation window based on the length of the selected term.

#### Scenario: Exporting a long term
- **WHEN** the selected term length (in words) plus a standard buffer exceeds the default `anki_context_max_words`
- **THEN** the system increases the effective truncation limit for that specific export to preserve surrounding context.

### Requirement: Increased Default Context Buffer
The system SHALL default to a higher word-count limit to accommodate complex sentence structures.

#### Scenario: Default export behavior
- **WHEN** an export is triggered without custom overrides
- **THEN** the system applies a default limit of 40 words.

### Requirement: Non-Contiguous Term Context Anchor (Sequential Forward Search)
When the composed term cannot be found verbatim in the context block, the system SHALL find term words in natural order using forward sequential search.

#### Scenario: Non-contiguous term spanning sentence boundaries
- **WHEN** `extract_anki_context` receives a non-contiguous multi-word term
- **THEN** it SHALL anchor at the closest first-word match and continue strictly forward for subsequent words.

### Requirement: Precision Offset Mapping
The system SHALL map character-relative spans to word indices while accounting for leading character stripping during sentence cleaning.

#### Scenario: Mapping selection to word indices
- **WHEN** a sentence is trimmed before index mapping
- **THEN** the system SHALL compute offsets from the true cleaned-string origin.

### Requirement: Adaptive Span Padding for Wide Selections
When the highlighted span is wider than the allowed word limit, the system SHALL fallback to a padded tight-crop span.

#### Scenario: Exporting a wide selection
- **WHEN** the detected span is greater than or equal to `anki_context_max_words`
- **THEN** the system SHALL return span words plus fixed side padding and clamp to sentence boundaries.
