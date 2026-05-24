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

## Risks / Trade-offs

- **[Risk]** The Lua 200 local variable limit might be exceeded by adding new helpers.
  - **[Mitigation]** Use scoped helper blocks/tables and avoid broad new top-level local declarations.
- **[Risk]** Hover hit zones might mismatch centered text in DM.
  - **[Mitigation]** Re-align mouse bounds in `dw_tooltip_hit_test` using the centered `960 - line_w / 2` calculation.
- **[Risk]** Changing tooltip alignment logic can regress SRT mode.
  - **[Mitigation]** Apply DM-only guards and keep SRT path unchanged.
- **[Risk]** Large hit-test rewrites can create unrelated regressions.
  - **[Mitigation]** Defer full hit-test architecture changes unless residual drift is confirmed after visual phases.
