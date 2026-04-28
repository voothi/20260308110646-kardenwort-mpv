## Why

German abbreviations like `ca.`, `z.B.`, `usw.`, `T.CON` end with a period, causing `extract_anki_context` to treat them as sentence terminators and falsely trim the exported Anki context. Since the data is subtitle-structured (each subtitle entry is already a coherent text unit), sentence boundaries should be derived from subtitle line edges — not from period characters within a line.

## What Changes

- **Remove in-line period scanning** from `extract_anki_context`: the backwards `%s+[.!?]` scan that finds "sentence start" within the joined context block will be eliminated.
- **Introduce subtitle-boundary-aware context building**: instead of joining subtitle texts with spaces and losing boundary information, the context passed to `extract_anki_context` will carry subtitle line demarcators so the function knows where one subtitle ends and the next begins.
- **Fix `is_sentence_boundary` detection** in `dw_anki_export_selection`: the word-level check `prev_text:match("[.!?]$")` fires on abbreviation-ending tokens; it will be guarded by an abbreviation heuristic (short lowercase token + period, or single-letter+period pattern).
- The primary sentence for context extraction will be the subtitle line(s) directly containing the selection — neighboring lines used only for word-count padding, not sentence splitting.

## Capabilities

### New Capabilities

- `subtitle-aware-sentence-extraction`: Sentence scoping in `extract_anki_context` uses subtitle line boundaries (passed as a sentinel-delimited string or structured table) instead of scanning for period characters, eliminating false splits on abbreviations.

### Modified Capabilities

- `adaptive-context-truncation`: The sentence-extraction phase (step 1 of `extract_anki_context`) changes its boundary-detection strategy. Word-count truncation and span-padding logic (requirements 1, 3, 4) remain unchanged; only the sentence-scoping heuristic is replaced.

## Impact

- `scripts/lls_core.lua` — `extract_anki_context` function (lines ~1729-1761) and the two `is_sentence_boundary` detection blocks in `dw_anki_export_selection` (lines ~3649-3663, ~3689).
- No changes to TSV schema, Anki field mapping, or any options keys.
- No breaking changes to existing `mpv.conf` / `lls.conf` parameters.
