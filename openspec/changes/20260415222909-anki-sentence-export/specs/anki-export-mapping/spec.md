## MODIFIED Requirements

### Requirement: Ordered Unified Field Mapping
The system SHALL support unified field mapping blocks (e.g., `[fields_mapping.word]`) where each line defines both the field name (key) and its data source (value) in a single assignment. The order of these assignments SHALL determine the TSV column sequence.

#### Scenario: Defining a unified field list
- **WHEN** `anki_mapping.ini` contains:
  ```ini
  [fields_mapping.word]
  Word=source_word
  Time=time
  ```
- **THEN** the system SHALL recognize a 2-column export structure where column 1 is the word and column 2 is the timestamp.

### Requirement: UI Highlight Persistence for Unmapped Terms
The system SHALL assure continued visual highlighting for items where the user has explicitly chosen not to map the base `source_word` string.

#### Scenario: User omits WordSource in sentence profile
- **WHEN** a user defines `[fields_mapping.sentence]` and maps `SentenceSource=source_sentence` but completely excludes any assignment to `source_word`
- **AND** the system reads the corresponding TSV row where the term column is thus evaluated as effectively empty
- **THEN** the `load_anki_tsv` parser SHALL fallback to setting the missing term exactly equal to the retrieved `SentenceSource` context string, ensuring the entire sentence dynamically stands out in color on-screen without requiring TSV data-smuggling.
