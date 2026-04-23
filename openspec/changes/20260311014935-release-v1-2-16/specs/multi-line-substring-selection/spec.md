## ADDED Requirements

### Requirement: Range Selection
The system SHALL allow users to select a range of words or lines within the Drum Window using the `Shift` modifier.

#### Scenario: Selecting a phrase
- **WHEN** the user holds `Shift` and navigates with arrow keys
- **THEN** the system SHALL highlight all words between the initial selection anchor and the current cursor position.

### Requirement: Aggregate Clipboard Export
The system SHALL aggregate all selected words into a single, clean text string when copying to the clipboard.

#### Scenario: Copying multi-line selection
- **WHEN** the user presses `Ctrl+C` while a multi-line range is selected
- **THEN** the system SHALL export the combined text of all selected words, respecting their chronological order.
