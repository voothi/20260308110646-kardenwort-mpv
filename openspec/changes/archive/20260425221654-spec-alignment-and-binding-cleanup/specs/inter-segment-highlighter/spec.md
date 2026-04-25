## MODIFIED Requirements

### Requirement: Temporal Proximity for Multi-Segment Phrases
The engine SHALL only join adjacent segments into a single match if the temporal gap between them is less than or equal to **60.0 seconds**.
- This accommodates long-form contextual paragraphs spanning multiple lines while maintaining phrase integrity across natural pauses.

#### Scenario: Long pause between paragraphs
- **WHEN** a saved term spans two subtitles separated by a 45-second gap
- **THEN** both segments SHALL be correctly identified and highlighted as part of the same phrase.
