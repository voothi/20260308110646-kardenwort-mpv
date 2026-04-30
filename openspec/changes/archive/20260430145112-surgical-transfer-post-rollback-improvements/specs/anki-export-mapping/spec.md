## ADDED Requirements

### Requirement: Unified String Preparation Engine
The system SHALL use a single, unified `prepare_export_text` service for ALL clipboard and Anki export pathways. This service MUST handle token concatenation, metadata cleaning, and punctuation restoration consistently to ensure architectural parity.

#### Scenario: Copying text from Drum Window
- **GIVEN** a word "test" is selected in the Drum Window
- **WHEN** the copy command is triggered (Ctrl+C)
- **THEN** `prepare_export_text` SHALL be called with the selection data to generate the clipboard string.

#### Scenario: Exporting via MMB in Yellow selection
- **GIVEN** a multi-word Yellow selection "Nummer 59"
- **WHEN** the user presses MMB to export
- **THEN** `prepare_export_text` SHALL be called to produce the `WordSource` field for the TSV record.

### Requirement: Unified High-Fidelity Export Joining
All export paths (Clipboard and TSV) SHALL use the original subtitle spacing and punctuation by concatenating tokens directly from the source text, prioritizing verbatim fidelity over typographic "normalization".
- OSD rendering logic remains governed by typographic rules (`compose_term_smart`).
- Export logic SHALL use `build_word_list_internal(text, true)` and `table.concat` for verbatim reconstruction.

#### Scenario: Exporting text with non-standard spacing
- **GIVEN** a subtitle line "Word1 , Word2" (with a space before the comma)
- **WHEN** the user selects this range and copies it
- **THEN** the resulting string SHALL be "Word1 , Word2" (verbatim)
- **AND NOT** "Word1, Word2" (normalized)

### Requirement: Selection Punctuation Preservation
Export logic SHALL NOT automatically strip leading or trailing punctuation symbols if they were explicitly included in the user's selection range. This uses strict `>=` and `<=` comparisons against `logical_idx` values (which are fractional for punctuation/spaces).

#### Scenario: Explicitly selecting a bracketed word
- **GIVEN** a subtitle "[Musik]"
- **WHEN** the user highlights the entire line including the brackets
- **THEN** the exported term SHALL be "[Musik]"
- **AND NOT** "Musik"

#### Scenario: Single word inside brackets
- **GIVEN** a subtitle "[Musik]"
- **WHEN** the user clicks on "Musik" only (word-level selection, not extending to brackets)
- **THEN** the exported term SHALL be "Musik" (without brackets)

### Requirement: Adjacent Member Fidelity
When exporting adjacent selection members on the same subtitle line in non-contiguous (Pink) mode, the system SHALL pull the actual intermediate tokens (hyphens, slashes, etc.) from the source text instead of injecting a default space separator.

#### Scenario: Exporting hyphenated term via Pink selection
- **GIVEN** tokens `["Marken", "-", "Discount"]`
- **AND** "Marken" and "Discount" are added to the Pink set
- **WHEN** the export is triggered
- **THEN** the system SHALL detect the intermediate "-" and join them as "Marken-Discount".

### Requirement: Unified Sentence Restoration Parity
The detection and restoration of terminal punctuation (`!`, `?`, `.`) for sentence fragments SHALL be identical across both Yellow and Pink selection modes, centralized within the `prepare_export_text` engine.

#### Scenario: Restoring exclamation mark in Pink mode
- **GIVEN** a subtitle line "Achtung!"
- **AND** "Achtung" is selected in Pink mode
- **WHEN** the export is triggered with `restore_sentence=true`
- **THEN** the resulting string SHALL be "Achtung!".

#### Scenario: Restoring period in Yellow mode
- **GIVEN** a subtitle line "Das ist gut."
- **AND** "Das ist gut" is selected in Yellow mode (not extending to the period)
- **WHEN** the export is triggered
- **THEN** the resulting string SHALL be "Das ist gut." (period restored as sentence boundary).
