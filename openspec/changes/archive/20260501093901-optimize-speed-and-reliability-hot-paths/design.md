## Context

The `lls_core.lua` script implements a high-frequency (50ms) rendering loop for mpv. Recent performance audits identified that while top-level "Result Caching" exists, it is fragile and frequently bypassed or stale. Specifically, `DRUM_DRAW_CACHE` collides in dual-track mode, `DW_DRAW_CACHE` fails to react to Anki database updates, and O(N) layout calculations run redundantly during scrolling and playback transitions.

## Goals / Non-Goals

**Goals:**
- **Reliability**: Ensure caches correctly differentiate between tracks and react to database changes.
- **Responsiveness**: Achieve near-instant visual feedback when adding records.
- **Efficiency**: Reduce per-tick CPU load by caching intermediate layout and highlight calculations.

**Non-Goals:**
- Changing the 50ms `master_tick` rate.
- Modifying the visual appearance or styling of subtitles.
- Deep refactoring of the global FSM state machine.

## Decisions

### Decision 1: Track-Aware Drum Cache Key
**Choice**: Add the track ID (Primary vs Secondary) to the `DRUM_DRAW_CACHE` key.
- **Rationale**: Currently, if both tracks share a center index (synced subs), the secondary track displays the primary's cached text.
- **Alternative**: Separate cache tables. Rejected because a single table with a discriminative key is more memory-efficient and follows the existing pattern.

### Decision 2: Cache Hit-Zone Geometry
**Choice**: Store the `hit_zones` metadata table inside the draw caches (`DRUM_DRAW_CACHE` and `DW_DRAW_CACHE`).
- **Rationale**: The cache is currently bypassed if `hit_zones` is requested (interactivity ON). By caching the geometry table, we can skip the full rebuild even during interactive playback.
- **Implementation**: Deep-copy or re-reference the hit-zones table when the ASS string is cached.

### Decision 3: Hierarchical Caching (Subtitle & Token Levels)
**Choice**: Implement caching on individual subtitle and token objects.
- **Sub-level**: `sub.layout_cache` stores the wrapped visual lines (`vlines`) and total block height.
- **Token-level**: `token.highlight_cache` stores the results of `calculate_highlight_stack` (orange/purple levels).
- **Token-level**: `token.lower_clean` stores normalized text.
- **Rationale**: This prevents redundant wrapping and database scanning when the viewport scrolls or the draw cache misses.

## Risks / Trade-offs

- **[Memory Leakage]** → Storing caches on thousands of subtitle objects increases memory usage. **Mitigation**: Lua handles table growth well; 5,000 subtitles with minimal metadata will consume <5MB of additional RAM.
- **[Cache Invalidation Complexity]** → Moving to a multi-level cache increases the risk of "ghost" highlights. **Mitigation**: Use a centralized `flush_rendering_caches()` helper called by `load_anki_tsv` and track-change events.
- **[Hit-Zone Offset Drift]** → Caching geometry might lead to misaligned clicks if the OSD base position changes. **Mitigation**: Include `y_pos_percent` and `font_size` in the cache key.
