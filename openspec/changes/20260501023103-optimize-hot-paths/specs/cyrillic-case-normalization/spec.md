## MODIFIED Requirements

### Requirement: Multi-Byte Case Normalization
The system SHALL provide a specialized utility to normalize Cyrillic characters to lowercase for accurate case-insensitive searching. The Cyrillic and German upper/lower character mapping tables SHALL be defined as module-scope constants, created once at script load time, and reused across all invocations of `utf8_to_lower()`.

#### Scenario: Searching for capitalized Russian text
- **WHEN** the user searches for "привет" (lowercase) and the subtitle contains "Привет" (capitalized)
- **THEN** the system SHALL correctly identify this as a match by normalizing the subtitle text to lowercase during the comparison.

#### Scenario: Repeated lowering calls
- **WHEN** `utf8_to_lower()` is called multiple times during a single tick (e.g., inside `calculate_highlight_stack` for each token)
- **THEN** each call SHALL reuse the pre-built module-scope character tables without creating temporary string arrays or calling `utf8_to_table()` on the mapping strings
