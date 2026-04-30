## ADDED Requirements

### Requirement: Ordered Unified Field Mapping
The system SHALL support unified field mapping blocks where each line defines both the field name (key) and its data source (value) in a single assignment. The order of these assignments SHALL determine the TSV column sequence when an explicit `[fields]` list is absent.

#### Scenario: Deterministic Column Order
- **GIVEN** `anki_mapping.ini` contains assignments for `Word`, `Context`, and `Time` in that specific order.
- **WHEN** an export is triggered.
- **THEN** the resulting TSV row SHALL contain exactly 3 columns in the order: Word, Context, Time.

### Requirement: Verbatim Context Preservation
The Anki export system SHALL NOT perform any whitespace normalization or character stripping on the `SentenceSource` (context) field, preserving the original subtitle spacing and semantic markers.

#### Scenario: Exporting Context with Multiple Spaces
- **GIVEN** a subtitle line "Word1   [Musik]   Word2".
- **WHEN** the user selects "Word1" for export.
- **THEN** the `SentenceSource` field in the TSV SHALL be "Word1   [Musik]   Word2" (verbatim).
- **AND** it SHALL NOT be collapsed to "Word1 [Musik] Word2".
- **AND** the brackets `[]` SHALL NOT be stripped.
