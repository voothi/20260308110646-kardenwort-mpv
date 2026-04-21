## Context

The `calculate_highlight_stack` function returns `purple_depth` — a count of how many terms' spatial footprints cover the target word. The intended use was: if word W is covered by both an outer group (e.g., A...B) and an inner nested group (e.g., C...D fully inside A...B), it should appear darker, showing "you saved this in multiple overlapping contexts."

In practice, the footprint check uses a simple 1D range test (`t_total >= t_start and t_total <= t_end`), which fires for ANY term whose span includes W, regardless of whether that term is a true parent or simply an adjacent, non-intersecting sibling that happens to start before W ends. Adjacent groups that touch but do not nest still cause `purple_depth` to increment on their boundary words.

The user's screenshot demonstrates `gleich richtig` receiving a depth-2 shade even though its group does not nest inside the adjacent group; they are siblings. The fix is to stop using depth to modulate color.

## Goals / Non-Goals

**Goals:**
- All words matched by purple (split-match) terms render in a single flat shade (`anki_split_depth_1` / `FF88B0` by default).
- The orange + purple mix case also flattens to a single mix shade (`anki_mix_depth_1`).
- `purple_depth` is removed from the return value and rendering logic.
- The visual output is unambiguous: purple = split match, regardless of how many terms cover a word or their structural relationship.

**Non-Goals:**
- Implementing a structurally correct nesting detection algorithm (would require O(n²) group intersection analysis per render frame — too expensive).
- Adding any new colors or shades.
- Changing orange (contiguous) depth behavior — that gradient remains and is correct.

## Decisions

### Decision 1: Remove depth-based shading for purple entirely (Option B)

Chosen over fixing the depth algorithm because: (a) correctly detecting true nesting vs. adjacency would require comparing all pairs of matching terms to determine containment, which is expensive per-token per-frame; (b) the user explicitly requested minimalism and no new shades; (c) a flat color is always unambiguous — darker shading was the source of confusion.

**Alternative A (Fix containment test)**: Rejected. Too expensive at render time and the benefit (showing true nesting depth) is marginal for the use case.

### Decision 2: Keep `purple_depth` accumulation in `calculate_highlight_stack` but stop using it in rendering

The `purple_depth` variable can remain as an internally computed value (it costs nothing to keep), but the return value's usage at both call sites should simply be discarded or replaced with a constant.

**Alternative**: Remove `purple_depth` from the function signature entirely. This would require refactoring the function return and all callers. Chosen NOT to do this to minimize diff surface — we simply stop reading `purple_depth` in the rendering branches.

### Decision 3: Orange depth gradient is unchanged

Orange depth indicates multiple contiguous-match phrases stacked on the same word, which is a meaningfully different and unambiguous signal. No change.

## Risks / Trade-offs

- **[Trade-off] Loss of nesting information**: Words that genuinely ARE covered by multiple nested pink groups will no longer visually signal their nesting depth. This is acceptable because: (1) the user rarely creates truly nested groups, (2) the flat color still correctly identifies split-match words, and (3) the ambiguity was worse than the lost information.
- **[Risk] Orange+purple mix case**: When a word is simultaneously in an orange and a purple group, we still need a visible indicator. We flatten this to `anki_mix_depth_1` always. No risk.

## Migration Plan

1. In the Drum Window rendering pass (around line 2399), change the `elseif purple_stack > 0` branch to always use `anki_split_depth_1`.
2. Remove the `if purple_depth == 1 / elseif purple_depth == 2 / elseif purple_depth >= 3` cascade — replace with a single `h_color = Options.anki_split_depth_1 or "FF88B0"`.
3. In the same pass, change the `orange_stack > 0 and purple_stack > 0` mix branch to always use `anki_mix_depth_1` (remove the `mix_depth` variable).
4. In the playback rendering pass (around line 2131), apply identical changes.
5. No config file changes. No migration for users needed.

## Open Questions

- None. The approach is fully determined by the minimalism constraint and the bug root cause analysis.
