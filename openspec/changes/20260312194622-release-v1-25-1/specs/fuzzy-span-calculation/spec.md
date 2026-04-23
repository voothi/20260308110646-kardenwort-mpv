## ADDED Requirements

### Requirement: Positional Match Indexing
The search engine SHALL be capable of identifying and returning the start and end indices of a fuzzy match within a target subtitle string.

#### Scenario: Calculating match span
- **WHEN** the user searches for "mne" and the subtitle is "manage"
- **THEN** the system SHALL identify the match span as [1, 6] (from 'm' to 'e').
