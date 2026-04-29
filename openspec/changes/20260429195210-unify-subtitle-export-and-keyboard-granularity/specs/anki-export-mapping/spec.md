## ADDED Requirements

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

### Requirement: Unified Sentence Restoration Parity
The detection and restoration of terminal punctuation (`!`, `?`, `.`) for sentence fragments SHALL be identical across both Yellow and Pink selection modes, centralized within the `prepare_export_text` engine.

#### Scenario: Restoring exclamation mark in Pink mode
- **GIVEN** a subtitle line "Achtung!"
- **AND** "Achtung" is selected in Pink mode
- **WHEN** the export is triggered with `restore_sentence=true`
- **THEN** the resulting string SHALL be "Achtung!".
