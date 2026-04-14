## 1. Highlight Algorithm Fixes

- [ ] 1.1 Update `calculate_highlight_stack` runtime check to validate `data.time` against full subtitle interval `[start_time - window, end_time + window]`.
- [ ] 1.2 Modify sequence matching to fail cleanly if `get_relative_word` returns nil by adding `if not rw` boundary abort.
- [ ] 1.3 Add strict context substring bounds validation (with leading/trailing or spaced borders) in Phase 2 Context validation to prevent substring overlaps.

## 2. Refinement and QA

- [ ] 2.1 Verify contiguous text properly triggers correct highlighted colors.
- [ ] 2.2 Verify split text properly triggers `FF88B0` highlight code path without false overlaps.
