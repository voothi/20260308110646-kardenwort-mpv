## Context
Currently, `draw_dw` applies a single `\1a` (primary alpha) tag to the entire text block. To support context fading, we must move the alpha control to the line-prefix level.

## Goals / Non-Goals

**Goals:**
- Add per-line alpha control to `draw_dw`.
- Introduce `dw_active_opacity` and `dw_context_opacity` configuration options.
- Maintain compatibility with `dw_text_opacity` (perhaps by using it as a global multiplier or base).

**Non-Goals:**
- Gradient-based fading (keeping it simple with binary active/context states for now).

## Decisions

### 1. New Configuration Options
We will add the following to the `Options` table:
- `dw_active_opacity = "00"` (Default: Fully opaque)
- `dw_context_opacity = "30"` (Default: Semi-transparent, matching Drum Mode)

### 2. Rendering Refactor
In `draw_dw`, the `line_prefix` string will be updated from:
`{\fn%s}{\b%s}{\c&H%s&}`
to:
`{\fn%s}{\b%s}{\c&H%s&}{\1a&H%s&}`

The alpha value will be selected based on the `is_active` check already present in the line loop.

### 3. Cleanup
Remove the block-level `\1a` tag from the final OSD string assembly to avoid conflicts with the new per-line tags.

## Risks / Trade-offs
- **OSD Length**: Adding a `\1a` tag to every line slightly increases the ASS string length, but well within `mpv`'s limits for the typical number of lines in the Drum Window.
