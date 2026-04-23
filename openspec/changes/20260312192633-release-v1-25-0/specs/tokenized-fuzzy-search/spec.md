## ADDED Requirements

### Requirement: Order-Independent Keyword Matching
The search system SHALL allow users to input multiple keywords separated by whitespace and match them regardless of their order in the target subtitle.

#### Scenario: Searching with swapped word order
- **WHEN** the user searches for "fox quick"
- **THEN** the system SHALL match the subtitle "The quick brown fox jumped".

### Requirement: Per-Token Fuzzy Validation
The search system SHALL perform a fuzzy validation for every token in the query to provide typo tolerance.

#### Scenario: Searching with a typo
- **WHEN** the user searches for "qick fx"
- **THEN** the system SHALL match "quick fox" by validating each token's fuzzy subsequence.
