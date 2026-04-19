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

### Requirement: Elliptical Paired Selection
The export system SHALL support non-contiguous selections by injecting ellipsis markers at logical gaps.

#### Scenario: Split selection save
- **WHEN** a user selection contains words with a gap in their `logical_idx` values (e.g. 1, 4).
- **THEN** the system SHALL join them using a space-padded ellipsis (exact string: ` ... `) for the `source_word` field (e.g. "word1 ... word4").

#### Scenario: Multi-Word Fragment Save
- **WHEN** a user selects a single word, skips several, and then selects two adjacent words.
- **THEN** the system SHALL detect the gap after the first word and inject ` ... `, but join the adjacent pair with a space.
- **RESULT**: `Word1 ... Word2 Word3`

#### Scenario: Triple-Split Save
- **WHEN** a user selects three words with gaps between each.
- **THEN** the system SHALL inject ellipses at every gap.
- **RESULT**: `Word1 ... Word2 ... Word3`

### Requirement: Smart Joiner for TSV Composition
TSV export MUST use a smart joiner that preserves the visual spacing of the source text for hyphenated or slashed terms, preventing both space injection and character stripping.

#### Scenario: Exporting Marken-Discount
- **WHEN** Exporting "Marken", "-", and "Discount" together
- **THEN** The resulting term MUST be "Marken-Discount" (no spaces around the dash).

### Requirement: Anki Data Source Resolution
The system SHALL support the keyword `source_url` in `anki_mapping.ini` to resolve TSV field values from the dynamic URL discovery mechanism.

#### Scenario: Mapping to source_url
- **WHEN** an entry in `[fields_mapping.*]` is set to `source_url`
- **AND** a valid URL has been discovered in the media directory
- **THEN** that URL SHALL be populated in the corresponding TSV column during export.

### Requirement: Multi-Layout Export Triggering
The export mapping logic SHALL support multiple physical keys and layouts mapped to the same logical export action.

#### Scenario: Unified mining list configuration
- **WHEN** the `dw_key_add` configuration contains multiple keys (e.g., `MBTN_MID r к`)
- **THEN** any of these keys SHALL trigger the export mapping logic identically.

### Highlighting Example (Concrete Case)
- **Source Text**: `Entscheiden Sie beim Hören, ob die Aussagen 41 bis 45 richtig oder falsch sind.`
- **Saved Term (1+2 Split)**: `Aussagen ... richtig oder`
  - **Result**: `Aussagen` (Database Highlight / Purple), `richtig` (Database Highlight / Purple), `oder` (Database Highlight / Purple).
- **Saved Term (3-Way Split)**: `Entscheiden ... beim ... ob`
  - **Result**: `Entscheiden` (Database Highlight / Purple), `beim` (Database Highlight / Purple), `ob` (Database Highlight / Purple).


