## Why

This change formalizes the Search Hit Highlighting features introduced in Release v1.26.0. As the search engine became more complex with fuzzy keyword matching (v1.25.x), users required immediate visual feedback to understand why specific results were being returned. This update introduces "elegant" character-level highlighting, allowing the user to see exactly which parts of a subtitle line matched their query, even in non-contiguous subsequence scenarios.

## What Changes

- Implementation of **Character-Level Indexing**: The `find_fuzzy_span` utility has been evolved into `find_fuzzy_indices()`, which returns a complete list of every character index that contributed to the match.
- Implementation of **Dynamic Contrast Rendering**:
    - **Normal Results**: White text with **Bold Red** character hits.
    - **Selected Result**: Red background/text with **Bold White** character hits.
- Integration of **Visual Truncation Guards**: Enforcing a 120-character limit for result line rendering to maintain OSD performance despite the overhead of iterative ASS tag injection.
- Metadata Caching: Search result objects now store both the subtitle index and the bit-map of matched indices to ensure efficient OSD redraws.

## Capabilities

### New Capabilities
- `character-level-hit-highlighting`: A high-precision UI capability that provides character-by-character visual feedback for complex string-matching algorithms.
- `dynamic-contrast-rendering`: A rendering logic that adjusts color and style properties on-the-fly to ensure optimal legibility across different UI states (e.g., hover/selection).

### Modified Capabilities
- `universal-subtitle-search`: Upgraded with professional-grade visual feedback and performance hardening.

## Impact

- **Match Clarity**: Immediate confirmation of fuzzy-match relevance (e.g., seeing exactly which letters of "manage" matched the query "mne").
- **UI Professionalism**: Elegant, state-aware highlighting that matches high-end text editors and search HUDs.
- **Performance Stability**: The truncation guard ensures the OSD remains responsive even when processing long subtitle lines with multiple highlights.
