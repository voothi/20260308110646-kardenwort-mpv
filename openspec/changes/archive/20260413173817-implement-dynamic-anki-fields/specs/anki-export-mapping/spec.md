# Anki Export Mapping

## Purpose
Decouple Anki TSV export structure from the core logic using a dynamic, position-based INI configuration.

## MODIFIED Requirements

### Requirement: Ordered Field Mapping from INI
The system SHALL support an ordered list of Anki field names defined in `anki_mapping.ini` within a `[fields]` section where each line represents a subsequent TSV column.

#### Scenario: Defining a vertical field list
- **WHEN** `anki_mapping.ini` contains:
  ```ini
  [fields]
  Field1
  
  Field2
  ```
- **THEN** the system SHALL recognize a 3-column export structure where column 2 is empty.

### Requirement: Unified Field Resolution
The system SHALL resolve each field in the ordered list to a data source based on a single mapping table defined in `anki_mapping.ini`.

#### Scenario: Exporting a field
- **GIVEN** `Quotation` is mapped to `source_word`
- **WHEN** user exports "Example"
- **THEN** the column `Quotation` SHALL contain "Example" in the TSV.

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

