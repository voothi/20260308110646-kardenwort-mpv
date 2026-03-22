# Tasks: Fix Drum Window Navigation Double-Tap

## Implementation
- [x] **Helper Function**: Implement `cmd_dw_seek_delta(dir)` in `lls_core.lua`. <!-- id: 0 -->
- [x] **Update Bindings**: Update `a`, `d`, `ф`, `в` bindings in `manage_dw_bindings`. <!-- id: 1 -->

## Verification
- [x] **Manual Test: Autopause Navigation**: Trigger autopause, verify `d` jumps to next sub on first press. <!-- id: 2 -->
- [x] **Manual Test: Reverse Navigation**: Verify `a` jumps to previous sub correctly. <!-- id: 3 -->
