## ADDED Requirements

### Requirement: Selection Priority in Context Copy
The system SHALL prioritize manual selections (word pointer or range selection) over context-aware text harvesting when `COPY_CONTEXT` is enabled.

#### Scenario: Copying with active pointer and context ON
- **WHEN** the user has a "yellow cursor" (word pointer) on a specific word in the Drum Window.
- **AND** `COPY_CONTEXT` is "ON".
- **AND** the user triggers the copy command.
- **THEN** only the highlighted word SHALL be copied to the clipboard.

#### Scenario: Copying with active range and context ON
- **WHEN** the user has selected a range of words in the Drum Window.
- **AND** `COPY_CONTEXT` is "ON".
- **AND** the user triggers the copy command.
- **THEN** only the selected range SHALL be copied to the clipboard.

#### Scenario: Regulating Context Copy via Esc
- **WHEN** the user has a selection and `COPY_CONTEXT` is "ON".
- **AND** the user presses `Esc` to clear the selection.
- **AND** the user triggers the copy command.
- **THEN** the system SHALL harvest and copy the surrounding dialogue context.
