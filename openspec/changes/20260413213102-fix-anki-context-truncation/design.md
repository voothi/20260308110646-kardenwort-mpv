## Context

The `extract_anki_context` function in `lls_core.lua` currently cuts off context prematurely if the selected term contains punctuation. Additionally, the fixed word limit of 20 can lead to stunted contexts for long selections in German media.

## Goals / Non-Goals

**Goals:**
- Ensure selections spanning multiple sentences are fully captured in the context field.
- Provide more "breathable" context for long selections by making the truncation limit adaptive.
- Increase the default word limit to better suit higher-level language learning (e.g., B2).

**Non-Goals:**
- Complex grammatical parsing (sticking to punctuation-based boundaries).
- Changing the TSV schema.

## Decisions

### 1. Forward Search Starting Point Shift
The `extract_anki_context` function must identify sentence boundaries relative to the entire range of the selected term. Specifically:
1. **Multi-Sentence Span**: If a selection starts in Sentence A and ends in Sentence B, the logic MUST return the full range from the start of Sentence A to the end of Sentence B.
2. **Boundary Sensitivity**: The forward search for punctuation MUST start at the `end_pos` of the selection to avoid stopping at periods occurring *within* a long selection (the "middle period" bug).
3. **Adaptive Word Count**: To support complex languages like German, the truncation window must be dynamic: `MAX(40, selection_word_count + 20)`. This prevents squeezing the context into a fixed 20-word box when the selection itself is 20 words long.
5. **Whitespace Normalization**: To ensure `string.find` reliably locates the `selected_term` within the `context_line`, both strings MUST be normalized to use single-space delimiters (stripping all internal newlines and multiple spaces). Without this, mismatches between subtitle line-breaks and concatenated terms cause punctuation search to fail and trigger fallback truncation.

### 3. Increased Default Limit
Update `Options.anki_context_max_words` from `20` to `40` to accommodate the longer sentence structures typical in B2/C1 levels.

## Risks / Trade-offs

- **Risk**: Very long sentences might slightly increase the size of the TSV, but for Anki, 40-50 words is still well within reasonable flashcard limits.
- **Trade-off**: By moving the forward search to `end_pos`, we might include slightly more of the *next* sentence if the selection ends exactly on a period, but the trimming logic `match("^[%s.!?]*(.-)%s*$")` should handle this cleanly.
