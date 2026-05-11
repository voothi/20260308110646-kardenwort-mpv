## 1. Preparation

- [x] 1.1 Verify current hit-testing behavior in Drum Mode using IPC tests (if applicable) or manual validation notes.

## 2. Hit-Testing Logic Implementation

- [x] 2.1 Modify `drum_osd_hit_test` in `scripts/lls_core.lua` to implement vertical proximity snapping.
- [x] 2.2 Add horizontal alignment check to ensure snapping only occurs when within text bounds.
- [x] 2.3 Implement the 60px vertical threshold for snapping.

## 3. Validation

- [x] 3.1 Verify RMB (tooltip) behavior in Drum Mode: should trigger even when clicking in gaps between lines.
- [x] 3.2 Verify LMB (selection) behavior in Drum Mode: should update cursor focus when clicking in gaps.
- [x] 3.3 Ensure no regressions in Drum Window hit-testing.
- [x] 3.4 Ensure no regressions in standard SRT mode hit-testing.
