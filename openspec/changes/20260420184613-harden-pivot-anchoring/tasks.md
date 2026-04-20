## 1. Fractional Indexing Hardening (Gap 3)

- [x] 1.1 Update `build_word_list_internal` to implement `0.1` incremental indexing for non-word tokens.
- [x] 1.2 Implement `0.0001` epsilon buffer for all logical index comparisons (hit-testing, selection).
- [x] 1.3 Update `dw_hit_test` to support fractional word selection.

## 2. Phase 2 Highlighting (Gap 2)

- [x] 2.1 Update `calculate_highlight_stack` to include `green_stack` tracking.
- [x] 2.2 Implement same-segment detection for fragmented phrase matches.
- [x] 2.3 Integrate `anki_highlight_depth_local` (Green) palette into `draw_dw`.

## 3. Marker-Injection Anchoring (Gap 1)

- [x] 3.1 Update `extract_anki_context` to prioritize `coord_map` over geometric `pivot_pos`.
- [x] 3.2 Update `dw_anki_export_selection` call-sites.
- [x] 3.3 Implement `+/- 1` segment drift tolerance in logical anchor resolution.

## 4. Verification

- [ ] 4.1 Verify bracket/punctuation selection precision.
- [ ] 4.2 Validate Green highlights on single-line fragmented matches.
- [ ] 4.3 Test "Scene-Locked" extraction on segments with repeated terms.
