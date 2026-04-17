## ADDED Requirements

### Requirement: Context-Strict Local Highlighting
The system SHALL support a strict contextual validation mode for localized highlights. When `anki_context_strict` is enabled, a highlight SHALL ONLY be applied to a subtitle token if at least one of its immediate neighbors in the current subtitle (within a 4-token scan radius) also exists within the recorded context sentence from the TSV database. This check SHALL be bypassed if the term is explicitly marked as exempt (e.g. labels in brackets or common units).

#### Scenario: Matching word in same sentence
- **WHEN** `anki_context_strict` is ON
- **AND** a word is encountered whose neighbors match the card's context sentence
- **THEN** the highlight SHALL be applied.

#### Scenario: Skipping word in different sentence
- **WHEN** `anki_context_strict` is ON
- **WHEN** a word matches a card whose neighbors do NOT match the card's context sentence (e.g. "die" in a different sentence)
- **THEN** the highlight SHALL NOT be applied.

### Requirement: Center-Biased Context Extraction
The context extraction engine SHALL prioritize the occurrence of the term closest to the center of the provided text buffer when multiple identical matches are present.

#### Scenario: Ambiguous Word Matching
- **GIVEN** a context buffer containing "A: die word ... B: die word"
- **AND** the target selection is at the center (Sentence B)
- **WHEN** extracting context for "die"
- **THEN** the system SHALL anchor around the "die" in Sentence B, even if another "die" exists earlier in the buffer.

### Requirement: Precise Local Matching Window
The default temporal window for localized highlights SHALL be reduced to ensure that "drift" only bridges small technical timing variances between subtitles and TSV records, rather than spanning entire unrelated sentences.

#### Scenario: Default Local Window Refinement
- **WHEN** using the default configuration
- **THEN** `anki_local_fuzzy_window` SHALL be `3.0` seconds.
