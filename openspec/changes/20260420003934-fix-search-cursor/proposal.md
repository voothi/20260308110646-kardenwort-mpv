## Why

The current search field placeholder "Search...|" places the cursor at the end of the text, which is non-standard for input fields. Moving the cursor to the beginning (|Search...) provides a more logical and familiar user interface, clearly indicating the insertion point for the search query and eliminating the "hanging in the air" visual disconnect at the end of the field.

## What Changes

- Reposition the search field cursor symbol (`|`) from the end of the "Search..." placeholder to the beginning.
- Maintain visual hierarchy where the active cursor is fully opaque while the informational "Search..." text is dimmed.

## Capabilities

### New Capabilities
- `search-system`: Core interface and behavior for the global subtitle search functionality, including input handling and results rendering.

### Modified Capabilities
- `fsm-architecture`: Update the Modal Interface requirements to reference the specific UI behavior defined in the `search-system` spec.

## Impact

- **Scripts**: `scripts/lls_core.lua` will be modified in the `draw_search_ui` function.
- **User Interface**: The Empty search state will now show `|Search...` instead of `Search...|`.
