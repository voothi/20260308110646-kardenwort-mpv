# Tasks: Fix Drum Window Navigation Double-Tap

## Implementation
- [ ] **Helper Function**: Implement `cmd_dw_seek_delta(dir)` in `lls_core.lua`. <!-- id: 0 -->
- [ ] **Update Bindings**: Update `a`, `d`, `ф`, `в` bindings in `manage_dw_bindings`. <!-- id: 1 -->

## Verification
- [ ] **Manual Test: Autopause Navigation**: Trigger autopause, verify `d` jumps to next sub on first press. <!-- id: 2 -->
- [ ] **Manual Test: Reverse Navigation**: Verify `a` jumps to previous sub correctly. <!-- id: 3 -->
