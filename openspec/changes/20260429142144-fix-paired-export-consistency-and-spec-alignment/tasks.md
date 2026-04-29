# Implementation Tasks: Export Consistency and Spec Alignment

## 1. Specification Alignment

- [ ] 1.1 Update `anki-highlighting/spec.md` requirements 13 and 14 via the delta to formalize subtitle-boundary context extraction.

## 2. Code Implementation: Punctuation Parity

- [ ] 2.1 Refactor `ctrl_commit_set` in `scripts/lls_core.lua` to include phrase-based punctuation restoration.
- [ ] 2.2 Implement `raw_had_terminal` detection within the `ctrl_commit_set` token loop by checking the source text of the final selected word.
- [ ] 2.3 Add conditional check: if `is_sentence_boundary` and `raw_had_terminal` and `starts_with_uppercase(term)` and `term:find(" ")`, then append `.`.
- [ ] 2.4 Verify that restoration logic does not conflict with existing terminal punctuation in the term (using `not term:match("[.!?]$")`).

## 3. Verification and Audit

- [ ] 3.1 Perform a side-by-side export test: export a sentence-like phrase using a Yellow drag-selection, then export the same words using a Pink paired selection.
- [ ] 3.2 Verify that both exports result in identical `source_word` field content (specifically regarding the terminal period).
- [ ] 3.3 Conduct a final sanity check of `compose_term_smart` to ensure no regression in hyphen/bracket handling.
