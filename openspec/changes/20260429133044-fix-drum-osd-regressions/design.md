## Context

The `draw_drum` function in `scripts/lls_core.lua` was refactored in commit `67ee625` to support multi-line (word-wrapped) OSD subtitles. The refactor correctly introduced `wrap_tokens()` and `calculate_osd_line_meta()` returning per-vline data. However, it introduced three regressions:

1. **Gap-size source bug**: The `cur_y` and `total_h` loops both call `calculate_sub_gap(prefix, size, ...)` where `size` is derived from the **upcoming** subtitle's `is_active` flag. The correct source is the **previous** subtitle's size (the one that just finished rendering), matching the original `get_separator(prev_is_active)` semantics.

2. **Empty subtitle height regression**: `calculate_osd_line_meta` returns `total_height = 0` for empty text because no vlines are produced. Pre-refactor, `height = (font_size * line_height_mul) + vsp` was always non-zero, preserving the vertical slot. The new code silently compresses the OSD block when empty subtitles are in the context window.

3. **Unconditional metadata computation**: `calculate_osd_line_meta` and its `wrap_tokens` + `dw_get_str_width` cascade now run every frame regardless of whether `osd_interactivity` is enabled. Pre-refactor, this block was guarded by `if hit_zones and Options.osd_interactivity`.

## Goals / Non-Goals

**Goals:**
- Restore correct inter-subtitle vertical spacing when `drum_active_size_mul != drum_context_size_mul`.
- Restore the minimum slot height for empty context subtitles.
- Eliminate redundant per-frame width calculation when `osd_interactivity` is off.
- Zero changes to the word-wrapping logic, hit-zone data structures, or ASS rendering output format.

**Non-Goals:**
- Refactoring the wrapping engine.
- Changing the `vlines` data model.
- Touching `dw_build_layout` or `draw_dw`.

## Decisions

### Decision 1: How to pass "previous size" to the gap calculation

**Problem**: The gap after subtitle `i` should use the font size of subtitle `i` (the one that ended), not subtitle `i+1` (the one about to start).

**Option A** — Track `prev_size` variable in the loop:
```lua
local prev_size = nil
for i = start_idx, end_idx do
    local is_active = (i == center_idx)
    local size = font_size * (is_active and ...)
    local m = calculate_osd_line_meta(...)
    table.insert(sub_metas, m)
    total_h = total_h + m.total_height
    if prev_size and i <= end_idx then
        total_h = total_h + calculate_sub_gap(prefix, prev_size, lh_mul, vsp) + adj
    end
    prev_size = size
end
```

**Option B** — Store `size` inside `sub_metas[i]` and read `sub_metas[i-1].size` in the second loop.

**Decision**: Option B — store `size` inside each meta entry. This keeps both loops self-contained and avoids a dangling `prev_size` that must be updated in two places. The meta entry already carries `sub_idx`; adding `size` is consistent.

### Decision 2: Empty subtitle minimum height

`calculate_osd_line_meta` SHALL synthesize a minimal single vline entry for empty text rather than returning an empty `vlines` table, so the total height always equals at least `(font_size * line_height_mul) + vsp`. The synthesized vline has `words = {}`, `total_width = 0`, `token_indices = {}`.

**Rationale**: Keeps the height contract predictable — callers never need to special-case zero height.

### Decision 3: Interactivity guard

Re-introduce the guard: wrap the entire `for _, m in ipairs(sub_metas)` hit-zone population loop inside `if hit_zones and Options.osd_interactivity then`. The `sub_metas` table is still populated (needed for rendering), but the width calculations inside `calculate_osd_line_meta` become gated.

**Alternative**: Skip `calculate_osd_line_meta` entirely and use a lightweight height-only path for non-interactive rendering. This is more complex and deferred to a future optimization.

## Risks / Trade-offs

- [Risk] Storing `size` in the meta table couples the layout phase to the rendering phase → **Mitigation**: Size is already implicit in `vlines[].height`; storing it explicitly is not a new coupling, just surfacing existing data.
- [Risk] Minimum-height vline for empty subs could produce a blank ASS line → **Mitigation**: `format_sub_wrapped` already has an early-return `if #tokens == 0 then return ""` guard, so the ASS output is empty string; height reservation only affects `total_h`.
- [Risk] Guard change means hit-zones are not populated when `osd_interactivity` is off → **Mitigation**: This was exactly the pre-refactor behavior. The guard is a restore, not a new restriction.
