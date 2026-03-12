# Release Notes - v1.24.7 (Stability & Search Selection)

**Date**: 2026-03-12
**Version**: v1.24.7
**Request ZID**: 20260312173500

## Highlights

### 🔍 **"Really" Fuzzy Search**
- **Character-Order Matching**: Upgraded the Search HUD from literal substring matching to a robust fuzzy algorithm. You can now find "hello world" by typing "hlowrd" or "hl wrd". 
- **Select All**: Added `Ctrl + A` (and `Ctrl + Ф`) to the Search HUD. Instantly highlight your entire query for quick replacement or deletion.

### 🥁 **Drum Window (Static Reading Mode) Enhancements**
- **Enter to Seek**: Navigating the track list manually? Press `ENTER` on any line to instantly seek video playback to that timestamp and re-engage "Follow" mode.
- **Advanced Nav Multipliers**: Added `Ctrl + Arrows` and `Shift + Ctrl + Arrows` support. Navigate and select text in larger chunks (5 words/lines) for faster phrasal isolation.
- **Full Layout Parity**: All new keyboard shortcuts fully support both English and Russian layouts.

### 🛡️ **Critical Stability & UI Fixes**
- **Subtitle Sync Corrected**: Fixed a regression in `parse_time` that caused centisecond desynchronization in ASS subtitles.
- **UI Layering (Z-Index)**: Explicitly set OSD layers to ensure the Search HUD and Drum Window always appear on top of native subtitles and other overlays.
- **Lexical Scope Fix**: Stabilized the script by ensuring all Drum Window commands are defined before use, preventing the "disappearing window" crash.
- **Keybinding Cleanup**: Hardened the cleanup logic to ensure search-specific keys (like Select All and Arrows) are always removed when closing the HUD.
