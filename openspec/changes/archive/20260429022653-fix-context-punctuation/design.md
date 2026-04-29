## Context

The `extract_anki_context` function handles truncation of long subtitle segments for Anki exports. It currently:
1.  Loads the raw sentence.
2.  Splits it into a list of word-tokens (stripping punctuation).
3.  Determines a viewport (e.g., 40 words around the selection).
4.  Re-composes the viewport using `compose_term_smart`.

This approach is lossy because the `words` list discarded the punctuation and spacing of the original subtitle. `compose_term_smart` then attempts to "guess" where spaces should be, but its regex for `no_space_before` incorrectly matches anything ending in `]` (like `[UMGEBUNG]`), causing stuck words.

## Goals / Non-Goals

**Goals:**
- Restore original punctuation (periods, commas, etc.) in truncated Anki context fields.
- Fix spacing issues around bracketed metadata tags.
- Maintain word-count-based truncation logic.

**Non-Goals:**
- Changing the tokenizer's definition of a "word".
- Modifying how paired highlights are grounded.

## Decisions

### Decision 1: Substring-Based Viewport Extraction
Instead of building a new string from a word list, we will use the word list only to identify the "anchor" indices in the original string.
1. Find the byte positions of `words[context_start]` and `words[context_end]` in the source `sentence`.
2. Return the literal substring of `sentence` between these positions.
3. This ensures all spaces and punctuation *between* words are preserved exactly as they appeared in the subtitle.

### Decision 2: Strict Joiner Regex in `compose_term_smart`
Update `no_space_before` to use `^` and `$` anchors:
```lua
local no_space_before = next_w:match("^[%.,!?;:…»”%)%]%}]$")
```
This ensures that `[UMGEBUNG]` (length > 1) does not trigger the "suppress space" rule, while single characters like `)` or `.` still do.

## Risks / Trade-offs

- **[Risk] Word find ambiguity**: If a word appears multiple times, `sentence:find` must correctly find the specific occurrence. → **Mitigation**: Using the `curr_char` offset to search sequentially ensures we find the correct occurrence in document order.
