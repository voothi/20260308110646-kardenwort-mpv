# Technical Design: Fix Performance Regression and Smart Joiner Integration

## System Architecture Updates
1.  **`get_center_index` Refactoring**:
    - The dual implementation will be consolidated into a single function.
    - We will retain the binary search algorithm to ensure $O(\log N)$ performance.
    - We will augment the binary search with a "nearest neighbor" post-processing step if the target `time_pos` falls outside the bounds of the returned active subtitle. This will replicate the behavior of the linear search's precision grounding without the $O(N)$ penalty.
2.  **TSV Export Composition (`compose_term_smart`)**:
    - In `dw_anki_export_selection` and `ctrl_commit_set`, the term assembly will pass token lists through `compose_term_smart`.
    - This ensures that punctuation-aware spacing is applied to exported terms, matching the OSD behavior.
3.  **Drum Mode Hit-Zone Calibration**:
    - **`drum_upper_gap_adj`**: A new numeric option to apply a vertical offset to hit-zones of lines above the center (active) line.
    - **Cumulative Tracking**: In `draw_drum`, the hit-zone `cur_y` tracking will accumulate this adjustment for each upper line, ensuring the entire hit-zone block scales correctly and remains anchored at the bottom (`\an2`).

## Component Interactions
1.  **`lls_core.lua: get_center_index`**: Unified $O(\log N)$ function used by all subsystems.
2.  **`lls_core.lua: draw_drum`**: Modified to accumulate `adj` into `total_h` and `cur_y` logic.
3.  **`lls_core.lua: drum_osd_hit_test`**: Indirectly benefits from the updated metadata in `FSM.DRUM_HIT_ZONES`.

## Error Handling & Edge Cases
1.  **Boolean Ternaries**: Fix all ternary expressions like `is_drum_mode and Options.drum_double_gap or Options.srt_double_gap` that fail when the second term is boolean `false`. Use table lookups (`Options[prefix .. "_double_gap"]`) instead.
2.  **Cumulative Drift**: Ensure that `adj` is ONLY applied to upper lines to prevent shifting the active or lower context lines.
