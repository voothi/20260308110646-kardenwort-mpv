## 1. Core Navigation Utilities

- [ ] 1.1 Extend `dw_closest_word_at_x` with an optional `word_only` parameter.
- [ ] 1.2 Implement filtering logic in `dw_closest_word_at_x` to exclusively target `is_word` tokens when the flag is active.

## 2. Vertical Navigation Implementation

- [ ] 2.1 Refactor `cmd_dw_line_move` to use an idiomatic Lua `for` loop for scanning lines in the movement direction.
- [ ] 2.2 Implement line-skipping logic in the `for` loop to bypass lines that do not contain any valid word tokens.
- [ ] 2.3 Update the vertical landing logic to call `dw_closest_word_at_x` with `word_only = true`.

## 3. Verification

- [ ] 3.1 Verify that UP/DOWN navigation skips over symbolic lines (e.g., lines containing only "..." or "-").
- [ ] 3.2 Verify that LEFT/RIGHT navigation (horizontal) remains character-inclusive and can highlight punctuation.
- [ ] 3.3 Verify that mouse interaction in the Drum Window still allows for surgical selection of individual characters and symbols.
