## 1. Context Extraction Refactor

- [x] 1.1 Shift forward search index in `extract_anki_context` from `start_pos` to `end_pos` (Line 733).
- [x] 1.2 Verify that the `post:find` punctuation logic still correctly handles single-char matches at the new index.

## 2. Adaptive Truncation Implementation

- [x] 2.1 Calculate `selection_word_count` inside `dw_anki_export_selection` or `extract_anki_context`.
- [x] 2.2 Re-calculate the effective `anki_context_max_words` limit for the current export session: `MAX(Options.anki_context_max_words, selection_word_count + 20)`.
- [x] 2.3 Pass this effective limit into the truncation logic in `extract_anki_context`.

## 3. Configuration & Defaults

- [x] 3.1 Increase default `anki_context_max_words` in `Options` table to `40` (Line 109).
- [x] 3.2 Add a comment in `lls_core.lua` explaining the new adaptive truncation behavior for future maintenance.
- [x] 3.3 Increase `anki_context_lines` from 3 to 6 to handle long sentence spans.
- [x] 3.4 Update `mpv.conf` with new defaults to prevent local override of script improvements.
- [x] 3.5 Refactor `context_line` assembly in `dw_anki_export_selection` to use `build_word_list` for consistent normalization.

## 4. Metadata Tag Filtering
- [x] 4.1 Strip bracketed metadata tags (e.g., `[musik]`) from both term and context in `lls_core.lua`.
- [x] 4.2 Ensure sentence boundary detection treats remaining punctuation correctly after stripping.

## 5. Final Verification

- [ ] 5.1 Verify total coverage of multi-sentence selections in the TSV (no trailing truncation if word count < limit).
- [ ] 5.2 Verify that punctuation INSIDE the selection does not trigger early forward-search termination.
- [x] 5.3 Verify that `[musik]` and similar tags are removed from exported Anki cards.
