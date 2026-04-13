## 1. MPV Configuration Updates

- [ ] 1.1 Update `mpv.conf` Drum Window color and opacity variables for Dark Theme (`lls-dw_bg_color`, `lls-dw_bg_opacity`, `lls-dw_text_color`, `lls-dw_active_color`, `lls-dw_highlight_color`).
- [ ] 1.2 Update `mpv.conf` Tooltip colors to opaque dark grey (`lls-dw_tooltip_bg_opacity=11`, `lls-dw_tooltip_bg_color=222222`).
- [ ] 1.3 Update `mpv.conf` Search styling variables to neon equivalents (`lls-search_hit_color`, `lls-search_sel_color`, `lls-search_query_hit_color`).

## 2. Core Source Code Defaults

- [ ] 2.1 Update the hardcoded `Options` dictionary in `lls_core.lua` to correctly fallback to the new Dark Theme configuration if `mpv.conf` is missing or cleared.
