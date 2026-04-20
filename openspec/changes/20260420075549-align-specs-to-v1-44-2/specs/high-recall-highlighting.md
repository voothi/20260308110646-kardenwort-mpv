## ADDED Requirements

### Requirement: Generous Inter-Segment Bridging
The temporal gap tolerance for joining adjacent subtitle segments into a single phrase match SHALL be expanded to support slow speech.

#### Scenario: 10s Gap Tolerance
- **WHEN** two segments contain sequential components of a saved term
- **AND** the temporal gap between the segments is less than or equal to **10.0 seconds**
- **THEN** the system SHALL treat the segments as contiguous for highlight rendering.
