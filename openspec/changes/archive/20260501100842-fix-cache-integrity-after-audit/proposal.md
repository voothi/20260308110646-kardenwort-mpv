## Why

An independent expert audit of the two recent performance changes (`20260501023103-optimize-hot-paths` and `20260501093901-optimize-speed-and-reliability-hot-paths`) identified two medium-severity and two low-severity correctness gaps in the caching layer. Left unaddressed, these can produce stale rendering after font/spacing option changes, and the `flush_rendering_caches()` helper silently becomes a no-op if call order ever shifts.

## What Changes

- **Fix `DW_LAYOUT_CACHE` version-blindness**: Add a `LAYOUT_VERSION` check to the `DW_LAYOUT_CACHE` hit guard so that font/spacing changes reliably invalidate the viewport-level cache, consistent with the per-subtitle `sub.layout_cache` check.
- **Fix forward-reference fragility in `flush_rendering_caches()`**: Replace the `if DRUM_DRAW_CACHE then` / `if DW_DRAW_CACHE then` upvalue-at-definition checks with a pattern that is robust regardless of definition order — by resetting the sentinel key fields directly on the tables that are guaranteed to be module-scope at call time.
- **`ipairs()` over `pairs()` for hit-zone restoration loops**: Sequential arrays should use `ipairs()` for clarity and a marginal speed benefit; both draw-cache hit-zone restoration loops use `pairs()`.
- **Document `sub.layout_cache` lifetime contract**: Add a comment establishing that per-subtitle caches are intentionally session-lived and evicted only via `flush_rendering_caches()`.

## Capabilities

### New Capabilities
_(none — all changes are implementation-layer fixes with no new spec-level behavior)_

### Modified Capabilities
- `drum-window-performance`: Strengthen the invalidation requirement for the viewport-level layout cache to include the `LAYOUT_VERSION` counter, matching the sub-level cache invariant already required.

## Impact

- **Affected Code**: `scripts/lls_core.lua` — `flush_rendering_caches()`, `dw_build_layout()`, hit-zone restoration paths in `draw_drum()` and `draw_dw()`.
- **APIs/Behavior**: No user-visible behavior change under normal operation. Fixes potential stale layout after live option edits.
- **Dependencies**: None.
