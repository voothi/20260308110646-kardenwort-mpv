## Context

The `extract_anki_context` function in `lls_core.lua` is responsible for preparing the `SentenceSource` TSV field by capturing surrounding sentences and applying word-count-based truncation if necessary. Currently, its truncation logic is optimized for contiguous word sequences. When a "split" selection (e.g., `pick ... on`) is processed, the system fails to find the contiguous phrase, loses its anchoring, and falls back to a hardcoded 100-character truncation from the start of the sentence block. This results in data loss (missing keywords) and unprofessional formatting (unwanted trailing ellipses).

## Goals / Non-Goals

**Goals:**
- Fix the `extract_anki_context` logic to support non-contiguous word sets.
- Ensure that split selections are always centered in the exported context.
- Eliminate the arbitrary 100-character truncation fallback.
- Prevent literal ellipses (`...`) in composed terms from interfering with word anchoring.

**Non-Goals:**
- Changing the default word limit (`Options.anki_context_max_words`).
- Modifying the subtitle tokenization engine.

## Decisions

### 1. Ellipsis-Aware Tokenization
In `extract_anki_context`, the `selected_term` will be tokenized using a filter that ignores the literal `...` string. 
- **Rationale**: Composed terms for split selections use `...` as a joiner. Searching for this literal string in the subtitle text leads to false positives if the subtitle contains ellipses, or false negatives if it doesn't, causing anchor drift.

### 2. Multi-Pivot Span Detection
The loop that finds the keyword index (`target_idx`) will be replaced with a span detection algorithm:
- Iterate through the sentence words and find the index of every word in the `selected_term`.
- Record the `first_idx` and `last_idx` of these matches.
- **Rationale**: This allows the engine to "bracket" the entire split phrase, even if there are multiple words between the selected tokens.

### 3. Center-Weighted Truncation
If truncation is required, the "anchor" will be calculated as the midpoint between `first_idx` and `last_idx`.
- **Rationale**: This ensures that even if the selection spans a large distance, the resulting context is centered around the core area of interest, maximizing the chance that all selected words remain visible.

### 4. Removal of String-Based Fallback
The `sentence:sub(1, 100) .. "..."` fallback will be removed. If word-based anchoring fails (which it shouldn't if the term was extracted from the text), the system will fall back to returning the full sentence block or a more sensible centered window.

## Risks / Trade-offs

- **Risk**: If a split selection spans a distance larger than the `limit`, some words may still be cut off.
- **Mitigation**: The dynamic limit calculation already accounts for this by setting `effective_limit = math.max(limit, #term_words + 20)`. The design further mitigates this by centering the viewport.
