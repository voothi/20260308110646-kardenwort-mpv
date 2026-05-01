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

### 1. Cumulative Y-Offset Mapping
We will introduce a dynamic mapping system during the `draw_search_ui` call. 
- **Implementation**: The renderer will populate a temporary table (e.g., `FSM.SEARCH_HIT_ZONES`) containing the precise OSD bounding boxes for each search result.
- **Rationale**: This follows the proven architectural pattern used in the Drum Window (`DW_LINE_Y_MAP`) and eliminates all drift caused by wrapping or variable line heights.

### 2. Aesthetic Synchronization (`\3c`, `\4c`, `\3a`, `\4a`)
The search background box and result text will be updated to use the synchronized transparency pattern.
- **Tags**: Add `{\3a&H<bg_alpha>&}{\4a&H<bg_alpha>&}` to the background box.
- **Simplification**: As suggested by the user, we will set `\bord0` (abandon the frame) if it improves visual clarity and reduces hit-test interference, or ensure the border transparency is synchronized to prevent "blooming".

### 3. Query-Aware Results Positioning
The `results_y` offset will be calculated dynamically based on the actual height of the wrapped query block, rather than assuming a single-line height.

## Risks / Trade-offs

- **Memory**: Maintaining a hit-zone map for search results adds a negligible memory overhead (8-10 entries).
- **Performance**: The O(1) nature of the hit-test is preserved as it remains a simple linear scan of a very small set of results (max 8).
