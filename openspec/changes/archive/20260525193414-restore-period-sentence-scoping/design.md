## Context

`extract_anki_context` (in [scripts/kardenwort/main.lua:2809](scripts/kardenwort/main.lua#L2809)) is responsible for cropping the exported Anki `SentenceSource` field to the grammatical sentence containing the user's selection. The function receives:

- `full_line` — a `\0`-joined block of ±`anki_context_lines` subtitle texts around the selection (built in `dw_anki_export_selection` at [scripts/kardenwort/main.lua:5606](scripts/kardenwort/main.lua#L5606)).
- `selected_term`, `pivot_pos`, `coord_map`, and an optional word-count override.

History:

- **Before** archived change `20260429012045-subtitle-line-sentence-boundaries`: scoping scanned for `[.!?]` directly in the joined block. **Problem**: false splits on `ca.`, `z.B.`, `usw.`, abbreviated YouTube titles.
- **After** that change: scoping uses the `\0` subtitle-line sentinel as the boundary. **Problem**: returned sentence is always one subtitle line wide, even when the real sentence spans 2-3 lines.

The user's current SRT (`20260412001656-hoeren-b2-telc-uebungstest.de.srt`) exposes the regression — see proposal for trace.

## Goals / Non-Goals

**Goals:**
- The exported `SentenceSource` SHALL contain the complete grammatical sentence(s) covering the selection, bounded by real terminators `.`, `!`, `?`.
- When the selection spans multiple sentences, ALL of them (including the terminating sentence on each side) SHALL be included.
- Abbreviations (`ca.`, `z.B.`, `usw.`, `d.h.`, etc.) MUST NOT be treated as sentence terminators.
- Unpunctuated YouTube auto-subtitles MUST continue to produce usable context (fall back to the full ±N joined block).
- Existing `anki_context_max_words` truncation MUST continue to bound the final exported field.

**Non-Goals:**
- No change to TSV column structure, Anki field mapping, or the `\0`-sanitization behaviour of the subtitle loader.
- No change to highlighting, drum-window rendering, or word-token intersection (`high-recall-highlighting`).
- No change to the non-contiguous term anchoring algorithm or precision offset mapping (lines 2844-2890 of `main.lua` stay intact).
- No new external dependencies; only Lua-string scanning.

## Decisions

### Decision 1: Period-anchored boundary scan replaces NUL-sentinel scan

**Choice.** Backward and forward scans walk byte-by-byte through `full_line` (treating `\0` as ordinary whitespace), searching for any character in `Options.anki_sentence_terminators` (default `".!?"`) followed by either whitespace, a `\0` sentinel, or end-of-string. At scan time the option string is converted to a Lua character class pattern so the hot path does no repeated string splitting.

**Alternatives considered:**

1. *Keep NUL scoping, add a "merge with neighbours if they don't end in `.!?`" pass* — fragile; would need to look up the previous/next subtitle's actual text and re-test. The joined `full_line` already gives us the text we need; just stop using `\0` as the boundary.
2. *Comma + semicolon boundaries* — user explicitly excluded these. Would break sentences like `"Es kommt zu kräftigen Niederschlägen, die verbreitet als Schnee liegen bleiben."` by chopping at the first comma.
3. *Tokenize sentences via Lua pattern `[^.!?]+[.!?]`* — fails on abbreviations and requires post-processing to skip them. Plain backward/forward scan is simpler and lets the existing abbreviation heuristic intercept directly.

**Why this wins.** The joined block already preserves original subtitle text verbatim; period scanning across `\0` reconstructs the user's grammatical intent without losing the subtitle-line information we still need for the fallback path.

### Decision 2: Abbreviation skip = existing heuristic + configurable allowlist (additive)

**Choice.** When the scan encounters `[.!?]`, examine the word immediately preceding it. If the word matches:

- The existing heuristic: 1-4 lowercase letters + `.` (`ca.`, `usw.`, `bzw.`, `d.h.`); OR a single uppercase letter + `.` segment (`z.B.`, `T.CON`); OR
- A member of the new `Options.anki_abbrev_list` (case-insensitive exact match against the token including the period),

then treat the period as **not a terminator** and continue scanning. The heuristic remains primary; the list is an additive safety net for tokens the heuristic misses (e.g. `etc.`, `bspw.`, `ggf.`).

**Default `anki_abbrev_list`**: `"z.B., bzw., usw., ca., d.h., u.a., etc., vgl., ggf., bspw., u.a., u.U., i.d.R., bzgl., evtl."`. Configurable in `mpv.conf` via `script-opts=kardenwort-anki_abbrev_list=...`.

**Alternatives considered:**

1. *List-only (no heuristic)* — every new abbreviation requires config edits; bad UX.
2. *Heuristic-only (no list)* — heuristic misses some valid tokens like `etc.` (3 letters, fine) or oddities like `i.d.R.` if a future spec adds them.
3. *NLP/locale-based detector* — overkill; this is an mpv Lua script.

### Decision 3: No-terminator fallback = entire joined context block

**Choice.** If the backward scan reaches index 1 without finding a real terminator AND the forward scan reaches the end without finding one, return the **entire** `full_line` (with `\0` replaced by space) — bounded only by the subsequent `anki_context_max_words` truncation.

**Alternatives considered:**

1. *Fall back to single subtitle line* — that's the **current broken behaviour**; defeats the fix.
2. *Hard cap N subtitle lines around selection* — user prefers no arbitrary cap; word-count limit already provides bounding.
3. *Mix: backward terminator found but forward not* — handled naturally; we accept whichever side found a terminator and extend the other side to the block edge.

### Decision 4: Reuse the existing `is_sentence_boundary` abbreviation logic by extracting it

Currently the abbreviation heuristic lives inline in `dw_anki_export_selection` (word-level pre/post-selection check). We extract it into a module-local helper `is_abbreviation(token)` that both call sites use, ensuring the heuristic stays in sync between sentence-scoping and word-level boundary detection.

### Decision 5: Scan unit is byte, not word

We scan the joined `full_line` byte-by-byte rather than tokenizing first because:

- It preserves the exact char offsets needed downstream by **Precision Offset Mapping** (see `adaptive-context-truncation` spec).
- It correctly handles edge cases like `"raus.\0Es kommt"` where the `.` is at end of one subtitle and the next starts mid-byte after the sentinel.
- It's faster (Lua string operations are O(n) anyway, no allocation).

We use Lua patterns like `[%s%z]` to treat `\0` as whitespace during the look-ahead test.

## Risks / Trade-offs

- **[Risk]** The new abbreviation list may not cover all real-world abbreviations, especially in non-German content. **Mitigation**: heuristic still catches short-lowercase+period; users can extend `anki_abbrev_list` via `mpv.conf` without code changes.

- **[Risk]** A genuinely truncated subtitle (sentence ends mid-line and the next sentence doesn't appear in the ±N window) could produce a longer-than-expected context. **Mitigation**: `anki_context_max_words` (default 40, increased context buffer) truncates the final field as before. Span-padding still applies for wide selections.

- **[Risk]** The "no terminator → full block" fallback could produce very large contexts for unpunctuated streams with many subtitles in the window. **Mitigation**: `anki_context_lines` (small default) bounds the joined block size; `anki_context_max_words` bounds the exported field length.

- **[Trade-off]** We accept that the scan now crosses `\0` sentinels, which means a `.` belonging to a previous-line abbreviation can leak into the look-ahead. **Mitigation**: same abbreviation heuristic applies — `\0` is treated like whitespace for the look-ahead test, but the *token* preceding the `.` is read from the original bytes, so `"ca.\0Plattling"` is still detected as an abbreviation.

- **[Trade-off]** Slightly more complex than the current `\0` scan. Justified by correctness for properly-punctuated subtitles, which is the dominant use case.

- **[Migration]** No backward-incompatible option changes. The new `anki_abbrev_list` has a sensible default; users who didn't set it before get the default; users who want stricter behaviour can extend it. No archived TSV files need to be regenerated — but users who re-export the same selections will get fuller `SentenceSource` strings, which is the desired outcome.
