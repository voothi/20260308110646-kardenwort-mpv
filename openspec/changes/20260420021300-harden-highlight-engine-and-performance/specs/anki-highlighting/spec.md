## ADDED Requirements

### Requirement: Gated Fuzzy Healing for Local Mode
The engine SHALL implement a secondary anchoring pass for Local Mode highlights when the strict multi-pivot index check fails. This "healing" pass must verify if the target word exists in the immediate temporal neighborhood (+/- 1 line) of the original index.

#### Scenario: Recovery from minor subtitle shifts
- **WHEN** a record contains a valid index anchor but the subtitle file has been modified (e.g., a line added at the start)
- **AND** the target word is found within 1 line of the stored coordinate
- **AND** the neighborhood match (Phase 2) is successful
- **THEN** the highlight SHALL be rendered despite the index mismatch.

### Requirement: Global-Relative Split Search Centering
In Global Mode, the split-phrase search radius MUST be centered on the current active subtitle index rather than the original record timestamp to ensure phrases are discovered across the entire media timeline.

#### Scenario: Highlighting a split phrase in a different episode
- **WHEN** `anki_global_highlight` is active
- **AND** the user is viewing a scene containing a multi-word split term (e.g., "41 bis 45")
- **THEN** the engine SHALL identify the term relative to the current playback position, ignoring the original capture time.
