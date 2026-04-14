## Context

Currently, the rendering system collapses all saved term intersections into a single metric called `stack`. If a word overlaps with *any* saved match in the database, its `stack` depth simply increases. However, we recently introduced a split/purple highlight for non-contiguous terms alongside the contiguous orange highlights. Because depth is tracked in a single variable, an intersection between an orange term and a purple term results in a depth of 2, but loses clarity on *which* types are combining, obscuring the intersection. The user desires a "mixed" or "blended" color state representing the overlap of both types, similar to standard e-reader highlighter behavior.

## Goals / Non-Goals

**Goals:**
- Decouple the depth tracking of contiguous (orange) terms from split (purple) terms.
- Determine if a word belongs to *only* contiguous terms, *only* split terms, or *both* (an intersection).
- Use three new configuration keys: `anki_mix_depth_1`, `anki_mix_depth_2`, and `anki_mix_depth_3` to represent overlapping layers when *both* types of highlights apply to a given word.

**Non-Goals:**
- Creating a full 3x3 combinatorial matrix of 9 colors. As per the proposal, we can default to a simplified model where if an intersection happens, it reads from a single 3-level "mix" palette based on total depth `(orange_depth + purple_depth)`, rather than distinct colors for 1x2, 2x1, 2x2, etc., unless specifically requested as a 9-color matrix. For simplicity and robustness, we will just use a unified `mix_depth` track when both are present.

## Decisions

- **Independent Depth States (`orange_stack` & `purple_stack`):** `calculate_highlight_stack` will return both an orange stack count and a purple stack count, allowing the renderer to discern pure-orange, pure-purple, or mixed states.
- **Mix Color Rendering:** If a word has `orange_stack > 0` AND `purple_stack > 0`, it goes into the "mixed" color track. The specific depth of this mixed track can be calculated as `total_stack = orange_stack + purple_stack`. Based on `total_stack` (clamped to 3), it will select from `anki_mix_depth_1`, `2`, or `3`.
- **Config Defaults:** We will add the 3 new configuration keys to `mpv.conf` with default hex colors that visually represent a blending of Orange and Purple (e.g. muddy brownish-reds, or a distinct third color like dark magenta/gold).

## Risks / Trade-offs

- **Colorspace Exhaustion:** Adding 3 more colors brings the total anki highlight configuration palette to 9 colors (3 orange, 3 purple, 3 mixed). This increases user configuration burden but offers maximal flexibility.
- **Total Stack Caps:** We must ensure the `total_stack` doesn't overshoot array borders if an intersection of depth 3 orange and depth 3 purple happens. We will use `math.min(orange_stack + purple_stack, 3)` to map any intersection into the 3 available mix shades.
