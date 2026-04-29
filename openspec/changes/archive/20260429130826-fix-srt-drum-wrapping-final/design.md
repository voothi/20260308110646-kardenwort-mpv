# Design: Multi-Line Layout and Rendering in OSD

## Context
Interactivity requires the script to know the exact screen coordinates of every word. Since native ASS wrapping (`{\q0}`) is non-deterministic for the script, we implement manual wrapping.

## Goals / Non-Goals
- **Goal**: Accurate hit-testing on all visual lines.
- **Goal**: Respecting source `\n` while adding automatic wrapping where needed.
- **Non-Goal**: Supporting complex ASS layout features like scrolling or rotations within wrapped blocks.

## Decisions

### 1. Unified Wrapping Engine (`wrap_tokens`)
A new utility function `wrap_tokens` splits a stream of tokens into visual lines. It uses a 1860px width threshold and respects explicit `\n` characters as forced line breaks.

### 2. Multi-Line Metadata
`calculate_osd_line_meta` now returns a nested structure:
- `vlines`: An array of line objects, each with its own `total_width`, `y_offset`, and word list.
- `total_height`: The sum of all visual line heights.

### 3. Coordinate Flattening in `draw_drum`
The `draw_drum` loop flattens these nested `vlines` into a global `hit_zones` list. This ensures the mouse-tracking logic can iterate over a simple list of bounding boxes, regardless of which subtitle or line they belong to.

### 4. Lua Implementation Guard (Multiple Return Values)
To prevent crashes during rendering, string operations (like `gsub`) that return multiple values must be wrapped in parentheses when passed directly to `table.insert`. This avoids unintended argument expansion that can lead to "bad argument #2 (number expected, got string)" errors.

## Risks / Trade-offs
Manual wrapping is dependent on the accuracy of the `dw_get_str_width` heuristic. While consistent with the "Drum Window" mode, it may vary slightly from mpv's native font rendering if unusual glyphs are used.
