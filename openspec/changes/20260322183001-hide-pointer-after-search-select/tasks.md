# Tasks: Hide Pointer After Search Selection

## Implementation
- [ ] **Keyboard Selection**: Update `ENTER` binding in `manage_search_bindings` to set `FSM.DW_CURSOR_WORD = -1`. <!-- id: 0 -->
- [ ] **Mouse Selection**: Update `search_mouse_click` logic to set `FSM.DW_CURSOR_WORD = -1`. <!-- id: 1 -->

## Verification
- [ ] **Manual Test: Search Enter**: Open search, select a result with Enter, and verify no word is highlighted in DW. <!-- id: 2 -->
- [ ] **Manual Test: Search Click**: Open search, click a result, and verify no word is highlighted in DW. <!-- id: 3 -->
