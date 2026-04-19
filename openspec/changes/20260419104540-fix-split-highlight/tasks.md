## 1. Engine Hardening

- [x] 1.1 Expand split-phrase search window to +/- 10 lines in `calculate_highlight_stack`.
- [x] 1.2 Increase per-subtitle temporal gap limit to 12.0 seconds.
- [x] 1.3 Implement `best_unanchored_tuple` fallback for inaccuracies in TSV `SentenceSourceIndex`.
- [x] 1.4 Generalize ellipsis detection to match `...` with or without whitespace.

## 2. Export & UI Sync

- [x] 2.1 Update `ctrl_commit_set` to correctly anchor exports using `members[1].word`.
- [x] 2.2 Clean up indentation in `load_anki_mapping_ini`.
- [x] 2.3 Verify fix by toggling the Drum Window (refreshes TSV and applies new logic).
