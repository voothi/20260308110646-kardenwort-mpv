## 1. Implementation

- [x] 1.1 Refactor `cmd_cycle_sec_sid` in `scripts/lls_core.lua` to implement manual track iteration.
- [x] 1.2 Implement `external` track filtering in the cycling loop.
- [x] 1.3 Implement `sid` (primary) exclusion logic in the cycling loop.
- [x] 1.4 Update OSD rendering to include the `[X built-in hidden]` informative suffix.
- [x] 1.5 Disable the background auto-selection logic in `update_media_state` to prevent conflict loops.

## 2. Validation

- [x] 2.1 Verify that built-in tracks no longer appear in the `Shift+c` rotation.
- [x] 2.2 Verify that the primary track is correctly skipped during the secondary cycle.
- [x] 2.3 Verify that the OSD suffix accurately reflects the number of hidden internal tracks.
