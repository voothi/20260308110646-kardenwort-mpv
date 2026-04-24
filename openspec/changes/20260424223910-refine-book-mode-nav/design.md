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
  - If `paged` is true (Playback): When `line_idx` exceeds `view_max - margin`, set `FSM.DW_VIEW_CENTER` such that `line_idx` becomes `view_min + margin` (flipping the page forward so the active line is near the TOP).
  - If `paged` is false (Manual): Standard "push" logic that moves `FSM.DW_VIEW_CENTER` incrementally to keep `line_idx` within the margin.
- **Pointer Independence (Book Mode)**: Decouple the manual seek (`a`/`d`) from the yellow cursor. Manual seeking moves the video and "white pointer" while the yellow cursor stays stationary at its last manual position.
- **Selection Persistence (Regular Mode)**: In Regular Mode (Book Mode OFF), the yellow cursor follows the player focus but resets the word focus (`DW_CURSOR_WORD = -1`) when the subtitle changes automatically, matching the behavior of commit `d264b61`.
- **Virtual Seek Target**: Implement `FSM.DW_SEEK_TARGET` to track manual seek position independently of the video engine's current state, ensuring smooth and responsive navigation under load.
- **Repeatable Bindings**: Use script-level timers (`cmd_seek_with_repeat`) for high-performance key repeats, ensuring no conflict with `mpv`'s native repeat logic.

## Risks / Trade-offs
- **View Oscillations**: If `dw_scrolloff` is set too high for the current window size, the logic could trigger rapid scrolling. We've added a safety clamp in `dw_ensure_visible` to prevent this.
- **Decoupling Confusion**: Users might expect the yellow cursor to follow `a`/`d` in Book Mode. However, we've prioritized "Editor Mode" independence to allow users to hold a word focus while flipping through the context.
