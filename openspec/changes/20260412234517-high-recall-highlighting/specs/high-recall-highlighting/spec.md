# High-Recall Highlighting

## Requirements

### Requirement: Inter-Segment Sequence Matching
The highlighter engine SHALL be capable of verifying word sequences that are split across adjacent subtitle segments.

#### Scenario: Phrase split across two subtitles
- **WHEN** the term "falsch sind" is saved
- **AND** "falsch" is the last word of Subtitle 1
- **AND** "sind" is the first word of Subtitle 2
- **AND** Subtitle 2 starts within 1.5 seconds of Subtitle 1 ending
- **THEN** both "falsch" and "sind" SHALL be highlighted in their respective segments

### Requirement: Windowed Sequence Verification
The engine SHALL verify phrase integrity by checking a ±3 word local "neighborhood" around any match candidate.
- This allows long paragraphs that exceed the display buffer to remain highlighted while still preventing common-word bleed (e.g., 'nur', 'die') in Global Mode.

### Requirement: Temporal Proximity for Multi-Segment Phrases
The engine SHALL only join adjacent segments into a single match if the temporal gap between them is less than or equal to 1.5 seconds.
- This accommodates natural pauses in news reader speech while maintaining phrase integrity.

### Requirement: Deep Segment Peeking
The engine SHALL recursively traverse up to 5 adjacent subtitle segments to verify a phrase match.
- This ensures continuity for paragraphs that are heavily fragmented into single-word or short-phrase subtitles.

### Requirement: Adaptive Temporal Highlight Window
The engine SHALL calculate the fuzzy matching window dynamically based on the length of the saved term.
- Base window: `lls-anki_local_fuzzy_window` (e.g., 10s).
- Growth: +0.5 seconds for every word beyond the 10th word.
- Goal: Ensure long paragraphs stay highlighted for the duration of their reading time.

### Requirement: Performance Caching
The engine SHALL cache word lists and cleaned text for all highlight terms on first access.
- Rendering latency SHALL NOT increase significantly when hundreds of terms are active.
