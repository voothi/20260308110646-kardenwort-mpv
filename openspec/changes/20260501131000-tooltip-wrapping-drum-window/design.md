## Context

The Drum Window (DW) tooltip in `lls_core.lua` provides a context-aware view of translated (secondary) subtitles. While primary subtitles in Drum Mode use a sophisticated layout engine to handle long lines, the tooltip currently concatenates raw text, leading to overflows when translations are long.

## Goals / Non-Goals

**Goals:**
- Implement word-wrapping for secondary subtitles in the DW tooltip.
- Ensure the tooltip remains vertically centered and clamped to the screen boundaries.
- Maintain visual parity with the primary subtitle wrapping heuristic.

**Non-Goals:**
- Implementing a full layout cache for the tooltip (heuristics are fast enough for the small line count).
- Changing the primary subtitle wrapping logic.

## Decisions

### 1. Reuse `dw_get_str_width` Heuristic
We will use the existing `dw_get_str_width(str, fs, font_name)` utility. This ensures that wrapping decisions in the tooltip perfectly match the main window's behavior without the overhead of real-time OSD measurement calls.

### 2. Token-Based Wrapping Engine
We will utilize `get_sub_tokens(sub, true)` to retrieve rich tokens. The wrapping logic will:
- Iterate through tokens.
- Calculate cumulative width.
- Insert soft-wrap markers (`\N`) when `max_text_w` is exceeded.
- Group tokens into visual lines.

### 3. Maximum Width Configuration
We will use a fixed `max_text_w = 1400` for the tooltip. Since the tooltip is anchored at `x=1800` (`\an6`), this ensures the text stays within screen bounds (leaving 400px margin on the left) while providing enough horizontal space for complex translations.

### 4. Recursive Height Calculation
The `block_height` calculation in `draw_dw_tooltip` will be updated to sum the heights of all *visual* lines across all logical subtitle blocks. This ensures that the vertical centering (`final_y`) and clamping logic correctly accounts for multi-line subtitles.

### 5. Performance Caching (DW_TOOLTIP_DRAW_CACHE)
To prevent redundant $O(N)$ layout evaluations during high-frequency mouse movement, we will implement a result cache for the tooltip. The rendering logic will return early if `target_line_idx`, `osd_y`, and `FSM.LAYOUT_VERSION` are identical to the previous call.

### 6. Centralized Cache Invalidation
The `draw_dw_tooltip` state and OSD overlay will be integrated into the global `flush_rendering_caches()` mechanism. This ensures that track reloads, option updates, or TSV refreshes immediately clear any pinned or forced tooltips, maintaining architectural consistency with the `v1.58.0` hardening.

### 7. Alignment and Boundary Constraints
- **Horizontal Anchor**: The tooltip is fixed at `x=1800` with `\an6` (Right Center). Wrapped lines MUST maintain right-alignment within the block.
- **Max Width Safety**: A hard limit of `1400px` ensures a minimum `120px` right-margin and `400px` left-margin on standard 1080p displays.
- **Overflow Handling**: Single tokens exceeding the maximum width SHALL be rendered in full, with wrapping occurring immediately after the oversized token.

## Risks / Trade-offs

- **[Risk]** Tooltip height exceeding screen resolution → **[Mitigation]** The centering logic will use the sum of visual lines for `block_height`, and the existing clamping logic will anchor the block to the screen edges if it exceeds available vertical space.
- **[Risk]** Stale tooltip state after track reload → **[Mitigation]** Explicit integration with `flush_rendering_caches()` to reset OSD and cache sentinels.
- **[Risk]** Increased CPU usage on mouse-move → **[Mitigation]** Implementation of `DW_TOOLTIP_DRAW_CACHE` to bypass rendering when the cursor remains focused on the same subtitle line.
