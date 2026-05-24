## 0. Execution Contract

- [ ] 0.1 Execute one phase at a time, with user visual acceptance before moving forward.
- [ ] 0.2 Keep changes minimally invasive; no broad architectural refactors.
- [ ] 0.3 Defer broad/expensive test runs until the final phase.
- [ ] 0.4 Enforce tag-safety: preserve existing text color/typography tags by default; only add minimal local compatibility tags for defects.

## 1. Phase 1: Baseline Options and Diagnostics (Smallest, Highest Signal)

- [x] 1.1 Expose new options: `dw_wrap_line_height_mul = 1.05`, `dw_edge_margin = 24`, `dw_cyrillic_coef = 0.52`.
- [x] 1.2 Expose `dw_block_top` and `dw_total_height` in the OSD state snapshot query.
- [x] 1.3 Add DM-only tooltip centering guardrails: apply centered logic only when `FSM.DRUM == "ON"` and `FSM.DRUM_WINDOW == "OFF"`.
- [ ] 1.4 Visual gate: verify no SRT tooltip behavior change after guard introduction.

## 2. Phase 2: Spacing and Safe-Area Decoupling for DW (Moved Earlier)

- [ ] 2.1 Implement `vline_height(fs)` helper in a scoped helper block/table.
- [x] 2.2 Implement `calculate_block_top(raw_top, total_h)` with `dw_edge_margin` clamping.
- [x] 2.3 Use the same spacing model in rendering and hit-testing paths.
- [ ] 2.4 Visual gate: verify wrap spacing, inter-subtitle gap consistency, and safe margins at viewport extremes.
- [ ] 2.5 Hit-accuracy calibration pass (do immediately after 2.4): verify DW and tooltip pointer-to-word mapping at top/middle/bottom lines and tune geometric offsets only if drift is reproducible.

## 3. Phase 3: Border-Style Lifecycle Hardening (Foundational)

- [ ] 3.1 Implement `manage_ui_border_override(enable)` to switch `osd-border-style` only while custom overlays are active.
- [ ] 3.2 Add nested depth safety (`ui_border_override_depth`) to prevent premature restoration under overlapping menus.
- [ ] 3.3 Validate open-close lifecycle across DW/Search/Tooltip transitions.
- [ ] 3.4 Visual gate: confirm no dark/double background stacking in DM tooltip.

## 4. Phase 4: Tooltip Geometry and Width Safety in DM

- [ ] 4.1 Calibrate Cyrillic width in `dw_get_str_width()` using `dw_cyrillic_coef`.
- [ ] 4.2 Center DM tooltip text/card at `X = 960` with `\an8`.
- [ ] 4.3 Re-align `dw_tooltip_hit_test` bounds to centered geometry (`960 - line_w / 2`).
- [ ] 4.4 Place DM tooltip vertically in the secondary subtitle region to avoid collisions.
- [ ] 4.5 Visual gate: verify centered DM tooltip, stable hover/click hit-zones, and no clipping on long Russian lines.

## 5. Phase 5: Cohesive Vector Card Rendering (Largest Visual Rewrite)

- [ ] 5.1 Implement unified tooltip vector card (`\p1`) first, preserving current interaction flow.
- [ ] 5.2 Implement unified DW vector card (`\p1`) second, replacing line-by-line frame visuals.
- [ ] 5.3 Add local compatibility tags (`\3a&HFF&`, `\4a&HFF&`, `\bord0`, `\shad0`) for `background-box` mode stability.
- [ ] 5.4 Keep existing color constants and text-style tags unchanged unless a specific bug forces a local override.
- [ ] 5.5 Visual gate: verify premium single-card look with no frame leakage and preserved click behavior.

## 6. Phase 6: Interaction Parity Follow-Ups (Conditional)

- [ ] 6.1 Add trailing punctuation selection parity (`.`, `?`, `!`) by relaxing the `t.is_word` filter in `calculate_osd_line_meta()`.
- [ ] 6.2 Reassess residual drift after Phase 2.5 and Phase 4.5; only then consider `FSM.DW_HIT_ZONES` cache + `dw_hit_test()` rewrite.
- [ ] 6.3 Reassess drag behavior; only then consider `5px` timer/drag gating.
- [ ] 6.4 Visual gate: verify no regressions in selection, drag, and tooltip stability.

## 7. Phase 7: Safety Scope Enforcement

- [ ] 7.1 Explicitly avoid global startup callback shims.
- [ ] 7.2 If runtime safety issues remain, add narrow local guards at proven unstable call sites only.
- [ ] 7.3 Keep `manage_dw_bindings()` architecture unchanged unless a concrete regression demands a targeted fix.

## 8. Phase 8: Targeted Test Verification (Last Phase)

- [ ] 8.1 Add/adjust targeted tests for border lifecycle, DM centering, Cyrillic envelope, and hit-zone alignment.
- [ ] 8.2 Run focused suites after user-approved visual checkpoints.
- [ ] 8.3 Confirm final pass criteria: visual parity restored, no known false-path patches reintroduced.
