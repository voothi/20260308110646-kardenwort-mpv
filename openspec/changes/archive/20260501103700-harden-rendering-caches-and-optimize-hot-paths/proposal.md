## Why

A professional expert audit of the recent rendering optimizations (commits `9172605` to `e92448b3`) identified a critical "silent failure" in the cache invalidation layer: `flush_rendering_caches` cannot see the `local` cache tables defined later in the module without forward declarations, rendering it a no-op for those caches. Furthermore, the high-level draw caches are missing essential guard fields (`subs_ptr`, `LAYOUT_VERSION`), which could lead to stale rendering during track switching or font-size adjustments. Finally, `is_word_char` contains a performance bottleneck (O(N) string search) that triggers on every character during subtitle loading.

## What Changes

- **Cache Invalidation Integrity**:
  - Add forward declarations for `DRUM_DRAW_CACHE` and `DW_DRAW_CACHE` at the top of the module to ensure they are correctly captured by the `flush_rendering_caches` closure.
  - Strengthen `DW_DRAW_CACHE` guard by adding `subs_ptr` and `LAYOUT_VERSION` checks.
  - Strengthen `DRUM_DRAW_CACHE` guard by adding a `LAYOUT_VERSION` check.
- **Hot-Path Optimization**:
  - Replace the O(N) `find` loop in `is_word_char` with an O(1) `WORD_CHAR_MAP` lookup table.
  - Refactor `utf8_to_lower` to use a single `gsub` call with a mapping table instead of 37 sequential `gsub` calls.
- **Robustness**:
  - Add `LAYOUT_VERSION` check to `draw_drum` and `draw_dw` to ensure immediate invalidation on option changes, matching the `DW_LAYOUT_CACHE` pattern.

## Capabilities

### Modified Capabilities
- `rendering-optimization`: Strengthen cache invalidation invariants to require forward visibility and version-tracking for all high-level rendering results.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (`flush_rendering_caches`, `draw_drum`, `draw_dw`, `is_word_char`, `utf8_to_lower`).
- **Performance**: Significant reduction in subtitle loading time for large files (O(1) char check); slightly lower overhead in interactive redraws.
- **Correctness**: Eliminates potential stale rendering after track switches or live font adjustments.
