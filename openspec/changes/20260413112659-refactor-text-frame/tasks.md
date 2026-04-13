## 1. Schema Refactor in `Options`

- [x] 1.1 Rename and unify tooltip parameters in `scripts/lls_core.lua`: `dw_tooltip_*` -> `tooltip_*` in the `Options` table.
- [x] 1.2 Add missing frame control parameters to `Options`: `drum_bg_opacity`, `drum_border_size`, `drum_shadow_offset`, `dw_text_opacity`, `dw_border_size`, `dw_shadow_offset`.
- [x] 1.3 Normalize default visual values in `Options` across all modes (Target: `bg_opacity = "60"`, `dw_font_size = 38`, `border_size = 1.5`, `shadow_offset = 1.0`).

## 2. Core Renderer Refactor

- [x] 2.1 Update `draw_drum` in `lls_core.lua` to explicitly apply background transparency (`\4a`), border size (`\bord`), and shadow offset (`\shad`) from script options.
- [x] 2.2 Update `draw_dw` in `lls_core.lua` to remove hardcoded text alpha and inject `\4a`, `\1a`, `\bord`, and `\shad` from the unified `dw_` options.
- [x] 2.3 Update `draw_dw_tooltip` to utilize the new `tooltip_` prefixed options and standardize its ASS styling block.

## 3. Configuration & Documentation Integrity

- [x] 3.1 Update `mpv.conf` with renamed `lls-tooltip_*` options and add new entries for the unified styling parameters.
- [x] 3.2 Add a documentation section in `mpv.conf` explaining how to align native SRT subtitles (`sub-back-color`, `sub-border-style`) with the script's dark mode aesthetic.
- [x] 3.3 Identify and restore verbose calibration comments and alternative styling blocks (`MODE 1/2`) to ensure documentation integrity.
- [x] 3.4 Verify all defaults in both `lls_core.lua` and `mpv.conf` are visually synchronized.
