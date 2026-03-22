# Design: Hide Pointer After Search Selection

## Architecture
The search selection logic is integrated into the `manage_search_bindings` function in `lls_core.lua`. It handles both keyboard (`ENTER`) and mouse (`MBTN_LEFT`) selection events.

## Technical Implementation
The fix involves updating two locations in `lls_core.lua`:

1.  **Keyboard Selection**: Inside the `ENTER` binding for search, change `FSM.DW_CURSOR_WORD = 1` to `FSM.DW_CURSOR_WORD = -1`.
2.  **Mouse Selection**: Inside the `search_mouse_click` function, where the selection is confirmed, change `FSM.DW_CURSOR_WORD = 1` to `FSM.DW_CURSOR_WORD = -1`.

## Impact Assessment
-   **lls_core.lua**: Minimal change, only two assignments.
-   **Functionality**: Users will see the Drum Window jump to the correct line, but no word will be highlighted until they press an arrow key.
