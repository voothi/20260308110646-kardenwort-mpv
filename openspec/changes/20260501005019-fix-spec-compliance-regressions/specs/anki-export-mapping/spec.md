## REMOVED Requirements

### Requirement: Professional Bracket Stripping
**Reason**: This "smart" cleaning logic is too aggressive and often strips brackets that the user explicitly intended to export (e.g., `[Musik]`). It is replaced by a **Strict Verbatim** policy.
**Migration**: Users must manually adjust their selection range to include or exclude brackets.

## MODIFIED Requirements

### Requirement: Selection Punctuation Preservation
Export logic SHALL NOT perform any automatic filtering, stripping, or cleaning of leading/trailing symbols. The system SHALL strictly export the character sequence defined by the user's manual selection range.

#### Scenario: Verbatim bracket export
- **GIVEN** a subtitle "[Musik]"
- **WHEN** the user selects the entire line including the brackets
- **THEN** the exported term SHALL be "[Musik]"
- **AND** the system SHALL NOT attempt to "clean" the brackets away.
