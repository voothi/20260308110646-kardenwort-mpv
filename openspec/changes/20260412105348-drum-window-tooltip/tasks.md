## 1. Setup and State Variables (lls_core.lua)

- [ ] 1.1 In the `Options` table (top of file), add configurations: `dw_tooltip_font_size = 24`, `dw_tooltip_context_lines = 1`, `dw_tooltip_bg_opacity = "77"`, `dw_tooltip_bg_color = "1A1A1A"`, `dw_tooltip_text_color = "FFFFFF"`, `dw_tooltip_hover_key = "n"`.
- [ ] 1.2 In the `FSM` table, add state variables: `DW_TOOLTIP_LINE = -1` and `DW_TOOLTIP_MODE = "CLICK"`.
- [ ] 1.3 Below the existing OSD creations (`drum_osd`, `dw_osd`), create a new OSD object `dw_tooltip_osd` using `mp.create_osd_overlay("ass-events")`. Set `res_x = 1920`, `res_y = 1080`, and `z = 25`.

## 2. Tooltip Rendering Logic

- [ ] 2.1 Write function `draw_dw_tooltip(subs, target_line_idx, y_pixel)` below the `draw_dw` function. If `target_line_idx == -1` or `Tracks.sec.subs` is empty, return an empty string `""`.
- [ ] 2.2 In `draw_dw_tooltip`, find the temporal center point: calculate the midpoint time between `subs[target_line_idx].start_time` and `subs[target_line_idx].end_time`. Use `get_center_index(Tracks.sec.subs, midpoint)` to find the matching secondary subtitle index.
- [ ] 2.3 Gather the context lines from `Tracks.sec.subs`: Loop from `center_idx - Options.dw_tooltip_context_lines` to `center_idx + Options.dw_tooltip_context_lines`. Join their `raw_text` fields (to prevent ASS injection crashes) using `"\\N"`.
- [ ] 2.4 Return the constructed ASS string. Anchor it to the right: `{\pos(1850, y_pixel)}{\an6}`. Use `{\1a&H...&}{\1c&H...&}{\p1}...{\p0}` for a background rectangle and properly style the text. Ensure text wraps correctly or enforce `\q1`.

## 3. Tooltip Interaction Handlers

- [ ] 3.1 Write function `cmd_dw_tooltip_pin()`. Use `dw_get_mouse_osd()` and `dw_hit_test(osd_x, osd_y)`. If a `line_idx` is hit, set `FSM.DW_TOOLTIP_LINE = line_idx` and manually call `draw_dw_tooltip(...)` updating `dw_tooltip_osd.data`.
- [ ] 3.2 Write function `cmd_toggle_dw_tooltip_hover()`. It should toggle `FSM.DW_TOOLTIP_MODE` between `"CLICK"` and `"HOVER"`. Output a message using `show_osd(...)` to notify the user.
- [ ] 3.3 Write function `dw_tooltip_mouse_update()`. Call `dw_hit_test(osd_x, osd_y)`. If the hovered `line_idx` !== `FSM.DW_TOOLTIP_LINE`, set `FSM.DW_TOOLTIP_LINE = -1` and clear `dw_tooltip_osd`.
- [ ] 3.4 In `dw_tooltip_mouse_update()`, if `FSM.DW_TOOLTIP_MODE == "HOVER"` and `line_idx` exists, auto-pin: `FSM.DW_TOOLTIP_LINE = line_idx` and update `dw_tooltip_osd`.

## 4. Integration & Bindings

- [ ] 4.1 Inside `tick_dw()`, add a call to `dw_tooltip_mouse_update()` so the tooltip lifecycle runs continuously while the window is active.
- [ ] 4.2 In `manage_dw_bindings()`, inside the local `keys` table, add a new binding: `{key = "MBTN_RIGHT", name = "dw-tooltip-pin", fn = cmd_dw_tooltip_pin}`.
- [ ] 4.3 In `manage_dw_bindings()`, add the hover mode toggle binding dynamically: `{key = Options.dw_tooltip_hover_key, name = "dw-tooltip-hover", fn = cmd_toggle_dw_tooltip_hover}`.
- [ ] 4.4 In `manage_dw_bindings(enable)`, when `enable` is false (closing window), forcefully set `FSM.DW_TOOLTIP_LINE = -1` and flush `dw_tooltip_osd` to ensure it disappears instantly when the window closes.
