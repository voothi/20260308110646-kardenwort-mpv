## 1. MPV Configuration (`mpv.conf`)

- [x] 1.1 In `mpv.conf`, locate the "Common Drum Window Settings" section and update the following values to implement the dark theme:
  - Change `lls-dw_bg_color` to `000000`
  - Change `lls-dw_bg_opacity` to `60`
  - Change `lls-dw_text_color` to `CCCCCC`
  - Change `lls-dw_active_color` to `FFFFFF`
  - Change `lls-dw_highlight_color` to `00FFFF`

- [x] 1.2 In `mpv.conf`, locate the "Drum Window Tooltip Settings" section and make it an opaque dark grey box so it floats visibly above the background:
  - Change `lls-dw_tooltip_bg_opacity` to `11`
  - Change `lls-dw_tooltip_bg_color` to `222222`

- [x] 1.3 In `mpv.conf`, locate the "Search HUD Styling" section and update the highlight colors to neon variants for dark mode contrast:
  - Change `lls-search_hit_color` to `0088FF`
  - Change `lls-search_sel_color` to `FF0000`
  - Change `lls-search_query_hit_color` to `0088FF`

## 2. Core Script Defaults (`scripts/lls_core.lua`)

- [x] 2.1 In `scripts/lls_core.lua`, locate the `Options` table near the top of the file. Find the "Drum Window" settings block and update the fallback string values to match `mpv.conf`:
  - `dw_bg_color = "000000"`
  - `dw_bg_opacity = "60"`
  - `dw_text_color = "CCCCCC"`
  - `dw_active_color = "FFFFFF"`
  - `dw_highlight_color = "00FFFF"`

- [x] 2.2 In the same `Options` table, locate the \"Search HUD Styling\" section and update the strings:
  - `search_hit_color = "0088FF"`
  - `search_sel_color = "FF0000"`
  - `search_query_hit_color = "0088FF"`

- [x] 2.3 In the same `Options` table, locate the \"Drum Window Tooltip\" section and update the strings:
  - `dw_tooltip_bg_opacity = "11"`
  - `dw_tooltip_bg_color = "222222"`

## 3. Style Refinements (Search & Anki)

- [x] 3.1 Fix Search selection unreadability in `mpv.conf` by changing `lls-search_sel_color` from Blue (`FF0000`) to White (`FFFFFF`).
- [x] 3.2 Transition Anki highlights from Green to Orange in `mpv.conf` by updating `lls-anki_highlight_depth_1`, `lls-anki_highlight_depth_2`, and `lls-anki_highlight_depth_3` to `0075D1`, `005DAE`, and `003A70` respectively.
- [x] 3.3 Synchronize these refinements in `scripts/lls_core.lua` by updating the default `search_sel_color` and `anki_highlight_depth_1-3` values.

## 4. Visual Parity (Alignment with Drum Mode C)

- [x] 4.1 In `scripts/lls_core.lua`, within the `draw_dw` function, identify and remove the vector drawing block that renders the large central background rectangle (search for `get_bg_ass`).
- [x] 4.2 In `scripts/lls_core.lua`, within the `draw_dw` function, remove the ASS tags `{\\bord0}{\\shad0}{\\blur0}{\\1a&H00&}{\\3a&HFF&}{\\4a&HFF&}` from the main text block to allow the window to inherit native OSD background boxes.
- [x] 4.3 In `scripts/lls_core.lua`, within `draw_drum`, ensure any missing formatting tags (like `\q2` for wrap style) are aligned if necessary for perfect parity.
