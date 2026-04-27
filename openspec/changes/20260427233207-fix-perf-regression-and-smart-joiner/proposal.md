# Proposal: Fix Performance Regression and Smart Joiner Integration

## Context
During a regression and compliance audit of `lls_core.lua`, several critical issues were identified:
1. **Performance Regression**: The function `get_center_index` is defined twice. The local linear scan ($O(N)$) shadows the global binary search ($O(\log N)$), causing overhead in the rendering loop.
2. **Missing Smart Joiner**: TSV exports concatenate tokens using manual spaces, failing to use `compose_term_smart` and violating punctuation spacing rules.
3. **Drum Mode Hit-Zone Drift**: In single-gap mode (`drum_double_gap=no`), the hit-zones for upper subtitles drift vertically relative to the visual text due to cumulative font-rendering offsets.

## Proposed Changes
1. **Consolidate `get_center_index`**: Consolidate into a single $O(\log N)$ binary search with nearest-neighbor grounding for precision gaps.
2. **Integrate `compose_term_smart`**: Refactor `dw_anki_export_selection` and `ctrl_commit_set` to use the smart joiner for all TSV exports.
3. **Calibrate Drum Mode Hit-Zones**: Implement a cumulative gap adjustment (`drum_upper_gap_adj`) to allow precise alignment of hit-zones for upper subtitles in single-gap mode.

## Impact
- **Performance**: Logarithmic centering reduces CPU overhead.
- **Accuracy**: TSV exports correctly preserve punctuation-aware spacing.
- **Interactivity**: Drum Mode click detection perfectly aligns with visual text on all lines.

## Anchors
- 20260427231237
- 20260427231418
- 20260427163737
- 20260427233113
- 20260427233552
- 20260427234608
- 20260428000144
- 20260428000439
- 20260428001440
- 20260428002045
