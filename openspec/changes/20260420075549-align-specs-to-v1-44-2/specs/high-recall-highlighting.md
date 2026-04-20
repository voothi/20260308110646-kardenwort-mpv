## ADDED Requirements

### Requirement: Generous Inter-Segment Bridging
The temporal gap tolerance for joining adjacent subtitle segments into a single phrase match SHALL be expanded to support slow speech.

#### Scenario: 10s Gap Tolerance
- **WHEN** two segments contain sequential components of a saved term
- **AND** the temporal gap between the segments is less than or equal to **10.0 seconds**
- **THEN** the system SHALL treat the segments as contiguous for highlight rendering.

### Requirement: Precision Neighborhood Verification (Token Intersection)
When Global Highlighting is active, the system SHALL verify that the current subtitle scene is contextually related to the original Anki record before rendering a highlight.

#### Scenario: Contextual Anchor found
- **WHEN** `anki_global_highlight` is enabled
- **AND** the engine finds a textual match for a saved term
- **THEN** it SHALL scan neighboring segments (+/- 5 lines).
- **IF** any word of length >= 2 in those segments is found in the record's stored context (minus punctuation)
- **THEN** the highlight SHALL be rendered.

#### Scenario: Contextual Anchor NOT found
- **WHEN** no words from the neighborhood (excluding punctuation) match the stored context
- **THEN** the highlight SHALL NOT be rendered, even if the literal term matches.
