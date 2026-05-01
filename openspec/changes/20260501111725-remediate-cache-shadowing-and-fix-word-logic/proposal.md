## Why

A post-implementation expert audit of the rendering cache hardening (commit `d8bee95`) identified two critical structural regressions:
1. **Broken Cache Invalidation**: The forward declarations for `DRUM_DRAW_CACHE` and `DW_DRAW_CACHE` at the top of `lls_core.lua` are shadowed by `local` re-definitions later in the file. This makes `flush_rendering_caches` a no-op for the actual caches used in rendering, resulting in persistent stale OSD states.
2. **Logic Degradation**: A redundant and inferior definition of `is_word_char` was introduced at line 1395, shadowing the optimized O(1) version from line 913. This forces hot-path navigation and hit-testing logic to revert to unoptimized regex scanning.

## What Changes

- **De-shadow Caches**: Remove the `local` keyword from `DRUM_DRAW_CACHE` and `DW_DRAW_CACHE` assignments (lines 2918 and 3232) to ensure they bind to the module-scope upvalues captured by `flush_rendering_caches`.
- **Restore Optimized Logic**: Remove the redundant `is_word_char` definition at line 1395.
- **Sentinel Consistency**: Ensure `DRUM_DRAW_CACHE.is_drum` is correctly reset during cache flushes to guarantee track/mode synchronization.

## Capabilities

### Modified Capabilities
- `cache-hardening`: Fixes the invalidation layer to actually target the live cache tables.
- `rendering-optimization`: Restores O(1) word-character lookups across all module functions by removing shadowing.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (`DRUM_DRAW_CACHE`, `DW_DRAW_CACHE`, `is_word_char`).
- **Correctness**: Restores immediate UI feedback for mode toggles and configuration changes.
- **Performance**: Restores O(1) character scanning efficiency for all interactive navigation and hit-testing logic.
