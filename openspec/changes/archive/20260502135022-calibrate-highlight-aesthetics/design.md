## Context

The interactive rendering pipeline (SRT, Drum, DW, Tooltip) utilizes a shared `format_highlighted_word` utility to inject ASS color tags. Visual regressions occurred where highlights inherited semi-transparent border/shadow alphas from the global style block, leading to a blurry "blooming" effect on high-intensity colors (Yellow/Pink). Additionally, manual selections were inheriting bold weights meant only for database matches.

## Goals / Non-Goals

**Goals:**
- Eliminate visual blooming by enforcing opaque black borders for highlighted tokens.
- Enforce "Premium" regular font weight for all manual selections (Yellow/Pink).
- Maintain existing background transparency (`bg_opacity`) for the subtitle block.
- Ensure 100% visual parity across all rendering modes.

**Non-Goals:**
- Modifying the underlying tokenization or hit-testing logic.
- Changing the global font or size settings.
- Implementing new color schemes.

## Decisions

- **Parameterize Formatter with Context**: Update `format_highlighted_word` to accept `bg_color` and `bg_alpha` parameters. This allows the formatter to explicitly restore the correct visual context after the highlight, preventing "lost tags" or opacity regressions.
- **Opaque Border Override**: Explicitly inject `{\3a&H00&\4a&H00&}` into the highlight's ASS tags. Opaque borders on high-contrast colors eliminate the "muddy" blooming effect common in semi-transparent libass rendering.
- **Mandatory Weight Reset**: Inject `{\b0}` into manual selection highlights. This decouples the selection's weight from the line's `bold_state` and ensures a thin, premium look.
- **Scoping Audit**: Define `bg_alpha` at the start of each rendering function (`draw_dw`, `draw_drum`, etc.) to ensure it is available for all token-formatting calls within the loop.

## Risks / Trade-offs

- **Implementation Complexity**: Passing more parameters through the rendering loop increases boilerplate but is necessary for surgical visual control.
- **Tag Density**: Increasing the number of ASS tags per word has a negligible impact on performance but ensures aesthetic hardening against global style changes.
