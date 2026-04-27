# Technical Design: Fix Performance Regression and Smart Joiner Integration

## System Architecture Updates
1.  **`get_center_index` Refactoring**:
    - The dual implementation will be consolidated into a single function.
    - We will retain the binary search algorithm to ensure $O(\log N)$ performance.
    - We will augment the binary search with a "nearest neighbor" post-processing step if the target `time_pos` falls outside the bounds of the returned active subtitle. This will replicate the behavior of the linear search's precision grounding without the $O(N)$ penalty.
2.  **TSV Export Composition (`compose_term_smart`)**:
    - In `dw_anki_export_selection` and `ctrl_commit_set`, the `term` string assembly logic currently uses raw space concatenation (`table.concat(parts, " ")` or manual string building).
    - This logic will be intercepted right before `save_anki_tsv_row` is called. The extracted tokens for the term will be passed through `compose_term_smart` to produce the final, properly spaced string.

## Component Interactions
1.  **`lls_core.lua: get_center_index`**:
    - Called heavily by `master_tick` and navigation commands.
    - The unified function will ensure all subsystems agree on what constitutes the "active" or "centered" subtitle at any given timestamp.
2.  **`lls_core.lua: dw_anki_export_selection` & `ctrl_commit_set`**:
    - Both functions gather subtitle text fragments.
    - We will replace the final `term = table.concat(...)` steps with a call to `compose_term_smart`.

## Error Handling & Edge Cases
1.  **Binary Search Bounds**: Ensure the binary search properly handles edge cases such as `time_pos` being before the first subtitle or after the last subtitle.
2.  **Empty Tokens**: Ensure `compose_term_smart` gracefully handles empty or nil token lists when reconstructing the exported term.
