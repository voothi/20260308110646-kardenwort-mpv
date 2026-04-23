## Context

With the introduction of true fuzzy matching, search results could sometimes feel "mysterious" if the user didn't see the specific character sequence that triggered the match. This release provides visual transparency by marking every "hit" with high-contrast formatting.

## Goals / Non-Goals

**Goals:**
- Provide character-level visual feedback for fuzzy matches.
- Ensure high contrast regardless of whether a result is currently selected.
- Prevent OSD performance degradation caused by excessive ASS tagging.

## Decisions

- **Indexing Overhaul**: The system moves from range-based detection (`find_fuzzy_span`) to list-based detection (`find_fuzzy_indices`). This is necessary to support non-contiguous highlights (e.g., highlighting 'm', 'n', and 'e' separately in 'manage').
- **Styling Logic**: During OSD string construction, the script iterates through the subtitle text. If an index exists in the `hl` table, it wraps the character in `\b1` (bold) and the appropriate high-contrast color tag.
- **Contrast Switching**: The highlighting colors are inverted when a result is selected. This ensures the matched characters always remain the most prominent visual element.
- **Truncation Buffer**: Since each highlight adds multiple ASS tags, long lines could exceed the OSD's optimal processing buffer. A 120-character limit is enforced to keep the UI snappy.

## Risks / Trade-offs

- **Risk**: Iterative string manipulation in Lua is relatively slow.
- **Mitigation**: The highlight calculation is only performed when the query changes, and the visual truncation limit reduces the per-frame rendering burden.
