## Context

The `draw_search_ui` function in `lls_core.lua` renders the search interface (Ctrl+F) using fixed coordinates and heights. While the project's primary rendering pipeline for subtitles (Drum Window and SRT) has been upgraded to a robust, token-aware wrapping engine, the Search UI remains static. This results in visual overlaps and "bleeding" when search queries or results exceed the horizontal bounds (1200px) and wrap vertically.

## Goals / Non-Goals

**Goals:**
- Implement dynamic vertical sizing for the search input field background based on query length.
- Dynamically offset the results dropdown so it remains anchored to the bottom of the input field.
- Implement token-aware wrapping for search result items to prevent vertical overlap.
- Maintain visual parity with the project's "Consolas" monospace design system.

**Non-Goals:**
- Implementing a persistent layout cache for the search UI (the limited number of items makes real-time calculation feasible).
- Changing the horizontal width (box_w = 1200) of the search interface.

## Decisions

### 1. Reuse `dw_get_str_width` and `wrap_tokens`
We will utilize the existing `dw_get_str_width` and `wrap_tokens` utility functions. This ensures that the search interface's wrapping decisions perfectly match the Drum Window's heuristics, maintaining a unified design language across all interactive modes.

### 2. Layout-First Rendering Pipeline
The current `draw_search_ui` draws the background *before* processing the text content. We will refactor this to:
- Build the `display_query` string.
- Wrap it using `wrap_tokens` to determine `query_lines`.
- Calculate `input_box_h = query_lines * line_height + padding_y * 2`.
- Draw the background and text using these dynamic values.

### 3. Cumulative Dropdown Height
For the search results, we will iterate through the results to be displayed and calculate the number of visual lines for each. The total `results_h` will be the sum of these heights, ensuring the dropdown background perfectly fits the content.

### 4. Truncation and Wrapping Balance
We will maintain the current ~120 character truncation for results to prevent extremely long subtitles from dominating the search view, but we will allow them to wrap within that limit (typically 1-2 lines) instead of forcing them onto a single overlapping line.

## Risks / Trade-offs

- **[Risk]** Deeply nested layout loops impacting UI responsiveness → **[Mitigation]** The search interface is capped at 8 visible results. The computational cost of wrapping 8 short strings is minimal (<1ms) and well within the budget for interactive UI.
- **[Risk]** Overlapping with video content → **[Mitigation]** The search box is anchored at `box_y = 50`. Dynamic height will push content downwards. Since it's a transient HUD, this is acceptable and follows standard UI patterns.
