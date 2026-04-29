## ADDED Requirements

### Requirement: Unified Paired Export Cleaning
The paired selection export path (Pink selection) SHALL apply the same metadata and ASS tag cleaning logic as the standard selection path (Yellow selection) for the `source_word` field.

#### Scenario: Stripping metadata from paired highlights
- **GIVEN** a paired selection containing the word `Test` and a metadata tag `[UMGEBUNG]` as an interstitial.
- **WHEN** the highlight is exported to Anki with `anki_strip_metadata=true`.
- **THEN** the resulting term SHALL NOT contain the `[UMGEBUNG]` tag (it should be cleaned to `Test`).

### Requirement: Literal Punctuation Restoration for Paired Highlights
The export system SHALL restore the actual terminal punctuation (e.g., `!`, `?`, `...`) for paired highlights if the selection ends at a sentence boundary, rather than defaulting to a period.

#### Scenario: Restoring an exclamation mark
- **GIVEN** a subtitle line: `Das ist ein Test!`
- **WHEN** the word `Test` is exported as part of a paired highlight starting at a sentence boundary.
- **THEN** the resulting term SHALL be `... Test!`.
