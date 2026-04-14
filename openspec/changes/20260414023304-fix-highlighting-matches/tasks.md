## 1. Highlight Algorithm Fixes

- [x] 1.1 Update `calculate_highlight_stack` runtime check to validate `data.time` against full subtitle interval `[start_time - window, end_time + window]`.
- [x] 1.2 Modify sequence matching to fail cleanly if `get_relative_word` returns nil by adding `if not rw` boundary abort.
- [x] 1.3 Add robust backward-scanning for TSV field parsing to handle truncated time columns.
- [x] 1.4 Restrict split_match evaluations to tightly order-matched generic word spans, eliminating sequence permutations that generate false partial matches on stop words like 'die'.

## 2. Refinement and QA

- [x] 2.1 Verify contiguous text properly triggers correct highlighted colors.
- [x] 2.2 Verify split text properly triggers `FF88B0` highlight code path without false overlaps.
