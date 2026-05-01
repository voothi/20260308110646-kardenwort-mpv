## Why

Performance profiling of the `lls_core.lua` rendering pipeline has identified several "frozen" or "missing" cache triggers. High-load scenarios—such as rapid subtitle scrolling, dual-track playback, and frequent Anki mining—currently suffer from redundant calculations and occasional visual staleness. This change addresses these bottlenecks to ensure a butter-smooth, reliable user experience even with large highlight databases.

## What Changes

- **Cache Integrity Fixes**:
  - Fix `DRUM_DRAW_CACHE` collision by adding track-source identification (Primary vs Secondary) to the invalidation key.
  - Fix `DW_DRAW_CACHE` staleness by including the `ANKI_HIGHLIGHTS` count in the invalidation key.
- **Rendering Performance Enhancements**:
  - Enable `DRUM_DRAW_CACHE` during interactive playback by caching the `hit_zones` geometry table alongside the ASS string.
  - Implement per-subtitle layout caching (wrapped lines, widths, and heights) on subtitle objects to accelerate scrolling.
  - Implement token-level Database Highlight caching to skip expensive `calculate_highlight_stack` evaluations on every redraw.
- **Normalization Efficiency**:
  - Pre-calculate and store normalized lowercase (`lower_clean`) text on tokens during initial tokenization to eliminate redundant `utf8_to_lower` calls in the hot path.

## Capabilities

### New Capabilities
- `rendering-optimization`: Defines performance requirements, cache invalidation strategies, and intermediate result reuse for high-frequency subtitle rendering.

### Modified Capabilities
- `drum-window-performance`: Update cache invalidation requirements to include highlight count triggers.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (hot paths: `draw_drum`, `draw_dw`, `calculate_highlight_stack`, `get_sub_tokens`).
- **APIs**: Internal state management within the `FSM` table and subtitle/token objects.
- **Dependencies**: No new external dependencies; leverages existing Lua table structures for caching.
