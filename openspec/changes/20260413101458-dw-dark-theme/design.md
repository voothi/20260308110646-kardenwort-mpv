## Context

The Drum Window was rendering a solid beige panel for read-ability (`dw_bg_color=A9C5D4`). However, since the Anki Highlighting feature heavily leverages green overlay tags (e.g., `#71CC2E`), this created unreadable color mixing between beige and green. The standard `c` sub mode handles this natively by relying on MPV's dark translucent `background-box`. 

Additionally, the Search HUD's blue selection highlight (`FF0000`) clashes with the new dark theme, and the green vocabulary highlights should be unified with the Search HUD's orange/gold motif.

## Goals / Non-Goals

**Goals:**
- Unify Drum Window `w` mode visuals to match the standard `c` mode dark background stringency.
- Transition all vocabulary highlighting (Anki) to the established Orange/Gold project palette.
- Ensure Search HUD selection is clearly readable against a dark translucent backdrop.
- Ensure Search UI dropdown / tooltips remain distinctly visible over a darker canvas.

**Non-Goals:**
- Do not refactor `draw_dw` positioning or ASS coordinate mounting logic.

## Decisions

- **Color Palette Modifications**:
  - `dw_bg_color=000000`, `dw_bg_opacity=60` (translucent black film over video)
  - `dw_text_color=CCCCCC` (dimmer context lines)
  - `dw_highlight_color=00FFFF` (neon cyan for hovering)
  - `dw_tooltip_bg_color=222222`, `dw_tooltip_bg_opacity=11` (fully opaque dark gray tooltips)
  - `search_hit_color=0088FF` (Orange match variant)
  - `search_sel_color=FFFFFF` (Pure white for selected search line to ensure text clarity)
  
- **Anki Highlight Transition**: Reverting green overrides to use the core orange levels:
  - `anki_highlight_depth_1=0075D1` (Gold/Orange)
  - `anki_highlight_depth_2=005DAE` (Amber)
  - `anki_highlight_depth_3=003A70` (Burnt Orange)

*Rationale*: This change mirrors how standard MPV subtitles are naturally presented and leverages the existing thematic colors of the script for a more professional, "branded" experience.

## Risks / Trade-offs

- [Risk] Tooltips and dropdown interfaces blending into a dark translucent background.
  → Mitigation: Setting interface modals like tooltips to a distinct opaque dark gray (`222222`) so they clearly segment and elevate from the translucent black canvas beneath them.
