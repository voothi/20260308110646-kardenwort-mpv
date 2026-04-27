## 1. get_center_index Optimization
- [x] 1.1 Locate both definitions of `get_center_index` in `scripts/lls_core.lua`.
- [x] 1.2 Remove the local linear-scan definition.
- [x] 1.3 Modify the global binary-search definition to include nearest-neighbor grounding for gaps.

## 2. Smart Joiner TSV Export Integration
- [x] 2.1 Refactor `dw_anki_export_selection` to use `compose_term_smart`.
- [x] 2.2 Refactor `ctrl_commit_set` to use `compose_term_smart`.

## 3. Drum Mode Hit-Zone Calibration
- [x] 3.1 Implement `drum_upper_gap_adj` option in `lls_core.lua`.
- [x] 3.2 Fix the boolean ternary bug for `d_gap` evaluation in `draw_drum`.
- [x] 3.3 Update `draw_drum` to accumulate `adj` into `total_h` and `cur_y` for upper lines.
- [x] 3.4 Verify alignment with `drum_upper_gap_adj = 6` in single-gap mode.
- [x] 3.5 Update `mpv.conf` with `lls-drum_upper_gap_adj=6`.

## 4. Verification
- [x] 4.1 Verify $O(\log N)$ performance.
- [x] 4.2 Verify smart spacing in TSV exports.
- [x] 4.3 Verify perfect hit-zone alignment in Drum Mode.
