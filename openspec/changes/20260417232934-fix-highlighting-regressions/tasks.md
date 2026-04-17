## 1. Core Logic Fixes (lls_core.lua)

- [x] 1.1 Fix `get_relative_word_text` to correctly adjust `target_logical_idx` when moving forward/backward across subtile segments.
- [x] 1.2 Update `calculate_highlight_stack` Phase 1/Phase 2 to remove the word threshold color override for contiguous matches.
- [x] 1.3 Restore the word merging logic in `load_sub` for ASS tracks.
- [x] 1.4 Optimize `calculate_highlight_stack` by caching `sub.word_count` to avoid repeated counting.

## 2. Selection & Export Standardization

- [x] 2.1 Refactor `dw_anki_export_selection` to use `get_sub_tokens` and token-based iteration for phrase and context extraction.
- [x] 2.2 Verify that Anki export context anchoring via `target_pos` remains robust after tokenization changes.

## 3. Verification

- [x] 3.1 Verify that words at subtitle boundaries (overlap window) are correctly highlighted based on neighbors.
- [x] 3.2 Verify that long contiguous phrases in Mode W are Orange (not Purple).
- [x] 3.3 Verify that split phrases (scattered words) remain Purple.
