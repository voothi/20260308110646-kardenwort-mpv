## Why

When a multi-line selection ends at the last **word** of a subtitle that is immediately followed by closing punctuation (e.g. `)`), that punctuation is excluded from the exported phrase because the selection boundary is word-index-based and punctuation tokens carry only fractional indices. In the concrete case `(Gersdorf/Straubing-Ost)`, the selection records words 1–3 of the subtitle (`[UMGEBUNG]`, `Sport-Thieme`, `Ost`), but the closing `)` is a fractional-index punctuation token that lives *after* word 3 — so it is silently dropped from the phrase field while appearing correctly in the context (SentenceSource) field, which reads raw subtitle text.

## What Changes

- **Phrase trailing-punctuation capture**: After the selection boundary loop collects all tokens up to `p2_w`, the phrase-building pass will continue to consume any immediately-following non-word (punctuation/space) tokens that are attached (no intervening word) to the last selected word on the final subtitle line. This prevents the `)` from being orphaned.
- **Scope is local and line-final only**: The fix applies only on the last subtitle line of the selection (`is_last_line == true`) and only to tokens whose `logical_idx` is fractional (between `p2_w` and `p2_w + 1`). Middle lines are unaffected.
- **No change to context extraction**: `extract_anki_context` already uses raw subtitle text and is correct; it remains untouched.
- **No new parameters needed**: The fix is purely internal to the token loop in `dw_anki_export_selection`.

## Capabilities

### New Capabilities
- `phrase-trailing-punctuation`: The phrase field of a TSV export SHALL include closing punctuation tokens (e.g. `)`, `.`, `]`) that are directly attached — with no intervening word — to the last selected word on the final subtitle line of a multi-line selection.

### Modified Capabilities
- `multi-line-substring-selection`: The existing requirement that phrase boundaries are word-index-based is extended: after the last word boundary on the final line, trailing fractional-index tokens SHALL be included until the next word token is encountered.
- `tsv-export-formatting`: The phrase field (WordSourceInflectedForm) requirement is tightened to guarantee that syntactically-bonded closing punctuation is not silently dropped.

## Impact

- `lls_core.lua` — `dw_anki_export_selection()`, the token iteration loop (lines ~3600–3621).
- No impact on paired-mode (`ctrl_commit_set`), context extraction, highlighting, or indexing logic.
- No new options in `mpv.conf`.
