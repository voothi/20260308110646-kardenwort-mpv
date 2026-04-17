## ADDED Requirements

### Requirement: Metadata-Tolerant Context Matching
The highlight engine SHALL ignore or skip metadata tags (e.g., `[musik]`) when checking adjacent neighbors during strict context verification if those tags have been stripped from the stored context field.

#### Scenario: Highlighting a word next to a metadata tag
- **GIVEN** `anki_strip_metadata` is set to `yes`
- **AND** the word `Netto` was saved from `[UMGEBUNG] Netto`
- **AND** the stored context in Anki is only `Netto` (metadata stripped)
- **WHEN** the user plays the subtitle `[UMGEBUNG] Netto`
- **THEN** the word `Netto` SHALL remain highlighted despite `[UMGEBUNG]` being missing from the stored context.
