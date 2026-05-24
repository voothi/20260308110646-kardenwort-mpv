## 1. Phase 1: Baseline Options and Diagnostics (Smallest, Highest Signal)

- [ ] 1.1 Expose new options: `dw_wrap_line_height_mul = 1.05`, `dw_edge_margin = 24`, and `dw_cyrillic_coef = 0.52`.
- [ ] 1.2 Expose `dw_block_top` and `dw_total_height` in the OSD state snapshot query for verification.
- [ ] 1.3 Define and enforce DM-only centering guardrails for tooltip work (`FSM.DRUM == "ON"` and `FSM.DRUM_WINDOW == "OFF"`), keeping SRT tooltip behavior unchanged.

## 2. Phase 2: Border-Style Lifecycle Hardening (Foundational)

- [ ] 2.1 Implement the `manage_ui_border_override(enable)` callback flow to selectively switch global `osd-border-style` to `outline-and-shadow` only while custom OSD overlays are active.
- [ ] 2.2 Harden nested UI overrides using `ui_border_override_depth` to prevent premature restoration when multiple menus overlap.
- [ ] 2.3 Confirm override lifecycle across DW/Search/Tooltip open-close transitions before visual renderer rewrites.

## 3. Phase 3: Tooltip Geometry and Width Safety in DM

- [ ] 3.1 Calibrate Cyrillic width calculations in `dw_get_str_width()` using `dw_cyrillic_coef` to prevent long Russian tooltip overflow.
- [ ] 3.2 Center tooltip text and background card horizontally at `X = 960` with top-center alignment (`\an8`) in DM only.
- [ ] 3.3 Align mouse hit-zones horizontally in `dw_tooltip_hit_test` using centered `960 - line_w / 2` bounds.
- [ ] 3.4 Position tooltip vertically at the secondary subtitle OSD region in DM to prevent overlap with primary subtitles.

## 4. Phase 4: Spacing and Safe-Area Decoupling for DW

- [ ] 4.1 Implement visual helper `vline_height(fs)` inside a scoped helper table/block to decouple intra-subtitle wrap heights from block gaps.
- [ ] 4.2 Implement viewport helper `calculate_block_top(raw_top, total_h)` to respect `dw_edge_margin` clamps under overflow.
- [ ] 4.3 Wire the same spacing model into both rendering and hit-testing paths to avoid geometry drift.

## 5. Phase 5: Cohesive Vector Card Rendering (Largest Visual Rewrite)

- [ ] 5.1 Render a single cohesive vector background card (`bg_rect` via `\p1`) in `draw_dw_tooltip`, preserving existing interaction behavior.
- [ ] 5.2 Render the same cohesive vector background card pattern in `draw_dw`, replacing line-by-line frame visuals.
- [ ] 5.3 Prepend local opacity overrides (`\3a&HFF&` and `\4a&HFF&` with `\bord0` and `\shad0`) to text lines as a compatibility layer for `background-box` mode.

## 6. Phase 6: Interaction Parity Follow-Ups (Only After Visual Acceptance)

- [ ] 6.1 Allow trailing punctuation (`.`, `?`, `!`) selection parity in DM by removing the `t.is_word` filter in `calculate_osd_line_meta()`.
- [ ] 6.2 Evaluate need for `FSM.DW_HIT_ZONES` caching and `dw_hit_test()` rewrite; implement only if residual hit drift remains after Phases 1-5.
- [ ] 6.3 Evaluate drag-threshold changes (`5px` gating for timer/drag activation) only if reproducible in current branch after visual fixes.

## 7. Phase 7: Safety Scope and Non-Goals Enforcement

- [ ] 7.1 Do not introduce global startup callback shims; if needed, add narrow local guards only at the registration call sites that are proven unstable.
- [ ] 7.2 Keep `manage_dw_bindings()` architecture unchanged unless a concrete regression requires targeted edits.

## 8. Phase 8: Automated Test Verification (Last Phase)

- [ ] 8.1 Add/adjust only targeted visual regression tests for borders, margins, tooltip centering, and hit-zone alignment.
- [ ] 8.2 Run the focused automated suite to verify visual alignment and click accuracy after user-approved visual checks.
