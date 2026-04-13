## 1. Context Extraction Refactor

- [ ] 1.1 Shift forward search index in `extract_anki_context` from `start_pos` to `end_pos` (Line 733).
- [ ] 1.2 Verify that the `post:find` punctuation logic still correctly handles single-char matches at the new index.

## 2. Adaptive Truncation Implementation

- [ ] 2.1 Calculate `selection_word_count` inside `dw_anki_export_selection` or `extract_anki_context`.
- [ ] 2.2 Re-calculate the effective `anki_context_max_words` limit for the current export session: `MAX(Options.anki_context_max_words, selection_word_count + 20)`.
- [ ] 2.3 Pass this effective limit into the truncation logic in `extract_anki_context`.

## 3. Configuration & Defaults

- [ ] 3.1 Increase default `anki_context_max_words` in `Options` table to `40` (Line 109).
- [ ] 3.2 Add a comment in `lls_core.lua` explaining the new adaptive truncation behavior for future maintenance.

## 4. Validation

- [ ] 4.1 Test a selection spanning two sentences to ensure both are captured.
- [ ] 4.2 Test a very long selection (> 40 words) to ensure the 20-word buffer is still applied beyond the selection.
