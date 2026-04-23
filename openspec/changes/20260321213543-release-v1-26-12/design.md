# Design: Drum Mode Rendering and OSD Refinement

## System Architecture
The changes focus on the `tick_drum()` rendering loop in `lls_core.lua` and the global configuration in `mpv.conf`.

### Components
1.  **Rendering Engine (`tick_drum`)**:
    - Refactored to concatenate `prev_context`, `active_line`, and `next_context` with a single `\N` separator.
    - Applies a single set of ASS tags (e.g., `{\an8...}`) to the entire combined block instead of per-line.
2.  **Property Synchronizer**:
    - Updates `tick_drum` to query `secondary-sub-pos` for vertical alignment instead of using static percentages.
3.  **UI Configuration**:
    - `mpv.conf` updates to set `osd-bar=no` and `osd-border-style=outline-and-shadow`.

## Implementation Strategy
- **ASS Formatting**: Use the `{}` tag block at the very start of the concatenated string to ensure inheritance across the whole block.
- **Anchor Logic**: Use `\an8` for top-aligned subtitles and `\an2` for bottom-aligned subtitles, ensuring the block expands away from the center or edge naturally.
- **Sync Logic**: Ensure that manual positioning commands (like `Ctrl+T/R`) trigger an immediate visual update in Drum Mode.
