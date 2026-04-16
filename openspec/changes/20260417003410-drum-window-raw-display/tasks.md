## 1. Scanner Refactoring

- [x] 1.1 Add `dw_original_spacing = true` to the `Options` table in `lls_core.lua`.
- [x] 1.2 Modify `build_word_list` to return rich tokens `{ text = string, is_word = boolean }` instead of raw strings. (Implemented as `build_word_list_internal` with `keep_spaces` flag).
- [x] 1.3 Ensure the scanner pushes whitespace as items with `is_word = false`.
- [x] 1.4 Implement a `get_logical_index_map(tokens)` helper to bridge "Logical Words" (visible) to "Visual Tokens" (all). (Implemented inline in `dw_build_layout`).

## 2. Selection & Highlighting Logic

- [x] 2.1 Update `calculate_highlight_stack` to skip tokens where `is_word` is false. (N/A: Logic remains on logical indices).
- [x] 2.2 Re-calibrate `dw_get_word_at_pos` (hit-testing) to account for filler tokens.
- [x] 2.3 Update keyboard navigation (a/d keys) to ensure `dw_cursor_word` only stops on tokens where `is_word` is true. (Decoupled via `build_word_list` call).

## 3. Display & Composition

- [x] 3.1 Refactor `compose_term_smart` to simply `table.concat` text parts when `dw_original_spacing` is true. (Implemented in `draw_dw` joining loop).
- [x] 3.2 Update `draw_dw` (the render loop) to iterate through the rich token list and only apply color tags to `is_word` tokens.
- [x] 3.3 Ensure that `anki_strip_metadata` logic is applied to the individual tokens correctly.
- [ ] 3.4 Update `draw_drum` (Reel Mode & Standard Mode) to respect `dw_original_spacing`.
- [ ] 3.5 Implement `is_word_token` mapping in `draw_drum` for correct highlighting.
- [ ] 3.6 Refine `compose_term_smart` joining rules for common punctuation across all modes.

## 4. Verification

- [x] 4.1 Verify `z.B.` displays without spaces when `dw_original_spacing = true`.
- [x] 4.2 Verify `Logistiklager (Netto/Globus)` spacing matches the source file.
- [x] 4.3 Ensure `Option: anki_global_highlight` still functions correctly with the new token structure.
- [x] 4.4 Add `script-opts-append=lls-dw_original_spacing=yes` to `mpv.conf`.
