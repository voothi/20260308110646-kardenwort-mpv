## 1. Variable Renaming

- [ ] 1.1 Globally rename `drum_upper_gap_adj` to `drum_gap_adj` in `lls_core.lua`.
- [ ] 1.2 Update the parameter name in `mpv.conf` (including comments/documentation).
- [ ] 1.3 Update the parameter name in `README.md`'s parameter tables.

## 2. Anchor-Aware Gap Adjustment (Hit-Zones)

- [ ] 2.1 In `lls_core.lua` inside `draw_drum`, locate the hit-zone calculation loop (`total_h` accumulation). Change `local adj = (not d_gap and abs_idx < center_idx) and (Options.drum_upper_gap_adj or 0) or 0` to `local adj = (not d_gap) and (Options.drum_gap_adj or 0) or 0`.
- [ ] 2.2 Repeat the exact same change in the second `cur_y` calculation loop just below it. This ensures `adj` applies to *all* gaps, allowing the center line to shift relative to the anchor point.

## 3. Visual-Logical Integration (OSD Rendering)

- [ ] 3.1 In `lls_core.lua` inside `draw_drum`, locate the `get_separator(prev_is_active)` function (around line 2590).
- [ ] 3.2 Define `local adj = (not d_gap) and (Options.drum_gap_adj or 0) or 0` just above or inside the function.
- [ ] 3.3 Update the return format string to inject `adj` into the first `\vsp` tag: `return string.format("{\\vsp%g}%s{\\vsp%g}", vsp_base + vsp_extra + adj, d_gap and "\\N\\N" or "\\N", vsp_base)`.

## 4. Verification

- [ ] 4.1 Verify that setting `drum_gap_adj=30` visibly shifts the Drum Mode text downwards and hit-zones remain perfectly synced.
- [ ] 4.2 Verify that the center-line correctly shifts in bottom-anchored mode (`sub-pos=95`).
- [ ] 4.3 Confirm that `drum_double_gap=yes` behavior remains unaffected (where `adj` should be 0).
