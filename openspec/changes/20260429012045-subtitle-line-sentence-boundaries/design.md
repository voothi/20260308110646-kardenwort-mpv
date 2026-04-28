## Context

`extract_anki_context` in `lls_core.lua` joins subtitle entries into a single space-separated string and then scans that string for period characters to locate sentence boundaries. German abbreviations (`ca.`, `z.B.`, `usw.`, `bzw.`, `T.CON`) end with a period, so the scanner fires a false positive and truncates the exported context at the wrong point.

There are two independent trigger sites:

| Site | Code | Bug |
|---|---|---|
| `extract_anki_context` — backwards scan | `pre:reverse():find("%s+[.!?]")` | Fires on `" ca."` in `"Es liegt ca. 97 km"` |
| `dw_anki_export_selection` — word check | `prev_text:match("[.!?]$")` | Fires on `"ca."`, `"z.B."` as the word before the selection |

The data is already structured as subtitle lines. Each subtitle is one coherent text unit. Real sentence boundaries live at the edges between subtitle entries, not inside them.

## Goals / Non-Goals

**Goals:**
- Eliminate false sentence-boundary detection caused by period-terminated abbreviations.
- Make sentence scoping derived from subtitle line boundaries (which are structurally reliable).
- Leave word-count truncation, span padding, and pivot-anchor logic untouched.
- No new config keys, no TSV schema changes.

**Non-Goals:**
- Full NLP-based abbreviation detection (spaCy, regex dictionary).
- Handling the edge case where a genuine sentence ends at the same character position as an abbreviation (treated as a known acceptable limitation).
- Changing the `is_sentence_boundary` flag's effect on the term string (adding a trailing period to the exported term when it is a full sentence).

## Decisions

### Decision 1: Sentinel-delimited context string instead of space-joined

**Choice:** Join subtitle texts with a NUL sentinel (`\0`) when building `context_line` for `extract_anki_context`. Inside the function, replace the period-scanning boundary logic with a sentinel-scan.

**Why this over alternatives:**

| Alternative | Problem |
|---|---|
| Pass raw sub table to `extract_anki_context` | Requires refactoring the function signature and all three call sites; risk of regression |
| Abbreviation regex blocklist | German has hundreds of abbreviations; list is never complete; `ca.` at a true sentence-end still breaks |
| Strip periods from all tokens before joining | Loses legitimate end-of-sentence periods; breaks sentence completeness for the term |
| NUL sentinel | Zero-width, never appears in subtitle text naturally, invisible to word-count and span logic, requires changes only at join point and boundary scan point |

**Sentinel protocol:**
- Builder: `table.concat(ctx_parts, "\0")` (replaces `" "`)
- `extract_anki_context`: instead of `pre:reverse():find("%s+[.!?]")`, find `\0` in `pre:reverse()` to locate the start of the subtitle containing the selection.
- Forward scan: `post:find("\0")` gives the end of that subtitle (instead of `post:find("[.!?]")`).
- After extraction, strip all `\0` from the result (they shouldn't appear in the final sentence).

This is purely internal; the caller and caller's caller see no change.

### Decision 2: Guard `prev_text:match("[.!?]$")` with an abbreviation heuristic

**Choice:** Before declaring `is_sentence_boundary = true` from a word ending in `.`, verify the word is not an abbreviation using a lightweight pattern:

```lua
local function is_abbrev(w)
    -- Single or double lowercase letters followed by period: ca. bzw. usw. etc.
    if w:match("^%l+%.$") and #w <= 5 then return true end
    -- Uppercase letter + period patterns: z.B.  T.CON-style already tokenises differently
    if w:match("^%u%.$") then return true end
    return false
end
```

A word passes the existing `[.!?]$` test **and** is NOT an abbreviation → boundary declared.

**Why not remove the check entirely?** The check exists because sometimes the word immediately before a sentence boundary (e.g. "Ende.") carries the terminal punctuation. Removing it would break single-word selections where the previous word ended a sentence.

### Decision 3: Sentence scoping from subtitle boundaries, not intra-line periods

When the sentinel is found, the "sentence" given to the word-count check is the raw text of the subtitle containing the selection (between two `\0` sentinels). If the sentence is under the word limit it is returned verbatim. If it's over the limit, truncation continues with the existing span-centered window logic.

This replaces the previous behavior where the sentence could be any arbitrary fragment between two period characters found anywhere in the multi-line joined block.

## Risks / Trade-offs

- **[Risk] `ca.` at the literal end of a subtitle line** — if a subtitle ends with `"Es liegt ca."` and the next subtitle is `"97 km"`, the two subtitles will be joined as `"Es liegt ca.\097 km"`. The sentinel boundary lands between them. Sentence = `"Es liegt ca."`. This is correct behavior: the exported sentence is the full subtitle text, period included, without any false split. The word `97` is in the next subtitle and is accessible as padding. → **No mitigation needed.**

- **[Risk] Sentence-end detection for multi-subtitle selections** — when a paired selection spans subtitles N and N+1, the primary "sentence" is now the combined text of both. Sentinel is only useful for isolating a single subtitle. For multi-subtitle ranges the new code should use the combined N..N+1 text, with the sentinels used only to avoid splitting inside N or N+1. → Mitigation: for multi-subtitle selections, use `full_line` directly (already the combined text) with no sentence-scope narrowing — only truncation.

- **[Risk] NUL character in exotic subtitle sources** — unlikely but theoretically possible if a subtitle file contains a NUL byte. → Mitigation: sanitize `text` in the subtitle loader to strip any NUL bytes before storing.

## Migration Plan

1. Edit the NUL-sanitization into the `load_sub` parser (one line per format branch).
2. Change join separator in the two context-building loops (`p1_l..p2_l` range and single-line) from `" "` to `"\0"`.
3. Rewrite the sentence-scoping block in `extract_anki_context` (lines 1729-1761): replace `pre:reverse():find("%s+[.!?]")` + `post:find("[.!?]")` with NUL-scan logic.
4. Add `is_abbrev()` guard to the two `is_sentence_boundary` trigger sites.
5. Strip any residual `\0` from the returned sentence string.
6. Test with: `"Es liegt ca. 97 km"`, `"z.B. Firmen"`, `"T.CON oder"`, and a genuine multi-sentence block.

No rollback strategy needed — change is limited to pure string-processing logic with no persistent state or file-format impact.
