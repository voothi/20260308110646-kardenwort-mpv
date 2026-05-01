## Context

The `populate_token_meta` function is the central engine for colorizing interactive tokens. Historically, it relied on a rigid set of global `dw_` options, which made it impossible to tune selection brightness independently for secondary tracks or specific viewing modes (SRT/Drum). As the project moves toward a "Unified interactivity and highlighting schema," we must decouple these visual markers from their hardcoded origins to support different display environments (e.g., contrasting primary vs. secondary track luminance).

## Goals / Non-Goals

**Goals:**
- Decouple selection highlighting from the global `dw_` namespace for all modes.
- Enable independent color calibration for Tooltip, Drum Mode (Pri/Sec), and SRT Mode (Pri/Sec).
- Preserve $O(1)$ rendering performance via efficient color parameter passing.

**Non-Goals:**
- Fragmenting the core logic (keeping a single source of truth for selection rules).
- Changing default aesthetic values (maintaining backward compatibility).

## Decisions

### 1. Parameterized Palette Injection
`populate_token_meta` is refactored to accept `h_color` and `ctrl_color` as arguments.
- **Rationale**: This shifts the responsibility of palette selection to the high-level rendering loops (`draw_dw_core`, `draw_dw_tooltip`, `draw_drum`), which already have context about the current mode and track.
- **Alternative**: Passing a "mode" string and having the service perform internal lookups was rejected as it would re-introduce coupling with the `Options` table structure.

### 3. Universal Boldness Calibration
In addition to color, highlight **boldness** is now decoupled per mode.
- **Rationale**: Solves the "visual blooming" effect where bold highlights in high-contrast contexts (like the tooltip) feel overly bright compared to the main window.
- **Implementation**: `format_highlighted_word` accepts a `force_bold` override. Rendering loops calculate this by checking `Options.anki_highlight_bold` for database matches (Priority 3) and `Options.<mode>_highlight_bold` for manual selections (Priority 1/2).

### 4. Tooltip Glow Regression Fix
The tooltip renderer was incorrectly using `\3c` for background colors.
- **Decision**: Update `draw_dw_tooltip` to use `\4c` for background/shadow color and set both `\3c` and `\4c` to the same `bg_color`.
- **Rationale**: Resolves the "brighter and bolder" visual discrepancy (white shadow bleed) while ensuring a consistent dark aesthetic across all screens.

## Risks / Trade-offs

- **[Risk] Configuration Complexity** → **Mitigation**: New options default to legacy values (`false` for selections), maintaining the clean look of the current Drum Window calibration while allowing power users to opt into boldness where needed.
