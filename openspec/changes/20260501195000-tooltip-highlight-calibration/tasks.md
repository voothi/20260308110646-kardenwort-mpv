## 1. Options & Initialization

- [ ] 1.1 Add `tooltip_highlight_color` and `tooltip_ctrl_select_color` to the `Options` table in `lls_core.lua`.
- [ ] 1.2 Default these new options to `dw_highlight_color` and `dw_ctrl_select_color` respectively.
- [ ] 1.3 Add the new options to `mpv.conf` under the "Translation Tooltip Settings" section.

## 2. Refactor Core Service

- [ ] 2.1 Update `populate_token_meta` signature to accept `h_color` and `ctrl_color` parameters.
- [ ] 2.2 Refactor `populate_token_meta` internal logic to use these parameters (with fallbacks to `Options` defaults).
- [ ] 2.3 Verify that `populate_token_meta` remains $O(1)$ and respects the `force_plain` flag.

## 3. Rendering Loop Integration

- [ ] 3.1 Update `draw_dw_core` call to `populate_token_meta` to pass Drum Window specific colors.
- [ ] 3.2 Update `draw_dw_tooltip` call to `populate_token_meta` to pass Tooltip specific colors.
- [ ] 3.3 Ensure `flush_rendering_caches()` correctly invalidates the tooltip cache when these options are modified.

## 4. Verification

- [ ] 4.1 Verify that changing `tooltip_highlight_color` in `mpv.conf` affects the tooltip but not the Drum Window.
- [ ] 4.2 Confirm that selection synchronization still works (logic remains shared, only aesthetics are decoupled).
- [ ] 4.3 Validate that no regressions occur in multi-word selection coloring.
