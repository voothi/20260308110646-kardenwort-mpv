## 1. Unified Export Engine Consolidation

- [ ] 1.1 Relocate scope-critical constants (`L_EPSILON`) and comparison helpers (`logical_cmp`, `is_word_token`) to the top of the logic section in `lls_core.lua`.
- [ ] 1.2 Refactor `prepare_export_text` to support `SET` mode with token-lookbehind for adjacent members.
- [ ] 1.3 Centralize terminal punctuation restoration logic (`[.!?]`) into the core export engine.
- [ ] 1.4 Update `dw_anki_export_selection`, `ctrl_commit_set`, and `cmd_dw_copy` to utilize the unified `prepare_export_text` service.

## 2. Keyboard Selection Granularity Enhancement

- [ ] 2.1 Update `cmd_dw_word_move` to implement Shift-aware navigation using the full internal token list.
- [ ] 2.2 Implement fractional logical index support in `dw_compute_word_center_x` using epsilon-aware comparison.
- [ ] 2.3 Update `draw_dw` rendering pass to correctly highlight symbols (fractional logical indices) during selection focus.
