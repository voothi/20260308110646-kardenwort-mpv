## ADDED Requirements

### Requirement: Point-Based Result Ranking
The search system SHALL assign a numeric relevance score to every match and sort the results by this score in descending order.

#### Scenario: Sorting multiple matches
- **WHEN** the user searches for "word" and the subtitles contain "word" (exact), "wordy" (prefix), and "my word" (substring)
- **THEN** the system SHALL display them in the order: "word" (1000) > "wordy" (800) > "my word" (500).

### Requirement: Stability-Preserving Sorting
When multiple search results have identical relevance scores, the system SHALL preserve their original chronological order from the subtitle file.

#### Scenario: Identical score matches
- **WHEN** multiple lines contain the same substring match
- **THEN** the system SHALL display them in the order they appear in the media.
