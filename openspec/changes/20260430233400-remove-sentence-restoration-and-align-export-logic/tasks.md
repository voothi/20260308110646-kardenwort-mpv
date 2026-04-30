## 1. Code Refactoring (lls_core.lua)

- [ ] 1.1 Remove `starts_with_uppercase` helper function (deprecated).
- [ ] 1.2 Remove restoration state variables (`raw_had_terminal`, `terminal_punct`, `is_sentence_boundary`) from `prepare_export_text`.
- [ ] 1.3 Remove lookahead logic blocks from `RANGE`, `SET`, and `POINT` branches in `prepare_export_text`.
- [ ] 1.4 Delete the final "Unified Sentence Punctuation Restoration" block (lines 1280-1285).
- [ ] 1.5 Implement "Adaptive Gap Detection" in `SET` mode branch of `prepare_export_text` to support cross-line adjacency.

## 2. Verification & Validation

- [ ] 2.1 Verify `RANGE` mode export is strictly verbatim (no period added if not selected).
- [ ] 2.2 Verify `SET` mode export uses space (not ellipses) for adjacent words across consecutive lines.
- [ ] 2.3 Verify `SET` mode export uses ellipses for logical gaps within or across lines.
- [ ] 2.4 Verify `POINT` mode export no longer includes trailing punctuation lookahead.
