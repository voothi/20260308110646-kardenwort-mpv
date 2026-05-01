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

## 7. Glow Regression & Tooltip Unification

- [x] 7.1 Add `tooltip_active_bold` and `tooltip_context_bold` to `Options` in `lls_core.lua`.
- [x] 7.2 Update `draw_dw_tooltip` to use per-line `bold_state` derived from new active/context toggles.
- [x] 7.3 Fix ASS tag bug in `draw_dw_tooltip`: migrate from `\3c` to `\4c` for background color and set both to `bg_color`.
- [x] 7.4 Update `mpv.conf` to remove legacy `tooltip_font_bold` and use granular `active`/`context` boldness toggles (default `no`).
- [x] 7.5 Verify visual parity: Tooltip should now match Drum/SRT weight and background aesthetic.

## 9. Final Aesthetic Calibration (Post-Regression Analysis)
2026-05-01: Analysis identified that opaque borders contribute to perceived "Boldness" even when \b0 is used.

- [x] 9.1 Update `draw_dw` to explicitly set `\3a` (border transparency) to match `\4a` (derived from `dw_bg_opacity`).
- [x] 9.2 Update `draw_drum` to explicitly set `\3a` (border transparency) to match `\4a` (derived from `bg_opacity`).
- [x] 9.3 Update `draw_dw_tooltip` to explicitly set `\3a` (border transparency) to match `\4a` (derived from `tooltip_bg_opacity`).
- [x] 9.4 Verify that "Yellow" highlights now appear with a true "Premium" (Regular) font weight without artificial border thickening.

## 10. Final Verification

- [x] 10.1 Conduct a final expert-level regression analysis on commit `74263e43f0418b4950462b256989a61961b63d3b` against `v1.58.0`.
- [x] 10.2 Confirm zero regressions in O(1) performance and verbatim subtitle fidelity.
- [x] 10.3 Archive the change after user approval of the final aesthetic state.
