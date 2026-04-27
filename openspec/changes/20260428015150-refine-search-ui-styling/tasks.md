## 1. Configuration Schema

- [ ] 1.1 Add `search_results_font_size` to the `Options` table in `lls_core.lua`
- [ ] 1.2 Synchronize `mpv.conf` with new search parameters and defaults
- [ ] 1.3 Add comments to `mpv.conf` explaining the font scaling options (0=100%, -1=80%)

## 2. Search UI Rendering Restoration

- [ ] 2.1 Restore hardcoded layout constants (`box_w`, `box_x`, `box_y`) in `draw_search_ui`
- [ ] 2.2 Implement independent font size calculation for the results dropdown
- [ ] 2.3 Verify ASS tag syntax for font name and size consistency

## 3. Contrast and Highlighting Refinement

- [ ] 3.1 Update rendering loop to force pure white (`FFFFFF`) for the active selection's base text
- [ ] 3.2 Implement logic to preserve colored hit highlights on the selected line using `search_query_hit_color`
- [ ] 3.3 Ensure unselected lines use the dimmer `search_text_color` (default `CCCCCC`) for background context

## 4. Validation and Calibration

- [ ] 4.1 Test search functionality with varying query lengths
- [ ] 4.2 Verify that trailing spaces in the search query do not cause unexpected "orange overload"
- [ ] 4.3 Confirm that font scaling correctly applies to the results dropdown without breaking layout alignment
