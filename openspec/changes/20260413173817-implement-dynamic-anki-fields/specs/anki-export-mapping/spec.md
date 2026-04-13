## ADDED Requirements

### Requirement: Ordered Field Mapping from mpv.conf
The system SHALL support an ordered list of Anki field names defined in `mpv.conf` using a comma-separated string that supports native line-continuation (`\`).

#### Scenario: Defining a vertical field list
- **WHEN** `mpv.conf` contains `lls-anki_fields=Field1,\,Field2,\,Field3`
- **THEN** the system SHALL recognize a 3-column export structure where column 2 is empty.

### Requirement: Dynamic Field Resolution (Word vs Sentence Mode)
The system SHALL resolve each field in the ordered list to a data source based on whether a single word or a phrase/line is being exported.

#### Scenario: Exporting a single word
- **GIVEN** `anki_mapping_word` maps `WordField` to `source_word`
- **WHEN** user exports a single word "Example"
- **THEN** the column `WordField` SHALL contains "Example" in the TSV.

### Requirement: Automatic Deck and Language Extraction
The system SHALL extract the deck name and source language code from the primary subtitle filename.

#### Scenario: Extracting from standard filename
- **GIVEN** the subtitle file is named `2026.test.de.srt`
- **WHEN** the export logic initializes
- **THEN** the `deck_name` source SHALL be `2026.test.de`
- **AND** the `lang_code` source SHALL be `de`.

### Requirement: Automatic Anki Import Header
The system SHALL automatically prepend the TSV file with a `#deck column:N` header if the file is new or empty.

#### Scenario: Generating header for new file
- **GIVEN** `DeckField` is the 3rd field in `anki_fields`
- **AND** `DeckField` is mapped to `deck_name`
- **WHEN** the first row is written to a new TSV
- **THEN** the absolute first line of the file SHALL be `#deck column:3`.

### Requirement: Language-Aware TTS Flags
The system SHALL support `tts_source_[lang]` data sources that resolve to "1" if the extracted language code matches `[lang]`.

#### Scenario: Activating German TTS flag
- **GIVEN** the subtitle language postfix is `.de`
- **AND** a field is mapped to `tts_source_de`
- **WHEN** the row is exported
- **THEN** that field SHALL contain "1" in the TSV output.
