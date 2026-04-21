## 1. State and Helper Infrastructure

- [x] 1.1 Add `DW_CURSOR_X` to FSM state block in `lls_core.lua`
- [x] 1.2 Implement `dw_compute_word_center_x(sub)` helper to calculate pixel-center of a word
- [x] 1.3 Implement `dw_closest_word_at_x(sub, target_x)` helper to resolve word index from horizontal position

## 2. Navigation Logic Updates

- [x] 2.1 Modify `cmd_dw_line_move` to capture/reuse sticky horizontal position during vertical movement
- [x] 2.2 Modify `cmd_dw_word_move` to update sticky horizontal position after horizontal movement

## 3. Interaction Hardening and Resets

- [x] 3.1 Implement sticky position reset in `cmd_dw_esc`
- [x] 3.2 Implement sticky position reset in track change and media state flush logic
- [x] 3.3 Implement sticky position reset in mouse click/seek handler
- [x] 3.4 Implement sticky position reset in search navigation and Anki save callbacks
