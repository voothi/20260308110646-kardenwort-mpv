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
The forward search for `.`, `!`, and `?` will be moved from `start_pos` (inclusive of the term) to `end_pos` (inclusive of the last character of the term). This prevents the "middle period" in a multi-sentence selection from triggering a premature cutoff.

**Logic Change:**
```lua
-- From:
local post = full_line:sub(start_pos)
-- To:
local post = full_line:sub(end_pos)
```

### 2. Adaptive Truncation Window
The truncation logic will be updated to ensure that context doesn't feel "squeezed" when the selection is long. The window will now be calculated as follows:
`effective_max_words = math.max(Options.anki_context_max_words, selection_word_count + 20)`

This ensures that even for long selections, at least 10 words of context (roughly 5 before and 5 after) are preserved if the sentence boundaries allow.

### 3. Increased Default Limit
Update `Options.anki_context_max_words` from `20` to `40` to accommodate the longer sentence structures typical in B2/C1 levels.

## Risks / Trade-offs

- **Risk**: Very long sentences might slightly increase the size of the TSV, but for Anki, 40-50 words is still well within reasonable flashcard limits.
- **Trade-off**: By moving the forward search to `end_pos`, we might include slightly more of the *next* sentence if the selection ends exactly on a period, but the trimming logic `match("^[%s.!?]*(.-)%s*$")` should handle this cleanly.
