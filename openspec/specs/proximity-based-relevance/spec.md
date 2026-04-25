## ADDED Requirements

### Requirement: Ultra-Compact Proximity Bonus
The search system SHALL award a significant score bonus (+150) to matches where the character span is nearly equal to the query length, indicating a high-density intra-word match.

#### Scenario: Rewarding localized matches
- **WHEN** the query "mne" matches "manage" (Span 6)
- **THEN** the system SHALL apply the Ultra-Compact bonus to prioritize this result.

### Requirement: Compact Proximity Bonus
The search system SHALL award a moderate score bonus (+50) to matches that are slightly wider but still localized within a small neighborhood of text.

#### Scenario: Rewarding near-proximity matches
- **WHEN** the query "mne" matches "main engine" (Span 11)
- **THEN** the system SHALL apply the Compact bonus.
