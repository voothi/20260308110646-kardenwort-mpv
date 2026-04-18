## Context

The current highlighting engine relies on string matching to find words in subtitles. When the same word (e.g., "die", "und", "der") appears in multiple nearby subtitle segments, the engine may incorrectly highlight all occurrences instead of the one specifically selected by the user.

## Goals / Non-Goals

**Goals:**
- Implement unique anchoring for every exported word using a logical word index.
- Correct the "drift" in context extraction where the wrong sentence is picked for a common word.
- Stabilize the configuration parser for external `.ini` files.

**Non-Goals:**
- Retroactively updating all old TSV records (system must be backward compatible).
- Full re-write of the tokenization engine.

## Decisions

### Decision 1: Logical Word Index Mapping
**Rationale**: By saving the `source_index` (logical position 1, 2, 3...) of a word during export, the highlighting engine can perform a strict equality check (`current_index == saved_index`) instead of a fuzzy string search.
**Alternatives Considered**:
- Character offsets: Too brittle if subtitle formatting (ASS tags) changes.
- Temporal-only anchoring: Fails when multiple words appear in the same subtitle segment.

### Decision 2: Pivot-Point Anchoring for Context Extraction
**Rationale**: When building the context string, the exporter now calculates a `pivot_pos` (character offset) corresponding to the user's click. The search engine then identifies the occurrence of the term closest to this pivot. This prevents picking the "die" from an earlier sentence when the user clicked on one in a later sentence.

### Decision 3: "Tag-Aware" Pivot Logic
**Rationale**: The pivot must be calculated on the CLEANED text (no ASS tags) to match the string eventually searched by `extract_anki_context`. The logic now applies identical cleaning steps (`gsub`) in both the pivot calculation and context search.

## Risks / Trade-offs

- **[Risk] Missing Indices in Old Records** → **Mitigation**: The highlighting engine includes a fallback: if `data.index` is missing, it relies on the improved pivot-point context matching, which is much more accurate than the previous "first-found" logic.
- **[Trade-off] Tab-separated Complexity** → **Mitigation**: Added diagnostic console logs to verify that the tab-separated columns and word-lists remain perfectly aligned.
