## 1. Preparation

- [ ] 1.1 Analyze the current `draw_dw_tooltip` loop structure for secondary subtitle rendering.
- [ ] 1.2 Confirm that `dw_get_str_width` accurately handles the character width heuristics for the tooltip's font and size.

## 2. Wrapping Engine Implementation

- [ ] 2.1 Refactor the logical subtitle loop to use `get_sub_tokens` for secondary subtitles.
- [ ] 2.2 Implement a wrapping accumulator that splits tokens into visual lines when the 1400px width limit is reached.
- [ ] 2.3 Ensure visual lines are joined by `\N` and formatted with the correct color and opacity tags.
- [ ] 2.4 Handle unbreakable tokens (>1400px) by allowing overflow and forcing a break immediately after.


## 3. Dynamic Layout & Positioning

- [ ] 3.1 Update the logic to track the total count of *visual lines* (wrapped) across all logical entries.
- [ ] 3.2 Refactor the `block_height` calculation to sum `(visual_lines * line_height)` plus the inter-subtitle gaps.
- [ ] 3.3 Ensure the `final_y` positioning logic and screen boundary clamping correctly use the updated `block_height`.
- [ ] 3.4 Implement skipping of empty or metadata-only logical subtitles to prevent vertical gap artifacts.


## 4. Cache Hardening & Performance

- [ ] 4.1 Initialize `DW_TOOLTIP_DRAW_CACHE = { target_idx = -1, osd_y = -1, version = -1 }` at module scope (Line 14).
- [ ] 4.2 Update `flush_rendering_caches()` (Line 2154) to clear `dw_tooltip_osd` and reset the cache fields (target_idx/osd_y/version).
- [ ] 4.3 Implement early-return logic in `draw_dw_tooltip` using the draw cache sentinel.

## 5. Final Polish & Testing

- [ ] 5.1 Verify that long translations wrap cleanly without bleeding off the left edge.
- [ ] 5.2 Test "double newline" gap behavior for wrapped subtitles in both `CLICK` and `TOGGLE` modes.
- [ ] 5.3 Confirm that `\an6` right-alignment is preserved across all visual lines in the tooltip.
- [ ] 5.4 Stress test with extremely long text to verify vertical boundary clamping and "active line" visibility.

