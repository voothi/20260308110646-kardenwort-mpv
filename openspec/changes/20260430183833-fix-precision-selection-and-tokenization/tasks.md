## 1. Tokenization Refinement

- [ ] 1.1 Update `is_word_char` in `lls_core.lua` to only include alphanumeric characters and apostrophes.
- [ ] 1.2 Verify that brackets, slashes, and hyphens are now emitted as separate tokens.

## 2. Navigation Logic

- [ ] 2.1 Update `cmd_dw_word_move` to allow landing on punctuation tokens only when the `shift` parameter is true.
- [ ] 2.2 Ensure navigation logic skips pure whitespace tokens (`^%s*$`) in both word-only and precision modes.
- [ ] 2.3 Verify `cmd_dw_line_move` and `dw_closest_word_at_x` correctly handle the new token boundaries.

## 3. Rendering Engine Cleanup

- [ ] 3.1 Remove the `get_global_neighbor` and `apply_global_semantic_pass` functions from `lls_core.lua`.
- [ ] 3.2 Remove all calls to `apply_global_semantic_pass` in `draw_dw` and `draw_drum`.
- [ ] 3.3 Verify that highlighting is now strictly bound to the selected tokens without any bleeding.
