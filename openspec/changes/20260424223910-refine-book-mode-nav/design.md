## Context
The Drum Window's Book Mode currently suffers from inconsistent scrolling and navigation. While manual navigation (cursor) uses `dw_ensure_visible` correctly, playback navigation and seeking via `a`/`d` have lost their edge-aware logic or are using a simplified version that lacks "paged" scrolling capabilities.

## Goals / Non-Goals

**Goals:**
- Implement a unified `dw_ensure_visible` function that supports both "push" (line-by-line) and "paged" (viewport-flip) scrolling.
- Ensure manual seeking (`a`/`d`) in Book Mode follows "push" scrolling to maintain user orientation.
- Ensure playback in Book Mode follows "paged" scrolling to maximize reading time between viewport shifts.
- Keep the yellow cursor focus visible during manual seeking.

**Non-Goals:**
- Changing the layout rendering logic of the Drum Window.
- Modifying non-Book-Mode scrolling behaviors.

## Decisions

- **Unified Scroll Handler**: Modify `dw_ensure_visible(line_idx, paged)` to accept a `paged` boolean.
  - If `paged` is true: When `line_idx` exceeds `view_max - margin`, set `FSM.DW_VIEW_CENTER` such that `line_idx` becomes `view_min + margin` (flipping the page forward). Similar logic for scrolling up.
  - If `paged` is false: Standard "push" logic that moves `FSM.DW_VIEW_CENTER` just enough to keep `line_idx` within the margin.
- **Repeatable Bindings**: Maintain `a`, `d`, `ф`, `в` as repeatable keys in `manage_dw_bindings` to allow smooth manual scrolling.
- **Cursor Synchronization**: In `cmd_dw_seek_delta`, update `FSM.DW_CURSOR_WORD` to the closest word on the target line instead of `-1`. This ensures the `Options.dw_highlight_color` (Gold) is applied to at least one word, providing visual feedback of the "pointer" location.
- **Configurable Context**: Use `Options.dw_scrolloff` for both header and footer margins.

## Risks / Trade-offs
- **Rapid Seeks**: Repeatable `a`/`d` keys might trigger multiple `mpv` seek commands in quick succession. We rely on `mpv`'s `absolute+exact` seek efficiency and the script's `seek_hold_rate` to prevent lag.
- **Margin Overlap**: If `dw_scrolloff` is set to more than half of `dw_lines_visible`, the logic might cause oscillatory scrolling. We should add a safety clamp in `dw_ensure_visible`.
