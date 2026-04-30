## REMOVED Requirements

### Requirement: Phrase Trailing Punctuation Capture

## ADDED Requirements

### Requirement: Manual Punctuation Inclusion
The system SHALL strictly follow the user's manual selection boundaries for all export operations. No lookahead SHALL be performed to capture punctuation that was not explicitly included in the selection range.

#### Scenario: Manual period selection
- **WHEN** the user selects "word" but NOT the following period
- **THEN** the export SHALL contain "word" (no period).
