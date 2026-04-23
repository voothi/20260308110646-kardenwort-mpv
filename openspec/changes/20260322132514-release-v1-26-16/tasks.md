# Tasks: Smart Font Scaling Integration

## 1. Architectural Integration
- [x] Port scaling logic from `fixed_font.lua` to `lls_core.lua`
- [x] Implement `.ass` track exclusion guard
- [x] Delete `scripts/fixed_font.lua`

## 2. Logic Implementation
- [x] Implement the "Softer Scaling" interpolation formula
- [x] Connect scaling to `font_scale_strength` option

## 3. Automation
- [x] Set up property observation for `osd-dimensions`
- [x] Set up property observation for `track-list`
- [x] Verify real-time responsiveness to window resizes

## 4. Configuration
- [x] Expose `font_scale_strength` in `mpv.conf`
- [x] Verify settings are correctly parsed from `script-opts`
