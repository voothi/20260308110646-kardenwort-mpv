## 1. Preparation

- [ ] 1.1 Analyze the current `draw_dw_tooltip` loop structure for secondary subtitle rendering.
- [ ] 1.2 Confirm that `dw_get_str_width` accurately handles the character width heuristics for the tooltip's font and size.

## 2. Wrapping Engine Implementation

- [ ] 2.1 Refactor the logical subtitle loop to use `get_sub_tokens` for secondary subtitles.
- [ ] 2.2 Implement a wrapping accumulator that splits tokens into visual lines when the 1400px width limit is reached.
- [ ] 2.3 Ensure visual lines are joined by `\N` and formatted with the correct color and opacity tags.

## 3. Dynamic Layout & Positioning

- [ ] 3.1 Update the `num_lines` and `visual_lines` calculation to accurately reflect the total count of wrapped lines.
- [ ] 3.2 Refactor the `block_height` calculation to sum the heights of every visual line plus inter-subtitle gaps.
- [ ] 3.3 Ensure the `final_y` positioning logic and screen boundary clamping correctly use the updated `block_height`.

## 4. Cache Hardening & Performance

- [ ] 4.1 Define `DW_TOOLTIP_DRAW_CACHE` and implement result caching in `draw_dw_tooltip`.
- [ ] 4.2 Update `flush_rendering_caches()` to clear `dw_tooltip_osd` and reset cache sentinels.
- [ ] 4.3 Verify that `FSM.LAYOUT_VERSION` is respected as a cache invalidation sentinel.

## 5. Final Polish & Testing

- [ ] 5.1 Verify that long translations wrap cleanly without bleeding off the left edge.
- [ ] 5.2 Test "double newline" gap behavior when subtitles are wrapped.
- [ ] 5.3 Confirm that right-center alignment (`\an6`) is preserved across all visual lines.
