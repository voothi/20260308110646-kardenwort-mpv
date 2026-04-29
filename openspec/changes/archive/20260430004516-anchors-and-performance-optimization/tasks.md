## 1. Performance Hardening

- [x] 1.1 Implement Word-Mapped Indexing (`FSM.ANKI_WORD_MAP`) for highlight lookups.
- [x] 1.2 Implement hierarchical caching (`DRUM_DRAW_CACHE` and `sub.__layout_cache`).
- [x] 1.3 Optimize rendering loops and master tick coordinate lookups.
- [ ] 1.4 Benchmark with large (>10k) TSV files to confirm UI stability.

## 2. Precision Anchoring

- [x] 2.1 Refactor `item_index` format to support `Line:Word:Char` triplets.
- [x] 2.2 Update `prepare_export_text` (RANGE and SET modes) to respect character-offset boundaries.
- [x] 2.3 Integrate character-level capture into the Drum Window hit-test and selection logic.
- [x] 2.4 Verify that "Orange/Purple" mixing logic preserves character-level boundaries for split phrases.
