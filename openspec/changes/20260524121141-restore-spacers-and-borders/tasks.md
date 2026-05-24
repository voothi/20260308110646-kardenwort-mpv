## 1. Phase 1: Spacing and Margin Decoupling

- [ ] 1.1 Expose new options: `dw_wrap_line_height_mul = 1.05`, `dw_edge_margin = 24`, and `dw_cyrillic_coef = 0.52`.
- [ ] 1.2 Implement the visual helper `vline_height(fs)` inside the `DW_HELPERS` table or scoping block to decouple intra-subtitle wrap heights from block gaps.
- [ ] 1.3 Implement the viewport visual helper `calculate_block_top(raw_top, total_h)` to respect `dw_edge_margin` clamps under overflow.
- [ ] 1.4 Calibrate Cyrillic width calculations in `dw_get_str_width()` using `dw_cyrillic_coef` to prevent long Russian tooltip overflow.
- [ ] 1.5 Expose `dw_block_top` and `dw_total_height` in the OSD state snapshot query for verification.

## 2. Phase 2: Cohesive Single Vector Background and Localized Transparency

- [ ] 2.1 Render a single cohesive vector background card (`bg_rect` using the `\p1` rectangle) in `draw_dw` and `draw_dw_tooltip` instead of line-by-line frames.
- [ ] 2.2 Prepend local opacity overrides (`\3a&HFF&` and `\4a&HFF&` with `\bord0` and `\shad0`) to individual OSD text lines to neutralize default frames in `background-box` mode.
- [ ] 2.3 Implement the `manage_ui_border_override(enable)` callback flow to selectively switch global `osd-border-style` to `outline-and-shadow` only while custom OSD overlays are active.
- [ ] 2.4 Harden nested UI overrides using `ui_border_override_depth` to prevent premature restoration when multiple menus overlap.

## 3. Phase 3: Centered Fullscreen Tooltip in Drum Mode

- [ ] 3.1 Center tooltip text and background card horizontally at `X = 960` with top-center alignment (`\an8`) when Drum Mode (DM) is active (`FSM.DRUM_WINDOW == "OFF"`).
- [ ] 3.2 Align the mouse hit-zones horizontally in `dw_tooltip_hit_test` using the centered `960 - line_w / 2` bounds.
- [ ] 3.3 Position the tooltip vertically at the secondary subtitle OSD region in DM to prevent overlap with primary subtitles.

## 4. Phase 4: Precision Hit-Testing and Punctuation Selection

- [ ] 4.1 Populate and cache dynamic visual line coordinates (`FSM.DW_HIT_ZONES`) during the OSD rendering pass.
- [ ] 4.2 Rewrite `dw_hit_test()` to resolve lines directly using the cached `FSM.DW_HIT_ZONES` coordinate table.
- [ ] 4.3 Allow trailing punctuation (`.`, `?`, `!`) to be clicked and selected in DM by removing the `t.is_word` filter in `calculate_osd_line_meta()`.

## 5. Phase 5: Drag Thresholds and Binding Safety

- [ ] 5.1 Defer mouse scroll timers and active drag states until a `5px` movement threshold is exceeded.
- [ ] 5.2 Rewrite `manage_dw_bindings()` dynamic key/mouse registration into a table-driven loop checking `type(cb) == "function"`.
- [ ] 5.3 Implement global API safety guards at startup to intercept and log missing callback registrations.

## 6. Phase 6: Automated Test Verification (Last Phase)

- [ ] 6.1 Port and migrate the visual regression tests for borders, margins, and tooltips.
- [ ] 6.2 Run the automated suite to verify visual alignment and click accuracy.
