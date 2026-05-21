## 1. Core Drum Window Enhancements

- [ ] 1.1 Implement dw_calculate_block_top and update draw_dw and dw_hit_test call sites to use unified positioning
- [ ] 1.2 Implement dynamic safe-area clamping with configurable dw_edge_margin (defaulting to 24px)
- [ ] 1.3 Implement decoupled wrap spacing using dw_wrap_line_height_mul (defaulting to 1.05) inside visual layout rendering

## 2. Click Interactivity and Styling Fixes

- [ ] 2.1 Cache active OSD coordinates in FSM.DW_HIT_ZONES and restore it on cache-hits within DW_DRAW_CACHE
- [ ] 2.2 Re-architect dw_hit_test to perform lookup directly against the cached FSM.DW_HIT_ZONES
- [ ] 2.3 Restore local variables fs and line_height in draw_dw_tooltip to prevent string.format nil exceptions
- [ ] 2.4 Remove is_word restriction in draw_drum to allow sentence-ending punctuation selectability

## 3. Verification and Polish

- [ ] 3.1 Implement targeted acceptance tests covering dynamic top alignment, scrolling, bottom clamping, and edge margins
- [ ] 3.2 Add regression tests for zero margin conditions
- [ ] 3.3 Run regression suites to ensure 100% success on tooltip stability, copy sub fallback, and general unit tests
