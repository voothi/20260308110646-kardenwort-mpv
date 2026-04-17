## ADDED Requirements

### Requirement: Selective Metadata Filtering for primary terms
When the system is set to strip metadata tags (e.g., `[musik]`), it SHALL NOT strip the content of the ONLY remaining tag in the exported term. Instead, it SHALL only strip the brackets themselves.

#### Scenario: Exporting a word in brackets
- **GIVEN** `anki_strip_metadata` is set to `yes`
- **WHEN** the user selects the word `[UMGEBUNG]`
- **THEN** the exported term SHALL be `UMGEBUNG`.

#### Scenario: Stripping secondary metadata
- **GIVEN** `anki_strip_metadata` is set to `yes`
- **WHEN** the user selects `[musik] Die Luftfahrt`
- **THEN** the exported term SHALL be `Die Luftfahrt`.
