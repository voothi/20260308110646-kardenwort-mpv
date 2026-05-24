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
- Harden callback registrations against `nil` values.

**Non-Goals:**
- Refactoring `main.lua`'s architecture or changing its structural modules.
- Introducing complex performance changes or unnecessary test runner ports at this stage.

## Decisions

### 1. Spacing and Margin Offsets Decoupling
- **Option A (Inline calculation)**: Duplicate the formulas inside `draw_dw` and `dw_build_layout`.
- **Option B (Helper functions - Selected)**: Decouple spacing logic into `vline_height(fs)` and clamp calculations into `calculate_block_top(raw_top, total_h)`.
- *Rationale*: Option B minimizes code duplication and guarantees that rendering and hit-testing always reference the exact same mathematical model.

### 2. Single Cohesive Vector Background Card with Independent Line OSDs
- **Option A (Unified ASS Block)**: Output a single multiline OSD string (`\an5`) with newlines.
- **Option B (Vector card + Absolute single lines - Selected)**: Draw the background card using a single solid 1-point polygon event (`\p1` rectangle), then output each text line as an independent OSD event positioned absolutely.
- *Rationale*: Option B allows us to keep precise hit-zone coordinates (no line-wrapping drift) while visually presenting a single, premium background card.

### 3. Localized Transparency Override
- **Option A (Global OSD property change)**: Change the global player property `osd-border-style` on window toggle.
- **Option B (Selective transparency masking - Selected)**: Prepend selective alpha tags (`\3a&HFF&` and `\4a&HFF&`) to OSD text strings when in background-box mode, and use nested `manage_ui_border_override()` calls.
- *Rationale*: Option B avoids overriding the border styles of console and native subtitles, resolving visual leakage.

### 4. Fullscreen Tooltip Centering (DM)
- **Option A (Right-aligned fallback)**: Preserve the right-aligned `X = 1800` layout in both modes.
- **Option B (Centered layout for DM - Selected)**: When `DRUM_WINDOW` is `OFF`, dynamically center the tooltip horizontally at `X = 960` with top-center alignment (`\an8`) and calculate margins relative to the text center.
- *Rationale*: Option B preserves the visual balance of the fullscreen interface.

## Risks / Trade-offs

- **[Risk]** The Lua 200 local variable limit might be exceeded by adding new helpers.
  - **[Mitigation]** Define the new spacing and coordinate helpers inside the global `DW_HELPERS` table or wrap them in isolated scoping blocks.
- **[Risk]** Hover hit zones might mismatch centered text in DM.
  - **[Mitigation]** Re-align mouse bounds in `dw_tooltip_hit_test` using the centered `960 - line_w / 2` calculation.
