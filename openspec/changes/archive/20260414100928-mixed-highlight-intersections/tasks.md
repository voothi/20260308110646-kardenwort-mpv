## 1. Stack Decoupling

- [x] 1.1 In `lls_core.lua` within `calculate_highlight_stack`, update the variables to track `orange_stack` and `purple_stack` independently during the overlap calculation loop.
- [x] 1.2 Modify `calculate_highlight_stack` to return `orange_stack`, `purple_stack`, and `is_phrase` so the rendering logic has granular state.

## 2. Mixed Color Implementation

- [x] 2.1 In `lls_core.lua` rendering functions (Drum OSD and DW), update the `color` selection cascade to evaluate: Pure Orange, Pure Purple, or Mixed Intersection.
- [x] 2.2 Calculate `total_stack` constraint for the Mixed color pathway, capping at 3 (`math.min(orange_stack + purple_stack, 3)`).
- [x] 2.3 Add `anki_mix_depth_1/2/3` key defaults to `lls_core.lua` `Option` matrix and implement rendering logic mapping.

## 3. Configuration Update

- [x] 3.1 Append the three new `lls-anki_mix_depth_X` color configuration properties to `mpv.conf` for user visibility and persistence.
