## 1. Highlighting Engine Refactoring

- [ ] 1.1 Enhance `calculate_highlight_stack` with strict $(time, index)$ grounding for contiguous (Orange) highlights.
- [ ] 1.2 Implement the `check_l`/`check_s` traceback loop for multi-subtitle phrase verification.
- [ ] 1.3 Update Global/Local logic to reject non-anchored matches when `anki_global_highlight` is disabled.
- [ ] 1.4 Add 0.05s timestamp tolerance to account for floating point jitter in subtitle start times.

## 2. Validation and Regression Testing

- [ ] 2.1 Verify that identical phrases in distant subtitles do not highlight when Global mode is OFF.
- [ ] 2.2 Confirm that multi-line highlights spanning segment boundaries still function correctly under strict grounding.
- [ ] 2.3 Ensure "Anki Global ON" mode still allows high-recall context-based highlights as expected.
