# Inter-Segment Highlighter

## Purpose
The Inter-Segment Highlighter ensures that phrases and word sequences remain identifiable and highlighted even when they span across multiple adjacent subtitle segments.
## Requirements
### Requirement: Inter-Segment Sequence Matching
The highlighter engine SHALL be capable of verifying word sequences that are split across adjacent subtitle segments.

#### Scenario: Phrase split across two subtitles
- **WHEN** the term "falsch sind" is saved
- **AND** "falsch" is the last word of Subtitle 1
- **AND** "sind" is the first word of Subtitle 2
- **AND** Subtitle 2 starts within 1.5 seconds of Subtitle 1 ending
- **THEN** both "falsch" and "sind" SHALL be highlighted in their respective segments

### Requirement: Temporal Proximity for Multi-Segment Phrases
The engine SHALL only join adjacent segments into a single match if the temporal gap between them is less than or equal to **60.0 seconds**.
- This accommodates long-form contextual paragraphs spanning multiple lines while maintaining phrase integrity across natural pauses.

#### Scenario: Long pause between paragraphs
- **WHEN** a saved term spans two subtitles separated by a 45-second gap
- **THEN** both segments SHALL be correctly identified and highlighted as part of the same phrase.

### Requirement: Deep Segment Peeking
The engine SHALL recursively traverse up to 5 adjacent subtitle segments to verify a phrase match.

#### Scenario: Fragmented paragraphs
- **WHEN** a paragraph is split into 5 single-word subtitles
- **THEN** the highlighter SHALL successfully traverse all 5 segments to confirm the sequence match.

### Requirement: Adaptive Temporal Highlight Window
The engine SHALL calculate the fuzzy matching window dynamically based on the length of the saved term.

#### Scenario: Long paragraph highlight duration
- **WHEN** a term consists of 20 words
- **THEN** the fuzzy window SHALL be extended by 5 seconds (0.5s * 10) beyond the base 10s window.

