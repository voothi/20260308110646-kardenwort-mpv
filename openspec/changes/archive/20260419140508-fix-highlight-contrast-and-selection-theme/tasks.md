## 1. Highlight Palette Calibration

- [x] 1.1 Update `anki_highlight_depth_3` to `#003C88` (Dark Orange) and `anki_mix_depth_3` to `#151578` (Deep Brick) in the `Options` default table in `scripts/lls_core.lua`.
- [x] 1.2 Update the two hardcoded `ANKI_MIX_DEPTH_3` fallbacks (approx. lines 1997 and 2260) in `scripts/lls_core.lua` to use the new `#151578` constant.

## 2. Selection Theme Transition

- [x] 2.1 Update `dw_highlight_color` to `#00CCFF` (Gold) and `dw_ctrl_select_color` to `#FF88FF` (Neon Pink) in the `Options` default table in `scripts/lls_core.lua`.
- [x] 2.2 Update the inline comments in `scripts/lls_core.lua` to reflect the Gold and Neon Pink "Neon" calibration.

## 3. Configuration Sync & Documentation

- [x] 3.1 Update the `script-opts-append` entries in `mpv.conf` for `lls-anki_highlight_depth_3`, `lls-anki_mix_depth_3`, `lls-dw_highlight_color`, and `lls-dw_ctrl_select_color`.
- [x] 3.2 Correct the misleading `mpv.conf` comment on line 179 from "Shades of green" to "Shades of orange/gold".
- [x] 3.3 Add clarifying comments to `mpv.conf` for the `anki_mix_depth` and `dw_ctrl_select_color` settings.
