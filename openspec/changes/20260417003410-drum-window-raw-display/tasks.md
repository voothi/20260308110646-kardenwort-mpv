## 1. Scanner Refactoring

- [ ] 1.1 Add `dw_original_spacing = true` to the `Options` table in `lls_core.lua`.
- [ ] 1.2 Modify `build_word_list` to return rich tokens `{ text = string, is_word = boolean }` instead of raw strings.
- [ ] 1.3 Ensure the scanner pushes whitespace as items with `is_word = false`.
- [ ] 1.4 Implement a `get_logical_index_map(tokens)` helper to bridge "Logical Words" (visible) to "Visual Tokens" (all).

## 2. Selection & Highlighting Logic

- [ ] 2.1 Update `calculate_highlight_stack` to skip tokens where `is_word` is false.
- [ ] 2.2 Re-calibrate `dw_get_word_at_pos` (hit-testing) to account for filler tokens.
- [ ] 2.3 Update keyboard navigation (a/d keys) to ensure `dw_cursor_word` only stops on tokens where `is_word` is true.

## 3. Display & Composition

- [ ] 3.1 Refactor `compose_term_smart` to simply `table.concat` text parts when `dw_original_spacing` is true.
- [ ] 3.2 Update `draw_dw` (the render loop) to iterate through the rich token list and only apply color tags to `is_word` tokens.
- [ ] 3.3 Ensure that `anki_strip_metadata` logic is applied to the individual tokens correctly.

## 4. Verification

- [ ] 4.1 Verify `z.B.` displays without spaces when `dw_original_spacing = true`.
- [ ] 4.2 Verify `Logistiklager (Netto/Globus)` spacing matches the source file.
- [ ] 4.3 Ensure `Option: anki_global_highlight` still functions correctly with the new token structure.
- [ ] 4.4 Add `script-opts-append=lls-dw_original_spacing=yes` to `mpv.conf`.
