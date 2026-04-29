## UPDATED Requirements

### Requirement: Unified High-Fidelity Export Joining
All export paths (Clipboard and TSV) SHALL use the original subtitle spacing and punctuation by concatenating tokens directly from the source text, prioritizing verbatim fidelity over typographic "normalization". 
- This REPLACES Requirement 131 (Spacing Consistency) for export-only paths.
- OSD rendering logic remains governed by typographic rules.

#### Scenario: Exporting text with non-standard spacing
- **GIVEN** a subtitle line "Word1 , Word2" (with a space before the comma)
- **WHEN** the user selects this range and copies it
- **THEN** the resulting string SHALL be "Word1 , Word2" (verbatim)
- **AND NOT** "Word1, Word2" (normalized)

### Requirement: Selection Punctuation Preservation
Export logic SHALL NOT automatically strip leading or trailing punctuation symbols if they were explicitly included in the user's selection range.
- This MODIFIES Requirement 128 (Strict Selection Boundaries) to respect user intent.

#### Scenario: Explicitly selecting a bracketed word
- **GIVEN** a subtitle "[Musik]"
- **WHEN** the user highlights the entire line including the brackets
- **THEN** the exported term SHALL be "[Musik]"
- **AND NOT** "Musik"

### Requirement: Unified Export Service
The system SHALL provide a central logic service (`prepare_export_text`) that handles all string reconstruction for mining and clipboard actions, ensuring behavioral parity across all triggers (MMB, Ctrl+C, etc.).
