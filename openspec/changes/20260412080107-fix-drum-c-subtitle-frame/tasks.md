## 1. Overlay Styling Updates
- [x] 1.1 Inject `{\\4a&HFF&}` into `draw_search_ui` text lines in `scripts/lls_core.lua` to hide background boxes in Search.
- [x] 1.2 Inject `{\\4a&HFF&}` into `draw_dw` (Drum Window) text blocks to ensure no extra boxes appear there.
- [x] 1.3 Ensure `draw_drum` (Drum Mode C) subtitles use `{\\4a&H00&}` or the default alpha to preserve the "dark frame".

## 2. Global Style Cleanup
- [x] 2.1 Modify `manage_ui_border_override` to stop forcing `outline-and-shadow`. Since we now use per-element alpha management, the global override is no longer necessary.

## 3. Verification
- [x] 3.1 Verify Drum Mode C subtitles retain their dark frame while Search is active.
- [x] 3.2 Verify Search UI and Drum Window remain "light" and box-free.


