## Context

An expert audit of `lls_core.lua` after the two recent performance changes found four gaps. The critical gap is that `DW_LAYOUT_CACHE` (the viewport-level layout cache) does not check `FSM.LAYOUT_VERSION`, while the per-subtitle `sub.layout_cache` does. This means if `flush_rendering_caches()` increments `LAYOUT_VERSION` but the viewport center has not changed, `DW_LAYOUT_CACHE` will serve stale layout geometry. A secondary gap is that `flush_rendering_caches()` resets caches via upvalue references that are resolved at call time but are fragile to definition-order changes. Two minor issues (use of `pairs()` on sequential tables, undocumented sub-cache lifetime) round out the set.

## Goals / Non-Goals

**Goals:**
- Ensure `DW_LAYOUT_CACHE` is always consistent with `LAYOUT_VERSION`.
- Make `flush_rendering_caches()` robust against definition-order changes.
- Improve code correctness and readability in hit-zone restoration loops.
- Document the lifetime contract of `sub.layout_cache`.

**Non-Goals:**
- Changing caching strategy, performance characteristics, or user-facing behavior.
- Adding eviction for `sub.layout_cache` (documented as session-lived; acceptable).
- Modifying any logic outside `lls_core.lua`.

## Decisions

### Decision 1: Add `LAYOUT_VERSION` field to `DW_LAYOUT_CACHE`
**Choice**: Store the `LAYOUT_VERSION` value when the viewport cache is written, and validate it in the hit guard.

```lua
-- Store:
FSM.DW_LAYOUT_CACHE = {
    view_center    = view_center,
    subs_ptr       = subs,
    layout_version = FSM.LAYOUT_VERSION,  -- NEW
    layout         = layout,
    total_height   = total_height
}

-- Check:
if FSM.DW_LAYOUT_CACHE and
   FSM.DW_LAYOUT_CACHE.view_center    == view_center and
   FSM.DW_LAYOUT_CACHE.subs_ptr       == subs and
   FSM.DW_LAYOUT_CACHE.layout_version == FSM.LAYOUT_VERSION then  -- NEW
    return ...
end
```

**Rationale**: Minimal diff; preserves the existing structure. The `layout_version` field makes the viewport cache a full peer of `sub.layout_cache` in terms of invalidation guarantees.

**Alternative**: Set `FSM.DW_LAYOUT_CACHE = nil` whenever `LAYOUT_VERSION` changes (in `flush_rendering_caches()`). Already done — but this only covers the case where `flush_rendering_caches()` is called. The version field adds a belt-and-suspenders check that is correct even if the flush path were ever bypassed.

### Decision 2: Harden `flush_rendering_caches()` via direct sentinel resets
**Choice**: Instead of `if DRUM_DRAW_CACHE then DRUM_DRAW_CACHE.center_idx = -1 end` (which silently no-ops if the upvalue is unexpectedly nil), add a module-level comment and rely on the fact that both tables are always initialized at module scope before any event handler fires. Keep the current `if` guards but add a `mp.msg.error` trace if either is nil, to make the failure visible.

**Rationale**: Full restructuring is out of scope. A trace log is the minimal change that makes a broken state observable without altering architecture.

### Decision 3: Replace `pairs()` with `ipairs()` for hit-zone restoration
**Choice**: In both the `DRUM_DRAW_CACHE` and `DW_DRAW_CACHE` hit-zone restoration loops, use `ipairs()`.

**Rationale**: Hit-zones are sequential arrays. `ipairs()` is faster (no hash part traversal) and signals intent clearly. Non-integer keys would silently be skipped — acceptable because the table structure is always sequential.

## Risks / Trade-offs

- **[No behavioral risk]** All changes are defensive guards or iteration style fixes. The rendered output is identical under correct operation.
- **[layout_version field cost]** One extra field per `DW_LAYOUT_CACHE` entry — negligible (one integer, one table).
