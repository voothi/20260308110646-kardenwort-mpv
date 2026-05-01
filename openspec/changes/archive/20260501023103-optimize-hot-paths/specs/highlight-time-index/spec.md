## ADDED Requirements

### Requirement: Time-Sorted Highlight Index
The system SHALL maintain a time-sorted index of Anki highlights (`FSM.ANKI_HIGHLIGHTS_SORTED`) that is rebuilt whenever `load_anki_tsv()` replaces the highlight array.

#### Scenario: TSV file loaded or reloaded
- **WHEN** `load_anki_tsv()` successfully parses the TSV and populates `FSM.ANKI_HIGHLIGHTS`
- **THEN** the system SHALL build `FSM.ANKI_HIGHLIGHTS_SORTED` as an array of `{time, idx}` pairs sorted by `time` ascending, where `idx` is the position in `FSM.ANKI_HIGHLIGHTS`

### Requirement: Binary-Search Window Lookup
The `calculate_highlight_stack()` function SHALL use binary search on `FSM.ANKI_HIGHLIGHTS_SORTED` to find only the highlights within the temporal window `[sub_start - window, sub_end + window]`, instead of scanning all highlights.

#### Scenario: Local Mode with 500 highlights, 10 in window
- **WHEN** `calculate_highlight_stack` runs with `anki_global_highlight = false` and there are 500 total highlights but only 10 fall within the time window
- **THEN** the function SHALL evaluate only those 10 highlights (plus any multi-word highlights eligible via `anki_split_search_window`), not all 500

#### Scenario: Global Mode fallback
- **WHEN** `anki_global_highlight = true`
- **THEN** the function SHALL skip the binary-search optimization and fall back to scanning all highlights (existing behavior preserved)

### Requirement: In-Memory Highlight Insertion
When `save_anki_tsv_row()` appends a new highlight to `FSM.ANKI_HIGHLIGHTS`, the system SHALL also insert the new entry into `FSM.ANKI_HIGHLIGHTS_SORTED` at the correct sorted position to maintain sort order.

#### Scenario: User adds a highlight during playback
- **WHEN** the user saves a new Anki highlight at time T
- **THEN** the sorted index SHALL contain the new entry at the correct position (sorted by time) without requiring a full TSV reload
