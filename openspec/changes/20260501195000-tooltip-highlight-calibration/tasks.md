## 1. Options & Initialization

- [x] 1.1 Add `tooltip_highlight_color` and `tooltip_ctrl_select_color` to the `Options` table in `lls_core.lua`.
- [x] 1.2 Default these new options to `dw_highlight_color` and `dw_ctrl_select_color` respectively.
- [x] 1.3 Add the new options to `mpv.conf` under the "Translation Tooltip Settings" section.

## 2. Refactor Core Service

- [x] 2.1 Update `populate_token_meta` signature to accept `h_color` and `ctrl_color` parameters.
- [x] 2.2 Refactor `populate_token_meta` internal logic to use these parameters (with fallbacks to `Options` defaults).
- [x] 2.3 Verify that `populate_token_meta` remains $O(1)$ and respects the `force_plain` flag.

## 3. Rendering Loop Integration

- [x] 3.1 Update `draw_dw_core` call to `populate_token_meta` to pass Drum Window specific colors.
- [x] 3.2 Update `draw_dw_tooltip` call to `populate_token_meta` to pass Tooltip specific colors.
- [x] 3.3 Ensure `flush_rendering_caches()` correctly invalidates the tooltip cache when these options are modified.

## 4. Verification

- [x] 4.1 Verify that changing `tooltip_highlight_color` in `mpv.conf` affects the tooltip but not the Drum Window.
- [x] 4.2 Confirm that selection synchronization still works (logic remains shared, only aesthetics are decoupled).
- [x] 4.3 Validate that no regressions occur in multi-word selection coloring.

## 5. Universal Mode Decoupling

- [x] 5.1 Add `drum_pri_highlight_color`, `drum_sec_highlight_color`, `srt_pri_highlight_color`, and `srt_sec_highlight_color` to `Options`.
- [x] 5.2 Add corresponding `ctrl_select_color` options for all modes and tracks.
- [x] 5.3 Update `draw_drum` to pass track-specific and mode-specific colors to `populate_token_meta`.
- [x] 5.4 Update `mpv.conf` with all new color options in their respective sections.

## 6. Universal Boldness Calibration

- [x] 6.1 Refactor `format_highlighted_word` in `lls_core.lua` to accept a `force_bold` parameter.
- [x] 6.2 Add independent `highlight_bold` toggles for Tooltip, Drum Window, Drum Mode (Pri/Sec), and SRT Mode (Pri/Sec) to `Options`.
- [x] 6.3 Update rendering loops to pass mode-specific and track-specific boldness preferences to `format_highlighted_word`.
- [x] 6.4 Update `mpv.conf` with the full suite of boldness toggles.
- [x] 6.5 Verify that tooltip yellow highlights are regular weight by default but can be made bold via configuration.
