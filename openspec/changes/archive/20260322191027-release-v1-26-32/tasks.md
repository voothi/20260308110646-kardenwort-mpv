# Tasks: Improved Drum Window Navigation & Pointer Logic

## 1. Pointer Refinement
- [x] Initialize `DW_CURSOR_WORD` to `-1` on window open
- [x] Integrate pointer reset into `cmd_dw_scroll`
- [x] Integrate pointer reset into search result jump logic
- [x] Update arrow key handlers to activate pointer from `-1` state

## 2. Navigation Reliability
- [x] Implement `cmd_dw_seek_delta` using internal subtitle tables
- [x] Bind `a`/`d` to `cmd_dw_seek_delta` while Drum Window is active
- [x] Verify "one-tap" jump reliability after autopauses

## 3. Validation
- [x] Verify full-line copying works immediately after opening window
- [x] Confirm no visual artifacts when pointer is inactive
- [x] Verify correct word highlighting when arrows are pressed
