## 1. Ground Truth Verification

- [x] 1.1 **Grounding Format**: Verify that the `SentenceSourceIndex` in the TSV now contains the `L:W:T` coordinate map for all new exports.
- [x] 1.2 **Interaction Shield**: Check that `DW_MOUSE_LOCK_UNTIL` is correctly set and enforced during rapid terminal/remote navigation.
- [x] 1.3 **Selection Persistence**: Confirm that `FSM.DW_CTRL_PENDING_SET` is not cleared on modifier-key release and correctly requires a Context-Aware `ESC` press for cleanup.
- [x] 1.4 **Color Flow**: Verify the **Gold focus -> Orange match** and **Pink select -> Purple match** visual pipelines.
- [x] 1.5 **Temporal Bridging**: Test highlight continuity with a 5-second gap between segments to ensure the 60.0s rule is active.

## 2. Specification Archival

- [ ] 2.1 **Run Archive**: Execute `openspec archive --change 20260420075549-align-specs-to-v1-44-2` to permanently merge these requirements into the core project specifications.
