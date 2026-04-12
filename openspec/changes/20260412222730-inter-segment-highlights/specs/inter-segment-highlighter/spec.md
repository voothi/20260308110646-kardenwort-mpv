## ADDED Requirements

### Requirement: Inter-Segment Sequence Matching
The highlighter engine SHALL be capable of verifying word sequences that are split across adjacent subtitle segments.

#### Scenario: Phrase split across two subtitles
- **WHEN** the term "falsch sind" is saved
- **AND** "falsch" is the last word of Subtitle 1
- **AND** "sind" is the first word of Subtitle 2
- **AND** Subtitle 2 starts within 500ms of Subtitle 1 ending
- **THEN** both "falsch" and "sind" SHALL be highlighted in their respective segments

### Requirement: Temporal Proximity for Multi-Segment Phrases
The engine SHALL only join adjacent segments into a single match if the temporal gap between them is less than or equal to 500ms.

#### Scenario: Unrelated segments with matching words
- **WHEN** "falsch" ends at 10.0s
- **AND** "sind" starts at 15.0s (5 second gap)
- **THEN** they SHALL NOT be considered part of the same phrase "falsch sind"
