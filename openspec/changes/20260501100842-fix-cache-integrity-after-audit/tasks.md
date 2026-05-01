## 1. DW_LAYOUT_CACHE Version Consistency (Medium — correctness)

- [ ] 1.1 Add `layout_version` field to the `FSM.DW_LAYOUT_CACHE` store in `dw_build_layout()`, capturing the current `FSM.LAYOUT_VERSION` value.
- [ ] 1.2 Add `layout_version == FSM.LAYOUT_VERSION` to the `DW_LAYOUT_CACHE` hit guard in `dw_build_layout()`, alongside the existing `view_center` and `subs_ptr` checks.

## 2. flush_rendering_caches() Observability (Low — fragility)

- [ ] 2.1 Add `mp.msg.warn` traces in `flush_rendering_caches()` for the case where `DRUM_DRAW_CACHE` or `DW_DRAW_CACHE` is unexpectedly nil, to make definition-order bugs visible instead of silent.
- [ ] 2.2 Add a module-level comment on `flush_rendering_caches()` documenting the required definition-order invariant (both cache tables must be defined at module scope before the function is called at runtime).

## 3. Hit-Zone Iteration Style (Low — clarity)

- [ ] 3.1 Replace `pairs()` with `ipairs()` in the hit-zone restoration loop inside `draw_drum()` (cache hit path).
- [ ] 3.2 Replace `pairs()` with `ipairs()` in the hit-zone cache-store loop inside `draw_drum()` (cache write path).
- [ ] 3.3 Replace `pairs()` with `ipairs()` in the hit-zone restoration loop inside `draw_dw()` (cache hit path).
- [ ] 3.4 Replace `pairs()` with `ipairs()` in the hit-zone cache-store loop inside `draw_dw()` (cache write path).

## 4. Documentation (Low — clarity)

- [ ] 4.1 Add a comment on `sub.layout_cache` in `dw_build_layout()` documenting that it is session-lived and evicted only via `flush_rendering_caches()` / track reload.
