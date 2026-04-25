## ADDED Requirements

### Requirement: Multi-Byte Case Normalization
The system SHALL provide a specialized utility to normalize Cyrillic characters to lowercase for accurate case-insensitive searching.

#### Scenario: Searching for capitalized Russian text
- **WHEN** the user searches for "привет" (lowercase) and the subtitle contains "Привет" (capitalized)
- **THEN** the system SHALL correctly identify this as a match by normalizing the subtitle text to lowercase during the comparison.
