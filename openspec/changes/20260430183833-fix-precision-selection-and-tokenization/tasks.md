## 1. Tokenization Refinement

- [x] 1.1 Update `is_word_char` in `lls_core.lua` to only include alphanumeric characters and apostrophes.
- [x] 1.2 Verify that brackets, slashes, and hyphens are now emitted as separate tokens.

## 2. Navigation Logic

- [x] 2.1 Update `cmd_dw_word_move` to allow landing on ALL tokens (words and symbols) by default.
- [x] 2.2 Ensure navigation logic skips pure whitespace tokens (`^%s*$`) in all modes.
- [x] 2.3 Verify `cmd_dw_line_move` and `dw_closest_word_at_x` correctly handle the new token boundaries.

## 3. Rendering Engine Cleanup

- [x] 3.1 Remove the `get_global_neighbor` and `apply_global_semantic_pass` functions from `lls_core.lua`.
- [x] 3.2 Remove all calls to `apply_global_semantic_pass` in `draw_dw` and `draw_drum`.
- [x] 3.3 Verify that highlighting is now strictly bound to the selected tokens without any bleeding.
