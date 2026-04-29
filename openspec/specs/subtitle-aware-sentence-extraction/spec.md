# subtitle-aware-sentence-extraction Specification

## Purpose
Ensure that sentence boundaries for Anki context extraction are derived from subtitle line edges rather than punctuation, preventing false splits on abbreviations.

## Requirements

### Requirement: Subtitle-Boundary Sentence Scoping
The context extraction system SHALL derive sentence boundaries from subtitle line edges, not from period characters found within the joined context string.

#### Scenario: Single abbreviation within a subtitle line
- **WHEN** `extract_anki_context` is called with a context block containing `"Es liegt ca. 97 km von Plattling"`
- **THEN** the system SHALL NOT split the sentence at the `"ca."` period
- **AND** the returned sentence SHALL include the full text up to the nearest subtitle line boundary (NUL sentinel), not the nearest period

#### Scenario: Abbreviation at the end of a subtitle line
- **WHEN** a subtitle ends with an abbreviation (e.g. `"Es liegt ca."`) and the next subtitle continues the phrase (e.g. `"97 km von Plattling"`)
- **THEN** the system SHALL treat the full text of the subtitle containing the selection as the primary sentence
- **AND** SHALL NOT attempt to join with the previous subtitle to find a sentence start

#### Scenario: Genuine sentence end at subtitle boundary
- **WHEN** subtitle N ends with `"Das war das Ende."` and subtitle N+1 begins with `"Ein neuer Satz"`
- **THEN** the system SHALL scope the sentence to subtitle N text only
- **AND** SHALL NOT include subtitle N+1 text in the primary sentence

### Requirement: Sentinel-Delimited Context Block
The context string assembled for `extract_anki_context` SHALL use a NUL character (`\0`) as the delimiter between individual subtitle texts, instead of a space character.

#### Scenario: Context block construction
- **WHEN** neighboring subtitle entries are joined into the `context_line` string for Anki export
- **THEN** each subtitle text SHALL be separated by a single `\0` character
- **AND** no `\0` characters SHALL appear in the final returned sentence string

### Requirement: NUL Sanitization in Subtitle Loader
The subtitle parser SHALL strip any NUL bytes from subtitle text before storing, to prevent sentinel collisions.

#### Scenario: Subtitle text with embedded NUL
- **WHEN** a subtitle file contains a NUL byte in its text content
- **THEN** the loader SHALL remove that byte before storing the text in the subtitle table
- **AND** the rest of the subtitle text SHALL be preserved intact

### Requirement: Abbreviation-Aware Sentence Boundary Detection
The word-level `is_sentence_boundary` check in `dw_anki_export_selection` SHALL NOT declare a boundary for a word that matches a known abbreviation pattern, even if that word ends with a period.

#### Scenario: Word before selection is an abbreviation
- **WHEN** the word immediately preceding the user's selection ends with `"."` (e.g. `"ca."`, `"z.B."`, `"bzw."`)
- **AND** that word matches a short lowercase-letter+period or single-uppercase-letter+period pattern
- **THEN** `is_sentence_boundary` SHALL remain `false`

#### Scenario: Word before selection is a genuine sentence end
- **WHEN** the word immediately preceding the user's selection ends with `"."` and does NOT match the abbreviation pattern (e.g. `"Ende."`, `"Abend."`)
- **THEN** `is_sentence_boundary` SHALL be set to `true`

### Requirement: Literal Context Extraction
The `SentenceSource` (context) field in exported Anki cards SHALL preserve the exact punctuation and spacing of the source subtitle by extracting substrings directly from the original text, rather than re-tokenizing and joining word lists.

#### Scenario: Complex punctuation in context
- **WHEN** a subtitle contains `Paketsortierung. [UMGEBUNG]`
- **THEN** the context extraction SHALL return the substring exactly as it appears in the source, including the space between the period and the bracket.
