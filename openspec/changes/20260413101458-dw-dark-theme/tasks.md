## 1. MPV Configuration (`mpv.conf`)

- [ ] 1.1 In `mpv.conf`, locate the "Common Drum Window Settings" section and update the following values to implement the dark theme:
  - Change `lls-dw_bg_color` to `000000`
  - Change `lls-dw_bg_opacity` to `60`
  - Change `lls-dw_text_color` to `CCCCCC`
  - Change `lls-dw_active_color` to `FFFFFF`
  - Change `lls-dw_highlight_color` to `00FFFF`

- [ ] 1.2 In `mpv.conf`, locate the "Drum Window Tooltip Settings" section and make it an opaque dark grey box so it floats visibly above the background:
  - Change `lls-dw_tooltip_bg_opacity` to `11`
  - Change `lls-dw_tooltip_bg_color` to `222222`

- [ ] 1.3 In `mpv.conf`, locate the "Search HUD Styling" section and update the highlight colors to neon variants for dark mode contrast:
  - Change `lls-search_hit_color` to `0088FF`
  - Change `lls-search_sel_color` to `FF0000`
  - Change `lls-search_query_hit_color` to `0088FF`

## 2. Core Script Defaults (`scripts/lls_core.lua`)

- [ ] 2.1 In `scripts/lls_core.lua`, locate the `Options` table near the top of the file. Find the "Drum Window" settings block and update the fallback string values to match `mpv.conf`:
  - `dw_bg_color = "000000"`
  - `dw_bg_opacity = "60"`
  - `dw_text_color = "CCCCCC"`
  - `dw_active_color = "FFFFFF"`
  - `dw_highlight_color = "00FFFF"`

- [ ] 2.2 In the same `Options` table, locate the "Search HUD Styling" section and update the strings:
  - `search_hit_color = "0088FF"`
  - `search_sel_color = "FF0000"`
  - `search_query_hit_color = "0088FF"`

- [ ] 2.3 In the same `Options` table, locate the "Drum Window Tooltip" section and update the strings:
  - `dw_tooltip_bg_opacity = "11"`
  - `dw_tooltip_bg_color = "222222"`
