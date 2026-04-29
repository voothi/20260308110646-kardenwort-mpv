## Context

The tokenizer `build_word_list_internal` (lls_core.lua ~L911) processes subtitle text into a stream of typed tokens:

| Branch | Trigger | Token type | `logical_idx` assigned |
|---|---|---|---|
| 2 | `[` | word (`is_word=true`) | integer N |
| 3 | whitespace | space | fractional (N-1)+0.1 |
| 4 | `is_word_char(c)` | word (`is_word=true`) | integer N |
| 5 | everything else | punctuation | fractional (N-1)+0.1 |

The phrase collection loop in `dw_anki_export_selection` iterates tokens and stops as soon as it hits a token with `logical_idx > p2_w + L_EPSILON` on the last line. Since `)` is a branch-5 token (fractional index e.g. `3.1`), and `p2_w = 3`, the condition `3.1 > 3 + ε` is true and the loop breaks, excluding `)` from the phrase but keeping it in the raw context string.

This was observed on subtitle: `[UMGEBUNG] Sport-Thieme (Gersdorf/Straubing-Ost)` where the selection of words 1–3 = `[UMGEBUNG]`, `Sport-Thieme`, `Ost` silently drops `)`.

## Goals / Non-Goals

**Goals:**
- Capture trailing fractional-index tokens (closing punctuation) that are directly attached to the last selected word on the final subtitle line.
- Keep the fix contained to `dw_anki_export_selection`; no changes to tokenizer, context extractor, or index format.
- Remain consistent with the existing rule that punctuation between selected words is already captured via the `line_parts` concatenation (since branch-5 tokens are added as-is when they fall within bounds).

**Non-Goals:**
- Capturing trailing tokens from middle lines (only the final line `is_last_line` is affected).
- Altering the `logical_idx` scheme or the `is_word` flag of punctuation tokens.
- Changing the index string format (`WordSourceIndices`) — indices track words only, this is correct.
- Fixing any issue in the context (SentenceSource) field — it reads raw text and is already correct.

## Decisions

### Decision 1: Extend the last-line boundary to include post-p2_w fractional tokens

**Chosen approach:** After the existing break condition (`logical_idx > p2_w + L_EPSILON`), change it to: break only if the token is a *word* token (`is_word == true`) with `logical_idx > p2_w + L_EPSILON`. Non-word fractional tokens (punctuation/spaces) that fall after `p2_w` are included if no new word token has been encountered yet.

```lua
-- Current (line ~3603):
if is_last_line and t.logical_idx > p2_w + L_EPSILON then
    break
end

-- Proposed:
if is_last_line and t.logical_idx > p2_w + L_EPSILON then
    if t.is_word then break end  -- stop only at the next word boundary
    -- non-word tokens (punctuation) are still collected below
end
```

**Alternatives considered:**
- *Post-loop punctuation scan*: After the main loop, scan remaining tokens for fractional trailing punctuation. Rejected — more code, same effect, harder to read.
- *Change L_EPSILON tolerance*: Rejected — would incorrectly include the `(` of the *next* set of tokens in some cases.

### Decision 2: Include the fractional token in `line_parts` and `term_tokens` but NOT in `indices`

Punctuation tokens have `is_word = false`, so they are never added to `indices`. This is correct — the index string tracks words for grounding purposes, and adding punctuation positions there would break the grounding logic. The phrase text benefits from the punctuation while the index remains word-only.

## Risks / Trade-offs

- **[Risk] Over-inclusion of space tokens**: If `p2_w` is the last word on the line and is followed by trailing spaces, those spaces would be included in `line_parts`. → **Mitigation:** `compose_term_smart` already trims trailing whitespace from the assembled term string.
- **[Risk] Punctuation already captured in middle lines**: The condition `is_last_line` gates the change, so middle-line behavior is unchanged. Middle-line punctuation is already captured correctly (the break condition does not fire on middle lines).
- **[Risk] Regression on simple single-word exports**: Single-word exports use `cw` path (not `al/cl` range), which is untouched by this change.
