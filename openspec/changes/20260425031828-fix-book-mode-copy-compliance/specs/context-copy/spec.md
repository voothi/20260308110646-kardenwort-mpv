## MODIFIED Requirements

### Requirement: Contextual Drum Copy
The Drum Window copy command (`Ctrl+C`) must support context-aware extraction when enabled.

#### Scenario: Verbatim Selection with Context
- **WHEN** a specific word or range of words is selected in the Drum Window and `COPY_CONTEXT` is "ON".
- **THEN** the clipboard must contain the selected text wrapped with `copy_context_lines` from the surrounding subtitle track, preserving the specific selected subset.

## ADDED Requirements

### Requirement: Formatting Preservation (Copy As Is)
The system SHALL preserve all textual formatting markers, including brackets and internal punctuation, during all copy operations to satisfy "Copy as is" requirements.

#### Scenario: Preserving brackets in capture
- **WHEN** copying a line containing metadata markers (e.g., `[räuspern]`)
- **THEN** the resulting clipboard text SHALL include those markers intact.
