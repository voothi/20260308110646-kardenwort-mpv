## Context

The previous search HUD implementation had hardcoded ASS color and bold tags (`\c&H...&`, `\b1`). This made it difficult for users to adjust the UI for better visibility or to change the theme. This release centralizes these "magic strings" into the `Options` table.

## Goals / Non-Goals

**Goals:**
- Externalize all Search HUD visual parameters.
- Enable user-defined bolding and color schemes.
- Implement a minimalist aesthetic by default.

## Decisions

- **Parameter Mapping**: Six new keys are added to the `Options` table, covering hits and selections in both the result list and the query input field.
- **Template Substitution**: The rendering logic in `draw_search_ui` is updated to construct formatting tags on-the-fly. It builds a `style_prefix` and `style_suffix` based on the current `Options` values.
- **Minimalist Default**: Legacy "markers" (like `>` or custom bullets) are removed in favor of color-based selection, reducing the character count and visual complexity of the OSD.
- **State Logic**: The engine continues to support different styles for the "selected" vs "unselected" result lines, now using the externalized variables for both states.

## Risks / Trade-offs

- **Risk**: Users might set invalid BGR hex codes, causing OSD rendering errors.
- **Mitigation**: The system assumes standard hex strings and defaults to sensible fallback values if the configuration is missing.
