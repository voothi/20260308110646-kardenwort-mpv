## Context

The user is restoring and migrating visual improvements to `main.lua` on branch `20260524120415` (rolled back to v1.82.26). Prior attempts accumulated complexity and regressions, specifically with OSD window backgrounds, outline transparency stacking under `background-box` mode, horizontal alignment in fullscreen Drum Mode (DM), and mouse dragging desyncs.

## Goals / Non-Goals

**Goals:**
- Provide a clean, minimally invasive transfer of spacers and margins.
- Decouple line-wrapping heights from inter-subtitle gaps.
- Render a single cohesive vector background card for the Drum Window (DW) and Tooltips instead of line-by-line frames.
- Support localized outline/shadow transparency overrides for `background-box` style compatibility without breaking global OSD overlays (console, upper subtitles).
- Horizontally center the translation tooltip in fullscreen Drum Mode (DM) and place it cleanly in the secondary subtitle track OSD region.
- Grant selection parity for trailing punctuation (e.g. periods, question marks) inside DM.
- Keep runtime safety local and narrow (only where instability is proven), avoiding broad global shims.

**Non-Goals:**
- Refactoring `main.lua`'s architecture or changing its structural modules.
- Introducing complex performance changes or unnecessary test runner ports at this stage.
- Running large/broad suites before prototype visuals are approved.

## Decisions

### 1. Sequencing Strategy (Selected)
- **Option A**: Start with renderer rewrites and patch lifecycle issues later.
- **Option B (Selected)**: Stabilize lifecycle/border behavior first, then apply geometry/rendering rewrites.
- *Rationale*: Foundational lifecycle correctness reduces false regressions during visual migration.

### 2. Tooltip Scope Guard (Selected)
- **Option A**: Apply centering whenever `DRUM_WINDOW == "OFF"`.
- **Option B (Selected)**: Apply centering only when DM is active (`FSM.DRUM == "ON"` and `FSM.DRUM_WINDOW == "OFF"`).
- *Rationale*: Preserves SRT tooltip behavior and avoids cross-mode regressions.

### 3. Spacing and Margin Decoupling (Selected)
- **Option A**: Keep duplicate inline formulas across render and hit-test.
- **Option B (Selected)**: Use shared helpers (`vline_height(fs)`, `calculate_block_top(raw_top, total_h)`) and consume them consistently.
- *Rationale*: Prevents geometry drift between displayed text and interactive bounds.

### 4. Unified Card Rendering (Selected)
- **Option A**: Keep per-line background frames.
- **Option B (Selected)**: Use a single vector card (`\p1`) with absolute line positioning.
- *Rationale*: Produces cohesive visuals while keeping precise word-level interaction.

### 5. `background-box` Compatibility (Selected)
- **Option A**: Only global `osd-border-style` override.
- **Option B**: Only local ASS alpha masking.
- **Option C (Selected)**: Layered strategy: stable lifecycle override + local alpha compatibility tags where needed.
- *Rationale*: Minimizes leakage and remains robust across overlay combinations.

### 6. Safety Scope (Selected)
- **Option A**: Add global startup callback shim.
- **Option B (Selected)**: Add narrow, local guards only at proven unstable registration points.
- *Rationale*: Avoids local-variable pressure and broad side effects from previous failed patterns.

## Mechanics (Baseline Standard: `20260523152149`)

The behavioral baseline standard for DW overflow geometry and pointer accuracy is branch `20260523152149`. This section is the canonical mechanics contract for this change.

### Geometry Contract (from `dw_calculate_block_top`)

1. Use `base_h = Options.font_base_height or 1080`, `center_y = base_h / 2`, and `edge_margin = Options.dw_edge_margin or 0`.
2. Start from centered placement: `block_top = center_y - (total_height / 2)`.
3. Trigger overflow anchoring only when `total_height > base_h - 2 * edge_margin`.
4. In overflow mode, accumulate `offset_y` from layout top to `view_center` midpoint:
   - Add each preceding `entry.height`.
   - Add inter-subtitle gaps with the same render/hit-test function: `calculate_sub_gap("dw", line_fs, Options.dw_line_height_mul, Options.dw_vsp)`.
   - On `entry.sub_idx == view_center`, add `entry.height / 2` and stop.
5. If `view_center` was found, set `block_top = center_y - offset_y`.
6. Apply baseline overflow clamping exactly:
   - If `block_top > edge_margin`, set `block_top = edge_margin`.
   - Else if `block_top + total_height < base_h - edge_margin`, set `block_top = base_h - edge_margin - total_height`.
7. Use this same `block_top` result in both rendering and hit-testing; no independent y-origin math is allowed.
8. DW text block anchoring must be top-centered (`\an8`) at dynamic `\pos(960, block_top)`, not fixed center (`\an5` at `y=540`).

### Hit-Accuracy Contract (from `draw_dw` + `dw_hit_test`)

1. Build `DW_HIT_ZONES` and `DW_LINE_Y_MAP` from the exact same `current_y` progression used to render lines.
2. Preserve wrapped-line spacing with `dw_vline_height()` and inter-subtitle spacing with `calculate_sub_gap(...)` in both visual and interactive paths.
3. Vertical clamping must follow baseline semantics:
   - `osd_y <= first_zone.y_top` maps to the first selectable word of the first zone.
   - `osd_y >= last_zone.y_bottom` maps to the last selectable word of the last zone.
4. If cursor y is between adjacent zones (`zone.y_bottom < y < next_zone.y_top`), map to the preceding zone (stable no-flicker behavior).
5. Horizontal clamping must be strict to line bounds:
   - Left of line (`rel_x <= 0`) maps to first selectable word.
   - Right of line (`rel_x >= total_width`) maps to last selectable word.
6. In-line word resolution must use nearest horizontal center (`x_offset + width / 2`).
7. If the selected visual zone has no selectable words, fallback through `dw_resolve_neighbor_word(...)` within the same subtitle.
8. Keep mode scope strict: DM-only tooltip centering guard remains enabled; SRT behavior remains unchanged.

### Acceptance Checks (Hit Accuracy + Geometry)

1. Start-of-file overflow: first subtitle is reachable by scroll; top pin behavior can settle at `block_top = edge_margin`; top-region hover/click selects expected first words.
2. End-of-file overflow: last subtitle is reachable by scroll; bottom pin behavior can settle at `block_top = base_h - edge_margin - total_height`; bottom-region hover/click selects expected last words.
3. Top/middle/bottom pointer checks: each region maps to expected line/word without vertical drift.
4. Between-line gap checks: hovering the gap consistently selects the preceding visual line (no jitter/flicker).
5. Scroll continuity checks: repeated wheel/UP/DOWN does not desynchronize pointer-to-word mapping.
6. Cross-mode safety: SRT tooltip geometry and hit behavior remain unchanged after DM updates.

## Risks / Trade-offs

- **[Risk]** The Lua 200 local variable limit might be exceeded by adding new helpers.
  - **[Mitigation]** Use scoped helper blocks/tables and avoid broad new top-level local declarations.
- **[Risk]** Hover hit zones might mismatch centered text in DM.
  - **[Mitigation]** Re-align mouse bounds in `dw_tooltip_hit_test` using the centered `960 - line_w / 2` calculation.
- **[Risk]** Changing tooltip alignment logic can regress SRT mode.
  - **[Mitigation]** Apply DM-only guards and keep SRT path unchanged.
- **[Risk]** Large hit-test rewrites can create unrelated regressions.
  - **[Mitigation]** Defer full hit-test architecture changes unless residual drift is confirmed after visual phases.
- **[Risk]** Broad ASS tag/color edits can cause unintended visual regressions.
  - **[Mitigation]** Apply a tag-safety policy: preserve baseline text coloring and typography tags, and limit changes to local wrappers needed for `background-box` compatibility and geometry correctness.
