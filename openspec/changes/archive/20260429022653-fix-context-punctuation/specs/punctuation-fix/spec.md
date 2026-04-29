# punctuation-fix Specification

## Requirements

### Requirement: Punctuation Preservation in Context
The `SentenceSource` (context) field in exported Anki cards SHALL preserve all original punctuation and spacing of the source subtitle, even when the sentence is truncated to fit word-count limits.

### Requirement: Correct Spacing for Metadata Tags
The export system SHALL NOT suppress spaces between words and bracketed metadata tags (e.g., `[UMGEBUNG]`). Spaces SHALL only be suppressed for single-character punctuation marks that traditionally attach to words (e.g., `.`, `,`, `!`, `?`, `)`, `]`).

## Scenarios

### Scenario: Truncated Context with Period
- **GIVEN** a subtitle line: `Paketsortierung. [UMGEBUNG] Geis Gruppe`
- **WHEN** the context is truncated to include `Paketsortierung` and `[UMGEBUNG]`
- **THEN** the resulting string SHALL be `Paketsortierung. [UMGEBUNG]` (preserving the period and the space).

### Scenario: Multi-word selection with brackets
- **GIVEN** a selection: `Paketsortierung` and `[UMGEBUNG]`
- **WHEN** the term is composed for the `source_word` field
- **THEN** the result SHALL be `Paketsortierung [UMGEBUNG]` (with a space).
