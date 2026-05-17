## 1. Core Implementation

- [x] 1.1 Update `load_anki_tsv` to parse and dynamically assign unique identity keys (`__entry_key`) for each highlight row.
- [x] 1.2 Update `save_anki_tsv_row` to generate matching in-memory identity keys upon saving new records.
- [x] 1.3 Modify highlight evaluation in `calculate_highlight_stack` to use `__entry_key` instead of raw `term` for deduplication in `matched_terms`.
- [x] 1.4 Update split-match validation caching in `calculate_highlight_stack` to index by `__entry_key` instead of raw `term` to isolate adjacent cache keys.

## 2. Verification and Tests

- [x] 2.1 Create regression test suite `tests/acceptance/test_20260517103917_independent_highlights.py` verifying identical adjacent highlights render independently.
- [x] 2.2 Run full test suite using `pytest` to confirm regression-free behavior.

