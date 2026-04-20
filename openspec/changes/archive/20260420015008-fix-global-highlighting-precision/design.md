## Context
The current Global Mode highlighting logic in `lls_core.lua` is too dependent on the absolute timestamp of the original Anki record (`data.time`). This works fine for Local Mode (Global OFF) where the user wants to see the specific occurrence they saved, but it fails in Global Mode when the same words or phrases appear in different movies or different scenes. Additionally, the neighborhood verification for single words uses a literal substring match, which is extremely sensitive to minor punctuation differences.

## Goals / Non-Goals

**Goals:**
- Enable robust Global Mode highlighting for multi-word split terms across the entire timeline.
- Relax context verification for single words to be punctuation-agnostic by using word-token intersection.
- Maintain the "Index Grounding" fix for Local Mode (Global OFF) to prevent duplicates at the source.

**Non-Goals:**
- Changing Local Mode (Global OFF) logic.
- Altering the core TSV format or how pivots are stored.
- Implementing full fuzzy string matching (Levenstein).

## Decisions

### 1. Global Phase 3 Un-grounding
In `calculate_highlight_stack`, Phase 3 (Split Matching) will be modified to detect if `anki_global_highlight` is active. If so, the search radius for constituent words will be centered on the current `sub_idx` rather than being bounded by the original `data.time`. The `gap` check against `data.time` will be bypassed, but the inter-constituent temporal gap check (`anki_split_gap_limit`) will remain active to ensure the words form a coherent phrase within the current movie context.

### 2. Token-Based Neighborhood Verification
The Phase 2 `context_satisfied` check for Global Mode will transition from a literal `string:find` to an intersection check.
- **Logic**: For each subtitle segment in the `anki_neighbor_window`, tokenize the segment text into words.
- **Verification**: A segment is considered a "neighbor match" if at least one of its word tokens (after stripping punctuation and ensuring it's not a single-character symbol) is found as a substring within the card's `data.__ctx_lower`.
- **Rationale**: This fulfills the spec requirement for a neighborhood check while accommodating variations in punctuation (e.g., matching "word." from a segment against the context "the word is here").

## Risks / Trade-offs

**Risks:**
- **Performance**: Tokenizing 11 segments (±5 `scan_pad`) for every word in the Drum Window might introduce micro-stutter.
- **Solution**: Use a very lightweight Lua pattern match for tokenization and cache the "cleaned" neighbor tokens for the duration of the `calculate_highlight_stack` call.

**Trade-offs:**
- **Recall vs. Precision**: Moving to a word-based intersection might slightly increase false positives for extremely short common words if the context is very generic. However, the requirement of matching at least one non-symbol word remains a high bar for random matches.
