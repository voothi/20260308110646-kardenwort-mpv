## 1. Engine Hardening

- [x] 1.1 Expand split-phrase search window to +/- 10 lines in `calculate_highlight_stack`.
- [x] 1.2 Increase per-subtitle temporal gap limit to 12.0 seconds.
- [x] 1.3 Implement `best_unanchored_tuple` fallback for inaccuracies in TSV `SentenceSourceIndex`.
- [x] 1.4 Generalize ellipsis detection to match `...` with or without whitespace.

## 2. Export & UI Sync

- [x] 2.1 Update `ctrl_commit_set` and `dw_anki_export_selection` to export advanced pivot coordinates (`L_OFF:W_IDX:T_POS`).
- [x] 2.2 Implement multi-segment Pivot Grounding in both Phase 1 (Contiguous) and Phase 2 (Split) search engines.
- [x] 2.3 Verify fix by toggling the Drum Window and checking console for `Pivot Grounding` messages.
- [x] 2.4 Hardened "Large Chunk" lookup by increasing segment safety (20) and gap (10s) limits.
- [x] 2.2 Clean up indentation in `load_anki_mapping_ini`.
