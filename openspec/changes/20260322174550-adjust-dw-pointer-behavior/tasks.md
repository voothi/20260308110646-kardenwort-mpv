# Tasks: Adjust Drum Window Pointer Behavior

## Implementation

- [ ] **Initial State**: Update `cmd_toggle_drum_window` to initialize `FSM.DW_CURSOR_WORD` to `-1` when opening the window. <!-- id: 0 -->
- [ ] **Mouse Scrolling**: Update `cmd_dw_scroll` to set `FSM.DW_CURSOR_WORD = -1` whenever the view is scrolled via mouse wheel. <!-- id: 1 -->
- [ ] **Keyboard Seeking**: Update `a`/`d` (and Russian equivalents) bindings in `manage_dw_bindings` to set `FSM.DW_CURSOR_WORD = -1`. <!-- id: 2 -->
- [ ] **Verify Rendering**: Ensure `draw_dw` correctly hides the highlight when `DW_CURSOR_WORD` is `-1`. <!-- id: 3 -->
- [ ] **Verify Copy**: Ensure `cmd_dw_copy` copies the full line when `DW_CURSOR_WORD` is `-1`. <!-- id: 4 -->

## Verification

- [ ] **Manual Test: Initial Open**: Open Drum Window and verify no word is highlighted. <!-- id: 5 -->
- [ ] **Manual Test: Copying**: Press `Ctrl+c` immediately after opening and verify full line is in clipboard. <!-- id: 6 -->
- [ ] **Manual Test: Arrow Activation**: Press `DOWN` and verify first word of next line is highlighted. <!-- id: 7 -->
- [ ] **Manual Test: Scroll Reset**: Highlight a word, scroll with mouse wheel, and verify highlight disappears. <!-- id: 8 -->
- [ ] **Manual Test: Seek Reset**: Highlight a word, press `d`, and verify highlight disappears on the new line. <!-- id: 9 -->
