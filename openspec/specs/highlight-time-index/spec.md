# Specification: Highlight Time Indexing

## Requirement: O(log N) Highlight Selection
The system SHALL maintain a time-sorted index of Anki highlights to enable fast binary-search lookup during subtitle rendering, reducing the complexity of finding relevant highlights from O(N) to O(log N).

#### Scenario: Rendering a subtitle at time T
- **WHEN** `calculate_highlight_stack()` is called for a subtitle line at time T, and there are 500 highlights total but only 10 within the search window of T
- **THEN** the function SHALL evaluate only those 10 highlights (plus any multi-word highlights eligible via `anki_split_search_window`), not all 500

#### Scenario: Global Mode fallback
- **WHEN** `anki_global_highlight = true`
- **THEN** the function SHALL skip the binary-search optimization and fall back to scanning all highlights (existing behavior preserved)

### Requirement: In-Memory Highlight Insertion
When `save_anki_tsv_row()` appends a new highlight to `FSM.ANKI_HIGHLIGHTS`, the system SHALL also insert the new entry into `FSM.ANKI_HIGHLIGHTS_SORTED` at the correct sorted position to maintain sort order.

#### Scenario: User adds a highlight during playback
- **WHEN** the user saves a new Anki highlight at time T
- **THEN** the sorted index SHALL contain the new entry at the correct position (sorted by time) without requiring a full TSV reload
