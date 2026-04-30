## 1. Reverting Smart Logic (lls_core.lua)

- [x] 1.1 Remove lookahead logic from `prepare_export_text` (`RANGE` mode).
- [x] 1.2 Remove lookahead logic from `prepare_export_text` (`SET` mode).
- [x] 1.3 Remove selection-aware bracket detection from `prepare_export_text`.
- [x] 1.4 Remove balanced-bracket stripping (`%b[]` etc.) from `clean_anki_term`.
- [x] 1.5 Revert `calculate_highlight_stack` to early-exit for non-word tokens (remove semantic bridge).

## 2. Verification & Validation

- [x] 2.1 Verify Anki export is strictly verbatim (exactly what is selected).
- [x] 2.2 Verify bracketed phrases are no longer automatically cleaned.
- [x] 2.3 Verify Drum Window highlights are strictly word-based (uncolored punctuation).
