# Anki Export Mapping

## Purpose
Decouple Anki TSV export structure from the core logic using a dynamic, position-based INI configuration.
## Requirements
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

### Requirement: Automatic Deck and Language Extraction
The system SHALL extract the deck name and language code from the Primary track (Source) and the language code from the Secondary track (Destination).

#### Scenario: Extracting from tracks
- **GIVEN** primary track is `test.de.srt` and secondary is `test.ru.srt`
- **WHEN** the export logic initializes
- **THEN** `pri_lang` SHALL be `de` and `sec_lang` SHALL be `ru`.

### Requirement: Track-Aware TTS Flags & Fallback
The system SHALL support `tts_source_[lang]` (matches primary track) and `tts_dest_[lang]` (matches secondary track). If no secondary track is found, `tts_dest_ru` SHALL return "1" by default.

#### Scenario: Russian destination fallback
- **GIVEN** no secondary subtitles are loaded
- **AND** a field is mapped to `tts_dest_ru`
- **WHEN** the row is exported
- **THEN** that field SHALL contains "1" in the TSV output.


### Requirement: Natural Context Extraction
The Anki export system SHALL prioritize using the original subtitle spacing for the `SentenceSource` context field.

#### Scenario: Multi-segment context building
- **WHEN** a user selects a range of subtitle segments for Anki export
- **THEN** the system SHALL construct the `context_line` by concatenating the original text of each segment with a single space separator.

#### Scenario: Metadata cleaning with natural space preservation
- **WHEN** ASS tags or metadata brackets are removed from the context
- **THEN** trailing/leading spaces from tokens SHALL NOT be doubled or introduced in a way that breaks punctuation spacing.
