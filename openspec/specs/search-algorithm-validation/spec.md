# search-algorithm-validation Specification

## Purpose
TBD - created by archiving change 20260513121332-search-algorithm-test-coverage. Update Purpose after archive.
## Requirements
### Requirement: Multi-Dimensional Ranking Verification
The search system SHALL be validated against a set of functional scenarios to ensure the relevance scoring algorithm correctly prioritizes results according to specified bonuses.

#### Scenario: Exact Match Priority
- **WHEN** the user searches for a term that exactly matches a subtitle (case-insensitive)
- **THEN** the system SHALL assign the maximum score (2000) and rank it at the top.

#### Scenario: Contiguous Substring Bonus
- **WHEN** the query appears as a verbatim contiguous substring in a match
- **THEN** the system SHALL apply a Proximity Bonus (+400).

#### Scenario: Sequential Order Bonus
- **WHEN** multiple keywords in the query appear in the match in the same order as the query
- **THEN** the system SHALL apply a Sequential Bonus (+300).

#### Scenario: Start-of-Sentence Bonus
- **WHEN** a match begins at the very first character of the subtitle string
- **THEN** the system SHALL apply a Start-of-Sentence Bonus (+300).

#### Scenario: Compactness Bonus
- **WHEN** a fuzzy match spans a range close to the keyword length
- **THEN** the system SHALL apply a Compactness Bonus (+150 for very compact, +5 for reasonably compact).

