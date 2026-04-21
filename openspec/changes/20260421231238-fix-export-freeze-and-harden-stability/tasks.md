## 1. Freeze Fix & Search Hardening

- [ ] 1.1 Add mandatory forward progress guard to `string.find` loops in `extract_anki_context`.
- [ ] 1.2 Implement empty-term validation in `dw_anki_export_selection` after cleaning (ASS/space stripping).
- [ ] 1.3 Add early return in `extract_anki_context` if `selected_term` is empty.
- [ ] 1.4 Audit and harden `find_fuzzy_indices` and other keyword search loops in `lls_core.lua`.

## 2. Drum Window Performance

- [ ] 2.1 Implement `FSM.DW_LAYOUT_CACHE` state variables.
- [ ] 2.2 Modify `dw_build_layout` to support caching and conditional invalidation.
- [ ] 2.3 Update `dw_hit_test` and `draw_dw` to utilize the cached layout.
- [ ] 2.4 Verify cache invalidation triggers on track changes and viewport scrolls.

## 3. TSV Update Optimization

- [ ] 3.1 Modify `save_anki_tsv_row` to perform an in-memory update of `FSM.ANKI_HIGHLIGHTS`.
- [ ] 3.2 Remove redundant `load_anki_tsv(true)` calls after adding new records.
- [ ] 3.3 Ensure the background sync timer correctly handles fingerprint mismatches for eventual consistency.

## 4. Verification & Polish

- [ ] 4.1 Verify that clicking in whitespace between words no longer causes a freeze.
- [ ] 4.2 Verify that Drum Window mouse interaction feels smoother (no O(N) layout rebuilds).
- [ ] 4.3 Verify that adding words to Anki is instantaneous without UI stutter.
