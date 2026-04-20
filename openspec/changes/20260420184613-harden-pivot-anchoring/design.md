## Context

The system requires hardening across three functional layers: coordinate grounding, visual highlighting, and sub-word indexing.

## Goals / Non-Goals

**Goals:**
- **Gap 1**: Replace geometric `pivot_pos` with `advanced_index` grounding.
- **Gap 2**: Implement Phase 2 (Green) highlights for contextually grounded, non-contiguous matches on the origin line.
- **Gap 3**: Implement fractional indexing (0.1 increments) for punctuation to enable granular selection.

## Decisions

### 1. Fractional Indexing Strategy
The `build_word_list_internal` function will be updated to maintain a sub-index for non-word tokens.
- **Logic**: If a word is 1, the following comma is 1.1, the next space is 1.2, etc. The next word is 2.
- **Impact**: `dw_hit_test` will now return floats for `word_idx`. Hit-testing logic will be updated to handle decimal comparisons with a 0.0001 epsilon.

### 2. Highlighting Phase 2 Detection
`calculate_highlight_stack` will be updated to differentiate between "On-Line" and "Cross-Line" split matches.
- **Logic**: If `match_found` is false for contiguous but true for split, we check if all involved words reside on the same `sub_idx`.
- **Visual**: If same line → Green; if different lines → Purple.

### 3. Context Grounding Refinement
`extract_anki_context` will ingest the `coord_map` and use `get_sub_tokens` to find the byte offset of the word whose `logical_idx` matches the pivot.

## Risks / Trade-offs

- **[Floating Point Jitter]** → Comparing `1.1 == 1.1` in Lua can be unstable. *Mitigation*: Implementation MUST use `math.abs(a - b) < 0.0001` for all index comparisons.
- **[Anki Compatibility]** → Anki export fields (except `source_index`) should continue to use text-based values.
