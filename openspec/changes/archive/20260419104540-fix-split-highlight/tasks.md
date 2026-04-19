## 1. Engine Hardening & Precision

- [x] 1.1 Complete transition from Single-Pivot to Multi-Pivot grounding system.
- [x] 1.2 Implement `L:W:T` tri-coordinate parsing in `calculate_highlight_stack`.
- [x] 1.3 Add temporal epsilon (+1ms) to all Anki exporter timestamps to prevent boundary drift.
- [x] 1.4 Refactor Phase 1 (Orange) identifier to prioritize grounded anchors over fuzzy context.
- [x] 1.5 Eliminate 10s hardcoded gap limit in the word-traverser; link to `anki_split_gap_limit`.

## 2. Configuration & Integration

- [x] 2.1 Expose all search windows and gap limits to `mpv.conf` with detailed documentation.
- [x] 2.2 Synchronize default fallbacks in `lls_core.lua` with `mpv.conf` initial values.
- [x] 2.3 Ensure "Anki Global" toggle compatibility across all identification phases.
- [x] 2.4 Fix coordinate scope bug in `dw_anki_export_selection` causing missing indices.

## 3. Optimization & Validation

- [x] 3.1 Implement recursive result caching on subtitle tokens to maintain 144fps rendering speed.
- [x] 3.2 Add lazy-caching for `term_clean` and `__pivots` parsing.
- [x] 3.3 Verify 100% precision for large (40+ word) range selections spans lines.
- [x] 3.4 Audit code for legacy regex-find patterns; convert all to plain-string or word-iterators.
