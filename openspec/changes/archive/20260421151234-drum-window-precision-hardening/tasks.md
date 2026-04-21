## 1. Core Logic Hardening

- [x] 1.1 Implement L_EPSILON constant (0.0001) for standardized float comparisons
- [x] 1.2 Implement absolute shadow footprint calculations in `load_anki_records`
- [x] 1.3 Update `calculate_highlight_stack` to use footprint shadow checks for nesting and intersections

## 2. Rendering precision (Pass 2)

- [x] 2.1 Refactor `calculate_highlight_stack` to return type-safe `{text, is_split}` match metadata
- [x] 2.2 Implement "Private Stack Check" for punctuation in `draw_drum_window` (Pass 2) to resolve Brick bleed

## 3. Export engine (Pixel-Perfect)

- [x] 3.1 Refactor `dw_anki_export_selection` to use strict fractional range filters
- [x] 3.2 Implement "Infinity Boundary" logic for non-terminal lines of multi-line selections
- [x] 3.3 Ensure terminal punctuation is strictly excluded if not hovering, as per the 20260421141721 anchor
