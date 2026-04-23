# Tasks: Drum Window Hit-Test Calibration

## 1. Logic Implementation
- [x] Add `dw_vline_h_mul`, `dw_sub_gap_mul`, and `dw_char_width` to `Options`
- [x] Update `handle_mouse_event` to use multipliers in grid calculations
- [x] Integrate multipliers into horizontal (character-level) selection logic

## 2. Calibration
- [x] Establish baseline values for `dw_font_size=34` (Consolas)
- [x] Verify vertical selection accuracy across multiple context lines
- [x] Verify horizontal selection accuracy for short and long words

## 3. Configuration
- [x] Organize `mpv.conf` into calibration "Modes"
- [x] Provide templates for common font size overrides
- [x] Update documentation to explain hit-test tuning
