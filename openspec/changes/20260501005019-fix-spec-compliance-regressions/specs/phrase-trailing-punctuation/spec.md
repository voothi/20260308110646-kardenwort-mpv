## REMOVED Requirements

### Requirement: Phrase Trailing Punctuation Capture
**Reason**: To simplify the export pipeline and ensure absolute predictability, the system will no longer perform lookahead to "capture" punctuation that wasn't explicitly selected.
**Migration**: Users who want trailing punctuation in their export MUST include it in their selection range.

#### Scenario: Strictly manual punctuation
- **WHEN** the user selects "word" and a period follows it but is NOT selected
- **THEN** the exported term SHALL be "word" (no period).
