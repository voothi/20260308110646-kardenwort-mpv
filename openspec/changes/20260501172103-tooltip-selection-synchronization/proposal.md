# Proposal: Tooltip Selection Synchronization

## Problem
In **Window Mode (W)**, the Drum Window provides a translation tooltip (E) for the currently focused or active line. While this tooltip displays the secondary subtitle (e.g., Russian), it currently lacks mouse interactivity. Unlike **Drum Mode (Mode C)**, where clicking secondary subtitles synchronizes the selection with the main primary text, the Window Mode tooltip is a display-only element. Users want to be able to click or select text in the tooltip and have that selection reflected in the main Drum Window, providing consistent visual parity across all viewing modes.

## Objective
Implement a high-performance hit-testing engine for the Drum Window translation tooltip that enables word-level selection and synchronizes the selection state with the primary Drum Window.

## What Changes
- **Rendering Pipeline**: The `draw_dw_tooltip` function in `lls_core.lua` will be updated to calculate and store hit zones for every rendered word.
- **Hit Detection**: A new `dw_tooltip_hit_test` function will be introduced to handle mouse coordinate mapping for the tooltip's right-aligned (`an6`) layout.
- **Interaction Dispatcher**: `lls_hit_test_all` will be expanded to include the tooltip area in its interaction checks.
- **State Management**: Clicking a word in the tooltip will update the global `FSM.DW_CURSOR_LINE` and `FSM.DW_CURSOR_WORD` state, triggering a reactive update in the main Drum Window.

## Capabilities

### Modified Capabilities
- `drum-window`: Extending interaction support to the translation tooltip.

## Impact
- **lls_core.lua**: Core rendering and mouse handler functions.
- **Performance**: Maintaining O(1) rendering performance via the `DW_TOOLTIP_DRAW_CACHE` by caching hit zones alongside the ASS text.
