## MODIFIED Requirements

### Requirement: Adaptive Temporal Highlight Window
The engine SHALL calculate the fuzzy matching window dynamically based on the mode and length of the saved term.
- **Global Mode**: Base window: 10s (configurable via `anki_local_fuzzy_window`).
- **Local Mode**: Base window: 2s.
- Growth: +0.5 seconds for every word beyond the 10th word (Global Mode only).

#### Scenario: Highlighting in Local Mode
- **WHEN** `anki_global_highlight` is `false`
- **THEN** the system SHALL use a fixed 2.0s window regardless of term length to prioritize precision over recall.

### Requirement: Deep Segment Peeking
The engine SHALL recursively traverse adjacent subtitle segments to verify a phrase match. The depth of traversal SHALL vary based on the highlighting mode.
- **Global Mode**: Traverse up to 15 adjacent segments.
- **Local Mode**: Traverse up to 3 adjacent segments.

#### Scenario: Phrase split in local mode
- **WHEN** a phrase is split across 4 subtitles
- **AND** global highlighting is OFF
- **THEN** only the portions within the 3-subtitle scan radius of the export timestamp SHALL be highlighted.
