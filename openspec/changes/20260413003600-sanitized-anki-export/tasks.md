## 1. Core Logic Refined

- [ ] 1.1 Update `calculate_highlight_stack` to bitwise-OR `has_phrase` across all overlapping matches.
- [ ] 1.2 Implement surgical sanitization in `cmd_dw_export_anki` (MBTN_MID handler).

## 2. Verification

- [ ] 2.1 Verify `Middle-Click` on `Umbruch.` saves `Umbruch` to TSV.
- [ ] 2.2 Verify overlapping highlights (`Mal ehrlich,` vs `ehrlich`) preserve the green comma.
- [ ] 2.3 Ensure internal punctuation in phrases is still preserved during capture.
