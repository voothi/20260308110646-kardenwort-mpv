## 1. Tests Preparation

- [x] 1.1 Create automated acceptance tests to verify Drum Mode / SRT mode paired selection visual feedback. Test should inject `f` actions and verify that `FSM.DW_CTRL_PENDING_SET` receives the item AND the visual state (`drum_osd` contents) properly reflects the Pink set immediately.

## 2. Implementation

- [x] 2.1 Update `ctrl_toggle_word` in `scripts/lls_core.lua` to trigger a UI update for Drum Mode and SRT mode when a word is toggled into or out of the pink set.
- [x] 2.2 Verify that the `master_tick` or `tick_drum` dependencies resolve correctly and draw the updated OSD content immediately upon interaction.
