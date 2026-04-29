## 1. Core Logic Fixes in lls_core.lua

- [ ] 1.1 Update `calculate_osd_line_meta` to handle empty text by returning a synthesized vline with height `(font_size * line_height_mul) + vsp`.
- [ ] 1.2 Add `size` field to the return table of `calculate_osd_line_meta` to store the calculated effective font size.
- [ ] 1.3 Update `draw_drum` height accumulation loop to use `sub_metas[i-1].size` (previous subtitle's size) when calling `calculate_sub_gap`.
- [ ] 1.4 Update `draw_drum` y-position advance loop to use `sub_metas[i-1].size` (previous subtitle's size) when calling `calculate_sub_gap`.
- [ ] 1.5 Wrap the hit-zone population loop in `draw_drum` with a conditional guard: `if hit_zones and Options.osd_interactivity then`.

## 2. Verification and Polish

- [ ] 2.1 Verify vertical alignment in Drum Mode when switching between active and context subtitles with different size multipliers.
- [ ] 2.2 Verify that empty context subtitles maintain their vertical slot height.
- [ ] 2.3 Verify that mouse hit-zones remain perfectly aligned with visual text after the gap calculation fix.
- [ ] 2.4 Verify that OSD performance is maintained when interactivity is disabled.
