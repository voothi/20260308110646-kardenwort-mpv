## 1. Multi-Selection Logic Refactoring

- [ ] 1.1 Update `cmd_dw_copy` in `lls_core.lua` to use the scanner's full token stream (`build_word_list_internal(text, true)`) for range reconstruction.
- [ ] 1.2 Implement the `in_range` state machine loop to collect all intermediate tokens (punctuation/spaces) between logical anchors.
- [ ] 1.3 Sync `dw_anki_export_selection` to use the same high-fidelity token extraction logic for the `term` field.

## 2. Validation and Regression Testing

- [ ] 2.1 Verify that multi-word selections (e.g., "Hören, ob") preserve commas and original segment spacing in the clipboard.
- [ ] 2.2 Ensure that single-word selections still follow the "clean boundary" rule (trailing punctuation stripped).
- [ ] 2.3 Confirm that Anki export terms match the verbatim text exactly, enabling reliable grounding in the context extractor.
