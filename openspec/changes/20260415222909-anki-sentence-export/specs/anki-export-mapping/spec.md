## MODIFIED Requirements

### Requirement: Ordered Field Mapping from INI
The system SHALL support an ordered list of Anki field names defined in `anki_mapping.ini`. This list SHALL be scoped under specific context groupings (e.g., `[fields.word]` or `[fields.sentence]`) to allow conditional branching based on the user's current selection sequence. If a specific context grouping is absent, the system SHALL fallback to identifying a default `[fields]` list, where each continuous line translates sequentially into an adjoining record column.

#### Scenario: Defining a vertical field list for isolated words
- **WHEN** `anki_mapping.ini` contains grouped keys underneath a `[fields.word]` declaration specifying a vertical ordered array
- **AND** the current selection evaluates purely as a vocabulary word
- **THEN** the system SHALL recognize and apply a sequential multi-column hierarchy where every corresponding exported row conforms structure derived solely from `[fields.word]`.

#### Scenario: Missing profile fallback
- **WHEN** a sequence evaluates logically as a sentence
- **BUT** `anki_mapping.ini` lacks any structured block labeled `[fields.sentence]`
- **THEN** the system SHALL recognize and fall back to the default `[fields]` format ordered array to execute the TSV write without any data loss.
