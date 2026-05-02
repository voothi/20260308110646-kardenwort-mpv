## Why

Address visual regressions where interactive highlights (yellow selection, pink split-word focus) exhibit "blooming" glow effects and artificial font thickening. Ensure that manual selections adhere to a "Premium" regular font weight while maintaining sharp, high-contrast outlines across all dual-subtitle viewing modes (SRT, Drum, Drum Window, and Tooltip).

## What Changes

- **Standardized Highlight Outlines**: Explicitly inject `\3c`, `\4c`, `\3a`, and `\4a` tags into the word-formatting pipeline to lock sharp, opaque black borders for interactive tokens.
- **Transparency Synchronization**: Restore background transparency (`bg_opacity`) across all rendering layers to prevent "black box" regressions caused by global alpha overrides.
- **Font Weight Decoupling**: Enforce regular weight (`{\b0}`) for manual selections while preserving bold styling exclusively for database matches (Anki).
- **Aesthetic Calibration**: Synchronize border and shadow alphas to opaque (`00`) for text outlines to eliminate visual blooming on high-DPI displays.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `window-highlighting-spec`: Enforce regular font weight and sharp outlines for interactive selections.
- `osd-uniformity`: Standardize border and shadow alpha synchronization to eliminate blooming across all modes.
- `drum-window-high-precision-rendering`: Refine the token-level ASS tag injection model for surgical visual parity.

## Impact

- `scripts/lls_core.lua`: Modifications to `format_highlighted_word`, `draw_dw`, `draw_drum`, and `draw_dw_tooltip`.
- No impact on O(1) rendering performance or cache invalidation logic.
