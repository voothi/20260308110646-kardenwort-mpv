## Why

This change formalizes the Externalized Search HUD Styling introduced in Release v1.2.62. To improve the customizability and maintainability of the Search HUD, it was necessary to decouple its visual parameters (colors, bolding) from the core rendering logic. This update introduces an "ultra-minimalist" aesthetic while providing users with the architectural hooks to precisely tune the search interface through standard configuration mechanisms.

## What Changes

- Introduction of **Configurable Styling Parameters**: Added six new options to the `Options` table to control search hit colors, selection styles, and query field aesthetics.
- Implementation of **Variable-Driven Rendering**: The `draw_search_ui` function has been refactored to substitute hardcoded ASS tags with dynamic, user-configurable formatting strings.
- Refinement of the **Ultra-Minimalist Aesthetic**: Removal of legacy markers and redundant UI elements to create a cleaner search interface.
- Integration of state-sensitive highlighting that correctly handles contrast between selected and unselected search entries.

## Capabilities

### New Capabilities
- `externalized-ui-styling`: A configuration pattern that allows for deep UI customization through external parameter files (`mpv.conf`) without Lua source changes.
- `variable-driven-rendering`: A rendering strategy that uses template strings and variable substitution to generate complex ASS-tagged OSD content.

### Modified Capabilities
- `universal-subtitle-search`: Upgraded with advanced styling controls and a minimalist visual theme.

## Impact

- **Customizability**: Users can now match the Search HUD's appearance to their personal preferences or monitor profiles.
- **Maintainability**: Future UI updates can be made by simply adjusting configuration defaults rather than modifying complex OSD string concatenation logic.
- **Visual Clarity**: The minimalist theme reduces visual noise, allowing users to focus entirely on search results during immersion.
