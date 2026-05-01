## Context
The Search HUD currently uses a simplified coordinate calculation for hit-testing that does not account for the multi-line wrapping implemented in the rendering loop. This results in a mismatch between the visual position of search results and their logical click targets, especially when the search query or results span multiple lines.

## Goals / Non-Goals

**Goals:**
- **Synchronized Hit-Testing**: Align the mouse interaction logic with the dynamic visual layout.
- **Aesthetic Parity**: Standardize transparency and border tags to match the v1.58.0 "Premium" aesthetic.
- **Improved Reliability**: Ensure all results in the dropdown are clickable, including those near the screen edges.

**Non-Goals:**
- Changing the search algorithm or database query logic.
- Adding new UI elements (icons, etc.).

## Decisions

### 1. Cumulative Y-Offset Mapping (ZID 20260501234125)
- **Implementation**: The renderer populates `FSM.SEARCH_HIT_ZONES` containing precise OSD bounding boxes for each visual line.
- **Rationale**: This eliminates the "click drift" where wrapped results were un-clickable at the bottom of the list.

### 2. Aesthetic Synchronization (ZID 20260501234944)
The search background box and result text are now synchronized with the v1.58.0 standard.
- **Tags**: Added `{\3a&H<bg_alpha>&}{\4a&H<bg_alpha>&}` to the background box.
- **Simplification**: Abandoned the explicit border (`bord=0`) to ensure a premium look and reduce hit-test interference.

### 3. Query-Aware Results Positioning
The `results_y` offset will be calculated dynamically based on the actual height of the wrapped query block, rather than assuming a single-line height.

## Risks / Trade-offs

- **Memory**: Maintaining a hit-zone map for search results adds a negligible memory overhead (8-10 entries).
- **Performance**: The O(1) nature of the hit-test is preserved as it remains a simple linear scan of a very small set of results (max 8).
