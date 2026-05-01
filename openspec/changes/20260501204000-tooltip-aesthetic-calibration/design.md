# Unified Tooltip Aesthetic Calibration

This change resolves visual rendering inconsistencies in the translation tooltip (E) by fixing a shadow color regression and implementing full parity for font weight (boldness) toggles across all UI modes.

## Problem
1. **Glow Regression**: The tooltip renderer was incorrectly using the `\3c` (border) tag for background colors while omitting the `\4c` (shadow) tag, leading to a "bright/bolder" glow effect (likely a white shadow) on dark backgrounds.
2. **Boldness Inconsistency**: The tooltip lacked independent `active_bold` and `context_bold` toggles, forcing a single `tooltip_font_bold` state on all lines, which deviated from the granular control available in Drum/SRT modes.
3. **Selection Weight**: Selections appeared "thin" because they correctly respected `tooltip_highlight_bold=no`, but they clashed with the forced bold state of the rest of the tooltip.

## Solution
1. **Fix ASS Tags**: Update `draw_dw_tooltip` to use `\4c` for background/shadow color and set both `\3c` and `\4c` to ensure a consistent, non-glowing aesthetic.
2. **Parameterize Boldness**: Add `tooltip_active_bold` and `tooltip_context_bold` to `Options` and the rendering pipeline, replacing the single `tooltip_font_bold` toggle for full architectural parity.
3. **Calibrate Defaults**: Unify defaults in `mpv.conf` to use regular weight (thin) by default across all screens, ensuring a "Premium" look.

## Verification
- [ ] Tooltip background is a clean, semi-transparent black without white glow.
- [ ] Active and context lines in the tooltip can be independently set to bold/regular.
- [ ] Selection highlights match the surrounding font weight by default but can be independently calibrated.
- [ ] No regressions in hit-testing or word-wrapping logic.
