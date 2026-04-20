## 1. Core Logic Refined

- [x] 1.1 Implement logic to inject `___PIVOT_MARKER___` into segment tokens at `logical_idx`.
- [x] 1.2 Refactor `dw_anki_export_selection` range/point export to calculate pivot via marker detection in the final cleaned `context_line`.
- [x] 1.3 Refactor `ctrl_commit_set` non-contiguous export to calculate pivot via marker detection in the final cleaned `full_ctx_text`.
- [x] 1.4 Ensure the marker is strictly removed from the final `extracted_context` before database save.

## 2. Verification

- [x] 2.1 Add temporary debug prints to verify `pivot_pos` offsets match expected character positions in duplicate-word scenarios.
