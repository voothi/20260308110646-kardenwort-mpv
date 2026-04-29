## 1. Core Engine Implementation

- [ ] 1.1 Implement `prepare_export_text` helper in `lls_core.lua` that handles Range, Set, and Point selections with verbatim token joining.
- [ ] 1.2 Implement strict boundary checks using `logical_idx` comparison to support symbol-level precision.
- [ ] 1.3 Add support for ` ... ` elliptical joiners in `prepare_export_text` for non-contiguous (Pink) sets.

## 2. Cleaning Logic Refactor

- [ ] 2.1 Update `clean_anki_term` to remove aggressive leading/trailing punctuation stripping.
- [ ] 2.2 Ensure `clean_anki_term` still handles ASS tag removal and space normalization.
- [ ] 2.3 Ensure terminal sentence punctuation restoration is preserved in the unified path.

## 3. Call Site Integration (Clipboard)

- [ ] 3.1 Refactor `cmd_dw_copy` to use `prepare_export_text` for verbatim selection copy.
- [ ] 3.2 Refactor `cmd_copy_sub` to use `prepare_export_text` (with Russian filter support).

## 4. Call Site Integration (TSV Export)

- [ ] 4.1 Refactor `dw_anki_export_selection` to use `prepare_export_text` for contiguous selection mining.
- [ ] 4.2 Refactor `ctrl_commit_set` to use `prepare_export_text` for paired selection mining.

## 5. Verification

- [ ] 5.1 Verify that mouse selection of punctuation/symbols is preserved in the clipboard.
- [ ] 5.2 Verify that Anki exports correctly capture bracketed terms if explicitly selected.
- [ ] 5.3 Verify that "smart" spacing does not regress OSD display but is correctly bypassed for exports.
