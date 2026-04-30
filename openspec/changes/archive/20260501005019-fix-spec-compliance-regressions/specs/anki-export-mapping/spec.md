## MODIFIED Requirements

### Requirement: Selection Punctuation Preservation
Export logic SHALL NOT perform any automatic filtering, stripping, or cleaning of leading/trailing symbols (including balanced brackets like `[]`, `()`, or `{}`). The system SHALL strictly export the character sequence defined by the user's manual selection range.
- **Clarification**: All "smart" bracket stripping is removed to ensure absolute verbatim fidelity.

#### Scenario: Verbatim bracket export
- **GIVEN** a subtitle "[Musik]"
- **WHEN** the user selects the entire line including the brackets
- **THEN** the exported term SHALL be "[Musik]"
- **AND** the system SHALL NOT attempt to "clean" the brackets away.
