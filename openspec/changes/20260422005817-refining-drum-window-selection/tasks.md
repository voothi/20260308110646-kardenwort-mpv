## 1. Core Logic Updates

- [x] 1.1 Implement pre-move anchor capture in `cmd_dw_word_move`.
- [x] 1.2 Implement pre-move anchor capture in `cmd_dw_line_move`.
- [x] 1.3 Update logic to treat `Shift` as the primary selection trigger.

## 2. Parameterization

- [x] 2.1 Add `dw_jump_words` and `dw_jump_lines` to `Options` in `lls_core.lua`.
- [x] 2.2 Replace hardcoded jump values with `Options` references in `manage_dw_bindings`.

## 3. Configuration & Documentation

- [x] 3.1 Add `lls-dw_jump_words` and `lls-dw_jump_lines` to `mpv.conf`.
- [x] 3.2 Update arrow key documentation in `input.conf`.
