# Proposal: Fix Performance Regression and Smart Joiner Integration

## Context
During a regression and compliance audit of `lls_core.lua`, two critical issues were identified:
1. **Performance Regression**: The function `get_center_index` is defined twice in `lls_core.lua`. The second (local) definition performs a linear scan $O(N)$ and shadows the intended global binary search $O(\log N)$ implementation. This causes significant performance overhead during `master_tick` evaluations.
2. **Missing Smart Joiner**: TSV exports (`dw_anki_export_selection` and `ctrl_commit_set`) concatenate tokens using a manual space delimiter (`table.concat(parts, " ")`), failing to utilize the `compose_term_smart` service. This violates Requirement 65 of `mmb-drag-export` and causes incorrect formatting for punctuated or hyphenated words (e.g., "Marken-Discount").

## Proposed Changes
1. **Consolidate `get_center_index`**: Merge the "nearest-neighbor" precision logic from the linear scan into the binary search implementation. This restores logarithmic performance while maintaining the required precision-aware active highlighting logic. Remove the duplicate local definition.
2. **Integrate `compose_term_smart`**: Refactor `dw_anki_export_selection` and `ctrl_commit_set` to use `compose_term_smart` when assembling the final exported `term`. This ensures exported terms respect the smart punctuation spacing rules natively provided by the core engine.

## Impact
- **Performance**: Subtitle centering and active line detection will execute in logarithmic time instead of linear time, significantly reducing CPU overhead during 50ms interval `master_tick` calls on large tracks.
- **Accuracy**: TSV exports will correctly preserve smart spacing for words with internal or boundary punctuation, eliminating unwanted spaces around hyphens and other specific characters.
