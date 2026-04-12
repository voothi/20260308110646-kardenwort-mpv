## 1. Safety & Cleanup
- [x] 1.1 Remove artificial `manage_ui_border_override` global mutations to prevent `osd-border-style` corruption.
- [x] 1.2 Implement `recover_native_osd_style()` on initialization to recover from previously stuck configurations.

## 2. Search UI ASS Isolation
- [x] 2.1 Inject `{\\4a&HFF&}` into the Search UI text blocks in `draw_search_ui`.
- [x] 2.2 Inject `{\\4a&HFF&}` into the Search UI vector polygon backgrounds (`{\p1}m...`) to prevent native boxes from surrounding them.

## 3. Drum Mode Subtitles
- [x] 3.1 Revert brittle `bg_box` manual logic inside `draw_drum`, as removing the global override allows the subtitles to natively recover their background box.

## 4. Verification
- [x] 4.1 Verify that the native subtitle frame is fully visible during search.
- [x] 4.2 Verify that the Search UI cleanly hides the native box without obscuring its own colors.
