## 1. Highlight Palette Calibration

- [ ] 1.1 Update `anki_highlight_depth_3` to `#003C88` (Dark Orange) and `anki_mix_depth_3` to `#151578` (Deep Brick) in the `Options` default table in `scripts/lls_core.lua`.
- [ ] 1.2 Update the two hardcoded `ANKI_MIX_DEPTH_3` fallbacks (approx. lines 1997 and 2260) in `scripts/lls_core.lua` to use the new `#151578` constant.

## 2. Selection Theme Transition

- [ ] 2.1 Update `dw_ctrl_select_color` to `#FF00FF` (Vivid Violet) in the `Options` default table in `scripts/lls_core.lua`.
- [ ] 2.2 Update the inline comment for `dw_ctrl_select_color` to "Vivid violet for split-word select (pairing with purple)".

## 3. Configuration Sync & Documentation

- [ ] 3.1 Update the `script-opts-append` entries in `mpv.conf` for `lls-anki_highlight_depth_3`, `lls-anki_mix_depth_3`, and `lls-dw_ctrl_select_color`.
- [ ] 3.2 Correct the misleading `mpv.conf` comment on line 179 from "Shades of green" to "Shades of orange/gold".
- [ ] 3.3 Add clarifying comments to `mpv.conf` for the `anki_mix_depth` and `dw_ctrl_select_color` settings.
