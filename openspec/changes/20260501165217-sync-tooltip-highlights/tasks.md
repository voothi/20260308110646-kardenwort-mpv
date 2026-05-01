## 1. Refactor Tooltip Rendering

- [ ] 1.1 In `draw_dw_tooltip`, call `populate_token_meta(Tracks.sec.subs, i, tokens, color, sub.start_time)` for each line `i`.
- [ ] 1.2 Implement surgical word formatting in the tooltip's visual line construction loop using `format_highlighted_word`.
- [ ] 1.3 Update `DW_TOOLTIP_DRAW_CACHE` to include `FSM.DW_CURSOR_LINE`, `FSM.DW_CURSOR_WORD`, and `FSM.ANKI_VERSION`.

## 2. Verification and Testing

- [ ] 2.1 **Yellow Pointer Sync**: Select a word in the Drum Window, open tooltip for that line. Verify word is yellow in tooltip.
- [ ] 2.2 **Pink Selection Sync**: Add words to the Pink Set (Ctrl+LMB), verify they appear pink in the tooltip.
- [ ] 2.3 **Surgical Precision**: Verify that punctuation around highlighted words in the tooltip remains uncolored.
- [ ] 2.4 **Cache Integrity**: Verify that changing the selection immediately updates the tooltip content without staleness.
