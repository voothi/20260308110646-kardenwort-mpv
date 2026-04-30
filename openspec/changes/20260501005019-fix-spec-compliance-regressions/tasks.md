## 1. Refactoring lls_core.lua

- [x] 1.1 Restore minimal lookahead logic in `prepare_export_text` for `RANGE` mode to capture bonded terminal punctuation.
- [x] 1.2 Restore minimal lookahead logic in `prepare_export_text` for `SET` mode to capture bonded terminal punctuation.
- [x] 1.3 Update `clean_anki_term` to support a `bypass_bracket_strip` parameter.
- [x] 1.4 Update `prepare_export_text` callers to detect explicit bracket selection and trigger `bypass_bracket_strip`.
- [x] 1.5 Modify `calculate_highlight_stack` to remove the `target_token.is_word` early-exit.
- [x] 1.6 Implement whitespace-blind neighbor search in `calculate_highlight_stack` for punctuation highlighting.

## 2. Verification & Validation

- [x] 2.1 Verify multi-line range selection includes bonded terminal punctuation (e.g., periods, parentheses).
- [x] 2.2 Verify bracketed words (e.g., `[Musik]`) are preserved in export when brackets are explicitly selected.
- [x] 2.3 Verify punctuation marks in Drum Window inherit highlight colors from their semantic neighbors.
- [x] 2.4 Verify single-word MMB clicks still perform "professional" bracket stripping when brackets are NOT selected.
