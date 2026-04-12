## 1. Setup and State Machine

- [ ] 1.1 Add `dw_tooltip_font_size`, `dw_tooltip_context_lines`, `dw_tooltip_bg_opacity`, and `dw_tooltip_mode` to `Options` in `lls_core.lua`.
- [ ] 1.2 Add `FSM.DW_TOOLTIP_LINE = -1` to the `FSM` state block.
- [ ] 1.3 Initialize the `dw_tooltip_osd` overlay at `z=25` mimicking existing OSD bootstrap patterns.

## 2. Tooltip Rendering Logic

- [ ] 2.1 Write `draw_dw_tooltip(subs, target_line_idx)` to generate the tooltip ASS string.
- [ ] 2.2 Inside `draw_dw_tooltip`, iterate `Tracks.sec.subs` based on primary node time bounds and pad the payload with `dw_tooltip_context_lines`.
- [ ] 2.3 Implement the layout logic `{\pos(1850, y)}{\an6}` limiting maximum ASS string width and injecting the semi-transparent background box payload.

## 3. Mouse Interaction and Lifecycle

- [ ] 3.1 Create `cmd_dw_tooltip_pin()` to force `FSM.DW_TOOLTIP_LINE = hovered_line` and bind it to `MBTN_RIGHT` dynamically in `manage_dw_bindings`.
- [ ] 3.2 Hook `tick_dw()` or a `mouse_move` fast-tracker to verify the mouse boundary. If it departs `FSM.DW_TOOLTIP_LINE`, reset line to `-1` and erase `dw_tooltip_osd`.
- [ ] 3.3 Add `cmd_toggle_dw_tooltip_hover()` to allow toggling "Hover Mode". Bind this dynamically to a designated key (e.g. `n`) specified in `mpv.conf` as `dw_tooltip_hover_key`.
- [ ] 3.4 Hook Hover Mode: If `FSM.DW_TOOLTIP_MODE` is set to "HOVER", auto-assign `FSM.DW_TOOLTIP_LINE` without requiring the `MBTN_RIGHT` click.
- [ ] 3.5 Wire `dw_tooltip_osd:update()` to fire when `FSM.DW_TOOLTIP_LINE` effectively toggles or drops.
