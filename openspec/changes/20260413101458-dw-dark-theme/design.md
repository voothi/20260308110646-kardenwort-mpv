## Context

The Drum Window currently renders a large centered vector rectangle as a background. The standard Drum Mode (`c`), however, uses localized background boxes per line (via `osd-border-style=background-box`). To achieve a unified "Pro" aesthetic, the Drum Window must transition to this line-based box model, removing global screen-darkening and aligning its font/border parameters with the standard subtitle environment.

## Goals / Non-Goals

**Goals:**
- Unify Drum Window `w` mode visuals to match the standard `c` mode line-based background boxes.
- Remove global background vectoring in favor of localized MPV-native background boxes.
- Synchronize text parameters (borders, shadows, opacity) between `c` and `w` modes.
- Achieve a high-recall visual style where key terms pop identically across all modes.

**Non-Goals:**
- Do not refactor `draw_dw` multi-line wrap logic or coordinate mounting.

## Decisions

- **Environmental Unification**:
  - **Remove Background Vector**: In `draw_dw`, remove the code that draws the `{\p1}m 0 ...` rectangle.
  - **Restore OSD Border/Shadow**: Remove the `{\\bord0}{\\shad0}{\\blur0}{\\1a&H00&}{\\3a&HFF&}{\\4a&HFF&}` overrides.
  - **Font Size Normalization**: Increase `dw_font_size` to `38` to compensate for the visual "thinness" of monospace `Consolas` compared to the proportional font used in `c` mode.

- **Tooltip Unification**:
  - **Sync Opacity**: Set `dw_tooltip_bg_opacity=60` to match the Drum Window's translucent look.
  - **Sync Text Parameters**: Update `draw_dw_tooltip` to use `Options.dw_text_color` (`CCCCCC`) as the primary text color, ensuring consistency with the Window's context display.

- **Anki Highlight Transition**:
  - Reverting Green overrides to the core Orange/Gold levels: `0075D1`, `005DAE`, `003A70`.

- **Search HUD Refinement**:
  - `search_sel_color=FFFFFF` (White) to ensure selected items are readable without a blue "wash".

*Rationale*: Moving to native background boxes reduces rendering overhead and ensures that the player's UI feels like a single coherent system rather than two separate rendering engines.

## Risks / Trade-offs

- [Risk] Loss of global background darkening for readability.
  → Mitigation: The native `background-box` provides excellent line-level contrast. If global darkening is still needed, a separate `dw_global_dim` option could be introduced, but current focus is on OSD-parity.
