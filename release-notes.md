# Release Notes - v1.0.0 (Subtitle Context & Autopause Suite)

**Date**: 2026-03-09
**Version**: v1.0.0
**Request ZID**: 20260308233056
**RFC**: [docs/rfcs/20260309002123-release-v1.0.0.md](docs/rfcs/20260309002123-release-v1.0.0.md)

## Highlights

### 🚀 **Smart Spacebar (Hold-to-Play)**
- **NEW**: Press and **HOLD** down the spacebar to temporarily unpause and smoothly bypass all word-by-word or end-of-phrase pause points.
- **TAPPING** the spacebar (< 200ms) functions as a standard Play/Pause toggle. 
- Integrated directly into `input.conf` for a seamless player experience.

### 🥁 **Drum Context Mode ('c')**
- Added a rolling context engine that displays previous and future subtitles around the active line.
- Smart "Stacking" logic ensures primary and secondary context drums never overlap when both are at the bottom of the screen.
- **Safety Check**: Automatically disables on `.ass` files to protect complex karaoke formatting.

### ⏸️ **Dual-Track Aware Autopause ('P' / 'K')**
- Redesigned `autopause.lua` to intelligently scan both primary and secondary tracks.
- Word-by-word pausing now works even if your "learning" track is set to the secondary position.
- Refined skip-logic to prevent "double-pausing" between languages.

### 🎨 **Minimalist Styled OSD**
- All status messages (Drum, Autopause, Position, Visibility) now use a unified **Left-Center** style.
- Reduced font size to **20pt** and duration to **500ms** to eliminate study distractions.
- Added custom OSD for **OSC Visibility (TAB)** and **Subtitle Positions (y)**.

## Key Fixes & Improvements
- **Dual-Layout Support**: Fully mapped English (EN) and Russian (RU) hotkeys in `input.conf` for all features.
- **Scaling Fixes**: `fixed_font.lua` now protects `.ass` files while maintaining readability for `.srt`.
- **Logic Sync**: `s` and `j` keys are now fully synchronized with Drum Mode and OSD status.
- **Configurable Timeout**: Added `osd_msg_duration` to all script settings for uniform adjustment.

## How to Update
1.  Overwrite your `input.conf` with the latest version.
2.  Replace the `scripts/` folder with the updated `sub_context.lua` and `autopause.lua`.
3.  Refresh your `mpv.conf` to include the standard subtitle position defaults (10/90).
