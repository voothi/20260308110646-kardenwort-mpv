# Tasks: Drum Mode Rendering and OSD Refinement

## 1. Drum Mode Rendering
- [x] Implement unified ASS tagging for grouped contexts
- [x] Fix newline concatenation logic (`\N` instead of `\N\N`)
- [x] Standardize on `\an8` and `\an2` anchors to remove vertical gaps

## 2. Property Integration
- [x] Synchronize `tick_drum` visual coordinates with `secondary-sub-pos`
- [x] Ensure manual position adjustments update live properties

## 3. UI Configuration
- [x] Disable `osd-bar` in `mpv.conf`
- [x] Force `outline-and-shadow` border style for Drum Mode
- [x] Verify OSD clarity and lack of clutter during navigation
