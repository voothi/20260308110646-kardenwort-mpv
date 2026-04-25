## ADDED Requirements

### Requirement: Context-Aware Score Bonuses
The search system SHALL apply specific score bonuses to reward matches that align with common linguistic patterns and user intent.

#### Scenario: Rewarding exact phrases
- **WHEN** the user's keywords match a literal substring in the subtitle
- **THEN** the system SHALL apply a Proximity Bonus (+400) to ensure this result is prioritized.

#### Scenario: Rewarding chronological order
- **WHEN** the user's keywords appear in the subtitle in the same order as the query
- **THEN** the system SHALL apply a Sequential Bonus (+300).
