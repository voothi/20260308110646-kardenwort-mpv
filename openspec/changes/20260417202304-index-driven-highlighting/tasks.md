## 1. Tokenizer Refactoring

- [ ] 1.1 Update `build_word_list_internal` in `lls_core.lua` to generate and return a Rich Token table (`{text, is_word, logical_idx, visual_idx}`).
- [ ] 1.2 Implement a caching mechanism in `load_sub` (or an on-demand cache in the getter) so subtitles are tokenized exactly once and stored in `sub.tokens`.

## 2. Rendering Engine Overhaul

- [ ] 2.1 Refactor `format_sub` (Drum Mode) to iterate over `sub.tokens` instead of calling `build_word_list_internal` locally.
- [ ] 2.2 Refactor `draw_dw` (Drum Window) to utilize the pre-calculated `visual_to_logical` properties directly from the cached token objects.
- [ ] 2.3 Remove legacy regex-based punctuation stripping from the rendering loops, delegating token isolation entirely to the scanner.

## 3. Highlighting Logic Update

- [ ] 3.1 Rewrite `calculate_highlight_stack` to evaluate the token array. Remove `string.find` calls used for sequence matching.
- [ ] 3.2 Update the split-term (purple) matching logic to identify discrete `logical_idx` targets within the block rather than performing substring proximity checks.
- [ ] 3.3 Enforce strict temporal window checks (`anki_local_fuzzy_window`) against the exact mapped indices, removing the loose `[-15, +15]` contextual pre-filter.

## 4. Verification

- [ ] 4.1 Verify that contiguous phrases (orange) highlight accurately without bleeding into identical phrases elsewhere in the timeline when Global Mode is OFF.
- [ ] 4.2 Verify that split-verbs (purple) highlight accurately using their distinct logical indices.
- [ ] 4.3 Verify that selection coordinates (Shift+Arrows, Mouse Drag) map correctly to the new token stream structure.
