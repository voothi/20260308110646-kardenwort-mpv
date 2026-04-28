## Context

The Search HUD in `lls_core.lua` has undergone multiple iterations, leading to a drift in visual alignment and a loss of high-contrast styling preferred by users. The current state requires manual overrides to achieve the "Drum Mode" look where the active selection is distinct from the context.

## Goals / Non-Goals

**Goals:**
- Restore the visually stable layout of commit `0befa9923cae21c33f43c69875de438c9101cf66`.
- Provide granular font size controls for the search interface.
- Ensure the selected result is highly visible while maintaining match highlights.

**Non-Goals:**
- Redesigning the search algorithm itself.
- Adding new search filters or advanced regex capabilities.

## Decisions

### 1. Hardcoded Layout Constants Restoration
To prevent future visual drift, the positioning constants (`box_w`, `box_x`, `box_y`) in `draw_search_ui` are reverted to the hardcoded values from `0befa99`. These values represent the most stable and centered layout configuration.

### 2. Independent Font Scaling Logic
A new logic block is introduced to calculate `r_font_size` (results font size) independently from the main `font_size`. This allows users to set a smaller dropdown size (e.g., `-1` for 80% scale) without affecting the readability of the search input bar.

### 3. Selection Contrast via Color Overrides
Instead of relying on a single text color for the entire dropdown, the rendering loop now dynamically calculates `base_color`. If a result is selected, it forces `base_color` to `search_sel_color` (White). This ensures the "Drum Mode" high-contrast look is always maintained regardless of the search query's match status.

### 4. Hit Highlight Color Priority
To preserve match visibility on the white selected line, the `hit_color` logic is updated to use `search_query_hit_color` (if set) or fall back to `FFFFFF`. This ensures that even on a white line, matches are still distinct (either via color or bolding).

## Risks / Trade-offs

- **Risk**: Hardcoding constants makes the UI less "responsive" to different resolutions.
  - **Mitigation**: These constants are designed for 1920x1080 and scale reasonably well in mpv's ASS coordinate system.
- **Risk**: Multiple color tags in a single line might increase ASS processing overhead.
  - **Mitigation**: The search result list is limited to 8 items, so the impact is negligible.
