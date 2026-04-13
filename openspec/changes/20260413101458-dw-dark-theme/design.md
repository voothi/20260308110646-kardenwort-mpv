## Context

The Drum Window was rendering a solid beige panel for read-ability (`dw_bg_color=A9C5D4`). However, since the Anki Highlighting feature heavily leverages green overlay tags (e.g., `#71CC2E`), this created unreadable color mixing between beige and green. The standard `c` sub mode handles this natively by relying on MPV's dark translucent `background-box`. 

## Goals / Non-Goals

**Goals:**
- Unify Drum Window `w` mode visuals to match the standard `c` mode dark background stringency.
- Retain existing rendering coordinate logic and functionality.
- Ensure Search UI dropdown / tooltips remain distinctly visible over a darker canvas.

**Non-Goals:**
- Do not refactor `draw_dw` positioning or ASS coordinate mounting logic.

## Decisions

- **Color Palette Modifications**: We are moving from a beige/dark-text theme to a dark-mode palette via direct option updates in `mpv.conf` and `lls_core.lua`:
  - `dw_bg_color=000000`, `dw_bg_opacity=60` (translucent black film over video)
  - `dw_text_color=CCCCCC` (dimmer context lines)
  - `dw_highlight_color=00FFFF` (neon cyan for hovering)
  - `dw_tooltip_bg_color=222222`, `dw_tooltip_bg_opacity=11` (fully opaque dark gray tooltips)
  - `search_hit_color=0088FF`, `search_sel_color=FF0000` (neon match variants)
  *Rationale*: This change mirrors how standard MPV subtitles are naturally presented, bypassing the green/beige accessibility issue with zero algorithmic logic changes.

## Risks / Trade-offs

- [Risk] Tooltips and dropdown interfaces blending into a dark translucent background.
  → Mitigation: Setting interface modals like tooltips to a distinct opaque dark gray (`222222`) so they clearly segment and elevate from the translucent black canvas beneath them.
