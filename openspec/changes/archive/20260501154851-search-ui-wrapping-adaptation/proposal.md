## Why

Recent "verbatim-first" and line-wrapping enhancements have introduced a layout regression in the Search UI (Ctrl+F). Long search queries and results now wrap within the fixed-width OSD container, but the background elements and vertical positioning remain static, causing text to bleed out of boxes and overlap neighboring elements. This fix is necessary to maintain the project's "premium design" standards and ensure the search interface remains readable for long queries.

## What Changes

- **Dynamic Input Field Height**: The search input field background will now calculate its height based on the number of visual lines occupied by the query.
- **Adaptive Dropdown Positioning**: The search results dropdown will dynamically shift its Y-position to remain correctly anchored below the (potentially multi-line) input field.
- **Token-Aware Result Wrapping**: Search results will utilize the project's established `wrap_tokens` logic, with the results dropdown adapting its total height and item positioning to accommodate multi-line result entries.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `search-ui-styling`: Updated to require dynamic vertical adaptation for all UI elements to accommodate wrapped content without overlap.

## Impact

- `scripts/lls_core.lua`: Significant refactoring of `draw_search_ui` and its coordinate calculation logic.
- `Options`: No schema changes expected, but styling parameters will be utilized more dynamically.
