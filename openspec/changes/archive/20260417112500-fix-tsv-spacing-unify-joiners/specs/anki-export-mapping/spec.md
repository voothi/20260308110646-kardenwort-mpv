## MODIFIED Requirements

### Requirement: Natural Context Extraction
The Anki export system SHALL prioritize using the original subtitle spacing for the `SentenceSource` context field.

#### Scenario: Multi-segment context building
- **WHEN** a user selects a range of subtitle segments for Anki export
- **THEN** the system SHALL construct the `context_line` by concatenating the original text of each segment with a single space separator.

#### Scenario: Metadata cleaning with natural space preservation
- **WHEN** ASS tags or metadata brackets are removed from the context
- **THEN** trailing/leading spaces from tokens SHALL NOT be doubled or introduced in a way that breaks punctuation spacing.
