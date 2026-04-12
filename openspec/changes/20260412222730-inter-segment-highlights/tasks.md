## 1. Core Logic Update

- [x] 1.1 Update `calculate_highlight_stack` signature to accept `subs` table and `idx`
- [x] 1.2 Implement `get_word_at_relative_index` helper to peek into adjacent subs
- [x] 1.3 Update the sequence matching loop to use the lookahead helper
- [x] 1.4 Implement temporal adjacency check (increased to 1.5s gap)
- [x] 1.5 Implement Deep Peeking (recursive/loop jumping across 5 segments)
- [x] 1.6 Implement Adaptive Temporal Window for long paragraphs
- [x] 1.7 Implement Self-Verification fallback for neighbors

## 2. Rendering Integration

- [x] 2.1 Update `format_sub` (Drum Mode) to pass current `subs` context
- [x] 2.2 Update `draw_dw` (Drum Window) to pass the `subs` table

## 3. Verification

- [x] 3.1 Verify that "falsch sind" highlights correctly in the user's news broadcast
- [x] 3.2 Verify that "Antwortbogen." (isolated) still highlights correctly
- [x] 3.3 Ensure no regressions in "Sie" (precision check)
