## 1. Core Rendering Logic

- [x] 1.1 Update `format_highlighted_word` signature to accept `bg_color` and `bg_alpha`.
- [x] 1.2 Implement surgical tag injection in `format_highlighted_word` with explicit `\3c`, `\4c`, `\3a`, and `\4a` locks.
- [x] 1.3 Audit `draw_dw` rendering loop: move `bg_alpha` definition to the top and pass to formatter.
- [x] 1.4 Audit `draw_drum` rendering loop: calculate `bg_alpha` per-mode and pass to formatter.
- [x] 1.5 Audit `draw_dw_tooltip` rendering loop: move `bg_alpha` definition to the top and pass to formatter.

## 2. Aesthetic Calibration

- [x] 2.1 Synchronize global border and shadow alphas to use `calculate_ass_alpha(bg_opacity)` in all `draw_` functions to restore transparency.
- [x] 2.2 Enforce `{\b0}` (regular weight) for manual selection highlights (Priority 1 and 2).
- [x] 2.3 Verify opaque outline sharpness for interactive highlights to eliminate blooming regressions.
- [x] 2.4 Confirm "Premium" font weight consistency across all modes (SRT, Drum, DW, Tooltip).
