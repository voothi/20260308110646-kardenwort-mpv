## 1. Ground Truth Verification

- [ ] 1.1 **Grounding Format**: Verify that the `SentenceSourceIndex` in the TSV now contains the `L:W:T` coordinate map for all new exports.
- [ ] 1.2 **Interaction Shield**: Check that `DW_MOUSE_LOCK_UNTIL` is correctly set and enforced during rapid terminal/remote navigation.
- [ ] 1.3 **Selection Persistence**: Confirm that `FSM.DW_CTRL_PENDING_SET` is not cleared on modifier-key release and correctly requires `Ctrl+ESC` for cleanup.
- [ ] 1.4 **Color Flow**: Verify the **Gold focus -> Orange match** and **Pink select -> Purple match** visual pipelines.
- [ ] 1.5 **Temporal Bridging**: Test highlight continuity with a 5-second gap between segments to ensure the 10s rule is active.

## 2. Specification Archival

- [ ] 2.1 **Run Archive**: Execute `openspec archive --change 20260420075549-align-specs-to-v1-44-2` to permanently merge these requirements into the core project specifications.
