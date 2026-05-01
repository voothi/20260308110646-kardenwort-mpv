# Proposal: Search HUD Interaction Synchronization

## Problem
Recent implementations of word-wrapping in the Search HUD (Ctrl+F) have introduced a significant regression in mouse interactivity. Specifically, the hit-testing logic in `search_mouse_click` (LLS Core) assumes a fixed single-line height for both the search query and the results list. This causes two distinct types of "interaction drift":
1. **Vertical Offset**: If the search query wraps, the entire result list shifts down visually, but the click targets remain at their original (un-shifted) coordinates.
2. **Result Drift**: If a search result wraps to multiple lines, subsequent results are shifted down, making them either un-clickable or causing the wrong item to be selected.
Additionally, the Search UI's aesthetic parameters (border transparency) are currently de-synchronized from the v1.58.0 parity standards used in Drum and Tooltip modes.

## Proposed Change
Refactor the Search HUD rendering and interaction pipeline to be "token-aware" and "layout-synchronized":
- **Dynamic Hit-Testing**: Implement a cumulative Y-offset map (similar to `FSM.DW_LINE_Y_MAP`) for the Search UI to ensure click targets perfectly align with the visual results, regardless of wrapping.
- **Aesthetic Synchronization**: Update the search background style to include `\3a` transparency tags, matching the background alpha to eliminate opaque "blooming" borders.
- **UI Simplification**: Abandon the explicit search result frame/border if it simplifies the visual hierarchy and improves click-target reliability at the screen edges.

## Impact
- **Interactivity**: Restores O(1) precise mouse selection of search results.
- **Reliability**: Fixes the "un-clickable bottom results" reported by the user.
- **Aesthetics**: Achieves full stylistic parity across all HUD modes (SRT, Drum, Tooltip, and Search).
