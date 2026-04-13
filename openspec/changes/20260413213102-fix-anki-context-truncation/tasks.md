## 1. Context Extraction Refactor

- [x] 1.1 Shift forward search index in `extract_anki_context` from `start_pos` to `end_pos`.
- [x] 1.2 Verify that the `post:find` punctuation logic still correctly handles single-char matches at the new index.

## 2. Adaptive Truncation Implementation

- [x] 2.1 Calculate `selection_word_count` inside `extract_anki_context`.
- [x] 2.2 Re-calculate the effective `anki_context_max_words` limit: `MAX(Options.anki_context_max_words, selection_word_count + 20)`.
- [x] 2.3 Pass this effective limit into the truncation logic in `extract_anki_context`.

## 3. Configuration & Defaults

- [x] 3.1 Increase default `anki_context_max_words` in `Options` table to `40`.
- [x] 3.2 Add maintenance comment explaining adaptive truncation behavior.

## 4. Validation

- [ ] 4.1 Test a selection spanning two sentences to ensure both are captured.
- [ ] 4.2 Test a very long selection (> 40 words) to ensure the 20-word buffer is still applied beyond the selection.
