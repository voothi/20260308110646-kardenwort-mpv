## Context

The current `calculate_highlight_stack` attempts to find multi-word and split-word phrases by searching for raw string subsets within a temporal cluster (`[-15, +15]`). This loose temporal bounding combined with fuzzy string matching causes false positives, where a word saved at 0:45 incorrectly lights up an identical word at 0:28. Fixing this via temporal clamping breaks split-verbs. The only permanent solution is to tokenize the text and match by strict logical indices.

## Goals / Non-Goals

**Goals:**
- Implement a one-time parsing step that converts raw subtitle text into a cached array of Rich Tokens.
- Establish a dual-indexing system (`visual_idx` for drawing, `logical_idx` for dictionary matching).
- Refactor the highlighter to apply ASS tags via direct array indexing.

**Non-Goals:**
- Modifying the underlying `.tsv` Anki database structure.
- Changing the visual appearance or color palettes of the Drum Window.

## Decisions

### 1. Rich Token Structure
The `build_word_list_internal` scanner will output a table of objects rather than a flat string array:
`{ text = "Wort", is_word = true, logical_idx = 1, visual_idx = 1 }`
Whitespace and ASS tags will receive `is_word = false` and `logical_idx = nil`.

### 2. Rendering via Token Assembly
The `format_sub` and `draw_dw` loops will no longer need to execute complex string stripping to isolate punctuation. They will simply iterate from `visual_idx = 1` to `N`. If a token's `logical_idx` is flagged as a highlight by the engine, the ASS color tag is wrapped around that specific token's `text` property. 

### 3. Strict Index Matching
When `calculate_highlight_stack` evaluates a multi-word term, it will search the `logical_idx` stream. If a saved term is 3 words long, the engine checks if `logical_idx[n]`, `logical_idx[n+1]`, and `logical_idx[n+2]` match the cached cleaned values of the Anki term.

## Risks / Trade-offs

- **Risk:** Memory overhead of caching rich token tables for the entire subtitle file.
  - **Mitigation:** Subtitle files are exceptionally small (rarely exceeding 100KB of text). Caching tables of this size in Lua requires negligible RAM and prevents GC thrashing compared to generating them on-the-fly every frame.
