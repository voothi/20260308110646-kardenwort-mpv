# Release Notes - v1.2.8 (Hotkeys & Documentation)

**Date**: 2026-03-10
**Version**: v1.2.8
**Request ZID**: 20260310025029
**RFC**: [docs/rfcs/20260310025029-release-v1.2.8.md](docs/rfcs/20260310025029-release-v1.2.8.md)

## Highlights

### ⌨️ **Simplified Hotkeys**
- **Modifier Removal**: Context Copy (`x`) and Copy Mode Cycle (`z`) no longer require `Ctrl`. Single-key triggers significantly speed up the immersion workflow.
- **Layout Robustness**: Hotkeys are now case-insensitive and fully mapped for both **English** and **Russian** layouts.

### 📖 **Comprehensive Documentation**
- **Inline Manual**: `input.conf` has been fully reorganized and commented. Every shortcut now includes an explanation of its purpose, helping users master the "Smart Spacebar," "Drum Mode," and "Autopause" features.
- **Grouped Structure**: Keys are now logically categorized into Navigation, Language-Specific, and Feature Toggle sections.

---

# Release Notes - v1.2.6 (Keybinding Source of Truth)

**Date**: 2026-03-10
**Version**: v1.2.6
**Request ZID**: 20260310024112
**RFC**: [docs/rfcs/20260310024112-release-v1.2.6.md](docs/rfcs/20260310024112-release-v1.2.6.md)

## Highlights

### 📋 **Single Source of Truth for Keybindings**
- **Consolidated Authority**: Removed the last hardcoded key (`"c"` for Drum Mode) from `lls_core.lua`. All 11 script bindings now use `nil` defaults, making `input.conf` the exclusive keybinding authority.
- **Zero Script Keys**: To change any hotkey, edit only `input.conf`. No script files need modification.

### 🧹 **Repository & Cache Cleanup**
- **Git Cache Optimization**: Removed `scripts/old_copy_sub.lua` from git tracking to prevent confusion with the new unified FSM core.
- **Ignore Patterns**: Added `__pycache__/` to `.gitignore` to maintain a clean workspace across Python-based developer tools.

---

# Release Notes - v1.2.4 (Drum Sync & Compatibility Guards)

**Date**: 2026-03-10
**Version**: v1.2.4
**Request ZID**: 20260310020401
**RFC**: [docs/rfcs/20260310020401-release-v1.2.4.md](docs/rfcs/20260310020401-release-v1.2.4.md)

## Highlights

### 🥁 **Synchronized Drum Keybindings**
- **FSM-State Prioritization**: Fixed a critical race condition where `master_tick` loop (50ms) was overwriting manual `y` (Secondary Position) toggles. Commands now write to FSM state first.
- **Stale Array Flushing**: Resolved "ghost" subtitles in Drum Mode. Cycling `j` (Secondary SID) to OFF now immediately flushes internal memory arrays upon detecting path changes.
- **Symmetrical Position Restore**: Secondary position is now perfectly restored from FSM memory when Drum Mode is turned OFF or the player shuts down.

### 🛡️ **Smart Feature Compatibility Guards**
- **Positional Integrity**: `y` (Secondary Position) now auto-blocks if the track is `.ass` or if no secondary sub is loaded, preventing layout collisions.
- **Context-Aware Copying**: `Ctrl+Z` (Copy Mode) and `Ctrl+X` (Context Copy) now detect if they are musically/mathematically supported before activating, with clear OSD feedback for SINGLE_SRT or internal-only tracks.

---

# Release Notes - v1.2.2 (Ass Context Copy Fix)

**Date**: 2026-03-10
**Version**: v1.2.2
**Request ZID**: 20260310014540
**RFC**: [docs/rfcs/20260310014540-release-v1.2.2.md](docs/rfcs/20260310014540-release-v1.2.2.md)

## Highlights

### 📋 **Intelligent ASS Context Copy Precision**
- **Symmetrical Dynamic Traversal**: Re-implemented the dynamic leaping extraction loop to completely bypass interleaved foreign-language blocks, fulfilling identical pure-English chronology sentences.
- **Center-Index Snapping**: Fixed a mathematical anomaly where randomly targeting a dual-track Russian baseline as the index center effectively skipped the exact middle string, turning 5-sentence extractions into 4-sentence extractions.
- **Clipboard Output Optimization**: Restored the `is_context` substring compilation shortcut from commit `45e8ae320` to reduce processor parsing overhead when explicitly loading filtered Context chunks.

---

# Release Notes - v1.2.0 (FSM Architecture Overhaul)

**Date**: 2026-03-10
**Version**: v1.2.0
**Request ZID**: 20260310002147
**RFC**: [docs/rfcs/20260310002147-release-v1.2.0.md](docs/rfcs/20260310002147-release-v1.2.0.md)

## Highlights

### ⚙️ **Unified State Machine Architecture**
- **Harmonized Operating Modes**: Replaced the ad-hoc, boolean-driven script collection (`autopause.lua`, `sub_context.lua`, `copy_sub.lua`) with a single, highly-performant Finite State Machine (`scripts/lls_core.lua`).
- **Context Awareness**: Features like Drum Mode and Context Copy are now natively aware of the exact loaded subtitle configuration (SRT vs ASS, Single vs Dual). This guarantees features activate only when mathematically supported.
- **Optimized Performance**: Consolidated all internal script timers into a single master tick loop, completely removing race conditions and lowering overall CPU overhead.

---

# Release Notes - v1.1.0 (ASS Context Copy Enhancements)

**Date**: 2026-03-09
**Version**: v1.1.0
**Request ZID**: 20260310000706
**RFC**: [docs/rfcs/20260310000706-release-v1.1.0.md](docs/rfcs/20260310000706-release-v1.1.0.md)

## Highlights

### 📋 **Intelligent ASS Context Copy**
- **Dual-Track Stability**: Context Copy (`Ctrl X`) robustly bridges interleaved language tracks (e.g., Russian translation chunks mixed between English subtitle lines) to fetch unified dialogue.
- **Karaoke Sentence Reconstruction**: Fragments of word-by-word karaoke highlights are now intelligently rebuilt into complete, coherent chronological sentences for clipboard exportation.
- **Targeted Context Range**: Requesting previous and next lines now specifically respects target language (filtering out translation noise) to provide pure context chunks.

---

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
2.  Delete obsolete standalone scripts (`autopause.lua`, `copy_sub.lua`, `sub_context.lua`) from your `scripts/` folder.
3.  Place the new unified `lls_core.lua` inside your `scripts/` folder.
4.  Refresh your `mpv.conf` to include the standard subtitle position defaults (10/90).
