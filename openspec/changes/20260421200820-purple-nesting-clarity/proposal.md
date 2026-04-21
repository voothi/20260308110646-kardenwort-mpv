## Why

The purple (split-match) gradient system was designed to show *nesting depth* — when one pair-selected phrase is wholly contained within another. However, the current `purple_depth` counter increments for any term whose spatial footprint overlaps the current word's position, regardless of whether the relationship is true nesting or merely spatial adjacency. This causes two adjacent, independent purple groups (one with nesting, one without) to incorrectly darken each other, as shown in the screenshot where `gleich richtig` became darker even though it is part of a separate, non-nesting group. The user considers this misleading and wants minimalism — no new colors, no new shades — so the question is whether to fix the depth logic or disable the gradient entirely.

## What Changes

- **Option A (Fix depth logic):** Restrict `purple_depth` increments to only terms that are *genuinely nested* within the same outermost group as the currently matched term. This requires determining whether the overlapping footprint term is the exact same match group or a different one.
- **Option B (Disable gradient / flatten):** Remove the depth-based color variation and render ALL purple split-matches at a single flat color (`anki_split_depth_1`). This is the minimalist option and avoids the ambiguity problem entirely for overlapping/adjacent groups.
- **Decision: Implement Option B.** The gradient was intended to aid comprehension, but when groups are adjacent (not nested) it creates confusion. With minimalism as the guiding principle and no new colors permitted, a flat purple is unambiguous: every split-match word is the same shade regardless of how many terms cover it or how they relate.

Concrete changes:
- Remove `purple_depth` from the rendering decision in `calculate_highlight_stack` and the two rendering call sites.
- Always use `anki_split_depth_1` (or the single flat color) when `purple_stack > 0`.
- Remove `anki_split_depth_2` and `anki_split_depth_3` from rendering (Options entries can remain for backward config compatibility but are ignored in rendering).
- Remove `mix_depth` calculation that used `purple_depth` (replace with a fixed depth of 1 for any mixed orange+purple word).

## Capabilities

### New Capabilities
_(none)_

### Modified Capabilities
- `window-highlighting-spec`: The Phase 2 (Split/Purple) rendering requirement changes — depth gradient is removed; all split-match words use a single flat purple shade. The mix-depth rule for orange+purple coexistence is simplified.
- `high-recall-highlighting`: The `purple_depth` counting requirement in `calculate_highlight_stack` is removed; the return value contract changes (depth is no longer meaningful).

## Impact

- **Code**: `scripts/lls_core.lua` — `calculate_highlight_stack` (remove `purple_depth` accumulation), both rendering pass sites (around lines 2131–2143 and 2399–2415).
- **Visual**: All split-match words become a uniform flat pink/purple instead of graduating darker with nesting depth.
- **No new options** required. Existing `anki_split_depth_2` and `anki_split_depth_3` options remain in the Options table but are no longer referenced.
- **No breaking changes** for users — the visual change is intentional and well-defined.
