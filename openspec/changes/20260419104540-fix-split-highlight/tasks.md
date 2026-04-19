## 1. Engine Hardening

- [x] 1.1 Expand split-phrase search window to +/- 10 lines in `calculate_highlight_stack`.
- [x] 1.2 Increase per-subtitle temporal gap limit to 12.0 seconds.
- [x] 1.3 Implement `best_unanchored_tuple` fallback for inaccuracies in TSV `SentenceSourceIndex`.
- [x] 1.4 Generalize ellipsis detection to match `...` with or without whitespace.

## 2. Export & UI Sync

- [x] 2.1 Update `ctrl_commit_set` to correctly anchor exports.
- [x] 2.2 Clean up indentation in `load_anki_mapping_ini`.
- [x] 2.3 Verify fix by toggling the Drum Window (refreshes TSV and applies new logic).
## 3. Ambiguity Resolution
- [x] 3.1 Implement multi-index tracking in `ctrl_commit_set` (format `offset:word_idx`).
- [x] 3.2 Update `calculate_highlight_stack` to use Level 2 grounding (Full Match) for precise disambiguation.
- [x] 3.3 Ensure backward compatibility for Level 1 (Partial) and Level 0 (Unanchored) matching.
