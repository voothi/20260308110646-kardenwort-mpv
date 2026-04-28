## Why

The Search UI styling regressed in recent versions, losing the preferred layout and high-contrast visuals of commit `0befa9923cae21c33f43c69875de438c9101cf66`. This change restores the original baseline aesthetics while introducing modern enhancements like independent font scaling for the results menu to better align with the "Drum Mode" visual hierarchy.

## What Changes

- **Layout Restoration**: Reverts search window positioning and box logic to the `0befa99` baseline.
- **Independent Font Scaling**: Adds `search_results_font_size` to allow the dropdown results to be scaled separately from the main search bar (e.g., 80% size vs 100% size).
- **Selection Highlighting**: Updates rendering logic to ensure the active search result is rendered in high-contrast bright white (`FFFFFF`) while maintaining colored hits for search queries.
- **Configuration Synchronization**: Maps internal search styling parameters to the `Options` table, enabling persistent user customization via `mpv.conf`.

## Capabilities

### New Capabilities
- `search-ui-styling`: Comprehensive styling and scaling controls for the search interface.

### Modified Capabilities
- None

## Impact

- `scripts/lls_core.lua`: Modified `draw_search_ui` and `Options` schema.
- `mpv.conf`: New `lls-search_results_font_size` parameter and updated defaults.
