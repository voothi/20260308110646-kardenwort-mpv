# Anki Export Mapping

## Purpose
Decouple Anki TSV export structure from the core logic using a dynamic, position-based INI configuration and allow contextual layout switching based on term length.
## Requirements
### Requirement: Threshold-Based Dynamic Field Mapping
The export system SHALL dynamically select between word-level and sentence-level field mapping profiles based on the total word count of the selected term.
- Profiles are defined in `anki_mapping.ini` as `[fields_mapping.word]` and `[fields_mapping.sentence]`.
- The threshold is controlled by the `sentence_word_threshold` setting (default: 3).

#### Scenario: Selecting mapping profile based on length
- **GIVEN** `sentence_word_threshold` is set to 3
- **WHEN** the user exports the term "Haus" (1 word)
- **THEN** the system SHALL apply the `[fields_mapping.word]` mapping layout.
- **WHEN** the user exports the term "Das ist gut" (3 words)
- **THEN** the system SHALL apply the `[fields_mapping.sentence]` mapping layout.

### Requirement: Ordered Unified Field Mapping
The system SHALL support unified field mapping blocks where each line defines both the field name (key) and its data source (value) in a single assignment. The order of these assignments SHALL determine the TSV column sequence.

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
The export mapping logic SHALL support multiple physical keys and layouts mapped to the same logical export action, ensuring that mining is as efficient on minimalist remote controllers as it is on a full keyboard.

#### Scenario: Unified mining list configuration
- **WHEN** the `dw_key_add` configuration contains multiple keys (e.g., `MBTN_MID r к`)
- **THEN** any of these keys SHALL trigger the export mapping logic identically.
- **AND** the system SHALL automatically determine whether to export the standard yellow selection or the persistent paired set based on the presence of pink highlights.

#### Scenario: Context-Aware Smart Mining
- **WHEN** a mining trigger is activated
- **AND** the current word belongs to a persistent paired (Pink) set
- **THEN** the system SHALL export all members of that set using elliptical joiners where necessary.
- **ELSE** the system SHALL export the contiguous yellow selection range.

### Requirement: Unified High-Fidelity Export Joining
All export paths (Clipboard and TSV) SHALL use the original subtitle spacing and punctuation by concatenating tokens directly from the source text, prioritizing verbatim fidelity over typographic "normalization". 
- This REPLACES Requirement 131 (Spacing Consistency) for export-only paths.
- The system SHALL NOT perform any whitespace normalization (e.g., collapsing multiple spaces).
- OSD rendering logic remains governed by typographic rules.

#### Scenario: Exporting text with non-standard spacing
- **GIVEN** a subtitle line "Word1   ,   Word2" (with multiple spaces around the comma)
- **WHEN** the user selects this range and copies it
- **THEN** the resulting string SHALL be "Word1   ,   Word2" (verbatim)
- **AND NOT** "Word1 , Word2" (normalized to single spaces)

### Requirement: Selection Punctuation Preservation
Export logic SHALL NOT perform any automatic filtering, stripping, or cleaning of leading/trailing symbols (including balanced brackets like `[]`, `()`, or `{}`). The system SHALL strictly export the character sequence defined by the user's manual selection range.
- **Clarification**: All "smart" bracket stripping is removed to ensure absolute verbatim fidelity.
- **Clarification**: Metadata stripping is restricted strictly to ASS tags `{...}` when `options.clean` is explicitly requested.

#### Scenario: Verbatim bracket export
- **GIVEN** a subtitle "[Musik]"
- **WHEN** the user selects the entire line including the brackets
- **THEN** the exported term SHALL be "[Musik]"
- **AND** the system SHALL NOT attempt to "clean" the brackets away.

### Requirement: Unified String Preparation Engine
The system SHALL use a single, unified `prepare_export_text` service for all clipboard and Anki export pathways. This service MUST handle token concatenation, metadata cleaning, and punctuation restoration consistently to ensure architectural parity.

#### Scenario: Copying text from Drum Window
- **GIVEN** a word "test" is selected in the Drum Window
- **WHEN** the copy command is triggered
- **THEN** `prepare_export_text` SHALL be called with the selection data to generate the clipboard string.

### Requirement: Adjacent Member Fidelity
When exporting adjacent selection members on the same subtitle line in non-contiguous (Pink) mode, the system SHALL pull the actual intermediate tokens (hyphens, slashes, etc.) from the source text instead of injecting a default space separator.

#### Scenario: Exporting hyphenated term via Pink selection
- **GIVEN** tokens `["Marken", "-", "Discount"]`
- **AND** "Marken" and "Discount" are added to the Pink set
- **WHEN** the export is triggered
- **THEN** the system SHALL detect the intermediate "-" and join them as "Marken-Discount".

