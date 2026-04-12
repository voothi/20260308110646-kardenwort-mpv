## 1. Core Logic Update

- [x] 1.1 Update `calculate_highlight_stack` signature to accept `subs` table and `idx`
- [x] 1.2 Implement `get_word_at_relative_index` helper to peek into adjacent subs
- [x] 1.3 Update the sequence matching loop to use the lookahead helper
- [x] 1.4 Implement temporal adjacency check (500ms max gap)

## 2. Rendering Integration

- [x] 2.1 Update `format_sub` (Drum Mode) to pass current `subs` context
- [x] 2.2 Update `draw_dw` (Drum Window) to pass the `subs` table

## 3. Verification

- [ ] 3.1 Verify that "falsch sind" highlights correctly in the user's news broadcast
- [ ] 3.2 Verify that "Antwortbogen." (isolated) still highlights correctly
- [ ] 3.3 Ensure no regressions in "Sie" (precision check)
