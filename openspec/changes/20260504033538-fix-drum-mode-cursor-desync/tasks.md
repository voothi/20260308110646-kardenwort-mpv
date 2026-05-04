## 1. Refactor Cursor Synchronization Logic

- [ ] 1.1 In `scripts/lls_core.lua`, locate the `tick_dw` function and remove the `FSM.DW_FOLLOW_PLAYER` cursor synchronization block (the logic that updates `FSM.DW_VIEW_CENTER`, `FSM.DW_CURSOR_LINE`, and `FSM.DW_CURSOR_WORD` to match `active_idx`).
- [ ] 1.2 In `scripts/lls_core.lua`, locate the `master_tick` function. Immediately following the calculation of `active_idx` (around line 5047), insert the extracted `FSM.DW_FOLLOW_PLAYER` cursor synchronization block.

## 2. Verification and Testing

- [ ] 2.1 Verify Drum Mode copy: Enter Drum Mode (Drum Window closed), use Spacebar to play, and press `Ctrl+C` at various subtitles. Ensure the copied subtitle perfectly matches the currently visible subtitle.
- [ ] 2.2 Verify Drum Window copy: Open the Drum Window, play using Spacebar, and verify that the cursor tracks correctly and `Ctrl+C` captures the correct subtitle.
- [ ] 2.3 Verify manual selections: Ensure that manually clicking a subtitle in the Drum Window still locks the cursor (setting `FSM.DW_FOLLOW_PLAYER = false`) and that pressing `a` or `d` restores follow behavior.
