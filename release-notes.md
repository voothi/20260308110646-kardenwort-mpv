# Release Notes - v1.24.8 (Stability & Search Selection)

**Date**: 2026-03-12
**Version**: v1.24.8
**Request ZID**: 20260312174400
**RFC**: [docs/rfcs/20260312174428-release-v1.24.8.md](docs/rfcs/20260312174428-release-v1.24.8.md)

## Highlights

### 🔍 **"Really" Fuzzy Search**
- **Character-Order Matching**: Upgraded the Search HUD from literal substring matching to a robust fuzzy algorithm. You can now find "hello world" by typing "hlowrd" or "hl wrd". 
- **Select All**: Added `Ctrl + A` (and `Ctrl + Ф`) to the Search HUD. Instantly highlight your entire query for quick replacement or deletion.

### 🥁 **Drum Window (Static Reading Mode) Enhancements**
- **Enter to Seek**: Navigating the track list manually? Press `ENTER` on any line to instantly seek video playback to that timestamp and re-engage "Follow" mode.
- **Advanced Nav Multipliers**: Added `Ctrl + Arrows` and `Shift + Ctrl + Arrows` support. Navigate and select text in larger chunks (5 words/lines) for faster phrasal isolation.
- **Full Layout Parity**: All new keyboard shortcuts fully support both English and Russian layouts.

### 🛡️ **Critical Stability & UI Fixes**
- **Lexical Scope Fix**: Stabilized the script by strictly defining all command functions before usage, resolving the "disappearing window" crash.
- **Subtitle Sync Corrected**: Fixed a regression in `parse_time` that caused centisecond desynchronization in ASS subtitles.
- **UI Layering (Z-Index)**: Explicitly set OSD layers to ensure the Search HUD and Drum Window always appear on top of native subtitles and other overlays.
- **Keybinding Cleanup**: Hardened the cleanup logic to ensure search-specific keys (like Select All and Arrows) are always removed when closing the HUD.

---

# Release Notes - v1.24.0 (Universal Subtitle Search)

**Date**: 2026-03-12
**Version**: v1.24.0
**Request ZID**: 20260312115025
**RFC**: [docs/rfcs/20260312115025-release-v1.24.0.md](docs/rfcs/20260312115025-release-v1.24.0.md)

## Highlights

### 🔍 **Universal Subtitle Search**
- **Standalone Lookup Overlay**: Subtitle search is no longer tied to the Drum Window. Press `Ctrl + F` (or `Ctrl + А`) at any time to summon a transparent search overlay directly over your video.
- **Fuzzy Text Navigation**: Type keywords to immediately filter the entire primary subtitle track. Navigation is synchronized; selecting a result instantly jumps the video and updates the Drum Window's context in the background.
- **Dual Layout First-Class Support**: Full native support for Russian Cyrillic input without keyboard switching.

### 📋 **Advanced Input & Clipboard**
- **Clipboard Paste**: Press `Ctrl + V` (or `Ctrl + М`) within the search bar to paste text from your system clipboard. Line breaks are automatically stripped to ensure query cohesion.
- **UTF-8 Precision**: Enhanced the input buffer to handle multi-byte characters. Deleting Cyrillic letters with Backspace now works with perfect byte-alignment.

### 🖱️ **Interactive Search Results**
- **Mouse Selection**: The search dropdown is now fully interactive. Use your mouse to click directly on any search result to jump to that timestamp instantly.
- **Dynamic Scrolling**: The result list intelligently scrolls and center-aligns as you navigate via keyboard or mouse.

### 🛡️ **Technical Robustness & Sync**
- **Hard-Sync Playback**: Upgraded jumping logic to use `seek absolute+exact`. This eliminates the "desync" bug where secondary subtitles would occasionally fail to load or align after a rapid jump.
- **Visibility Restoration**: Fixed a core engine bug where exiting the Drum Window would force subtitles 'ON' regardless of their previous state. Your manual visibility settings are now rigorously preserved.

---

# Release Notes - v1.2.22 (Track Scrolling Shortcuts)

**Date**: 2026-03-11
**Version**: v1.2.22
**Request ZID**: 20260311101023
**RFC**: [docs/rfcs/20260311101023-release-v1.2.22.md](docs/rfcs/20260311101023-release-v1.2.22.md)

## Highlights

### ⌨️ **Universal Track Scrolling Shortcuts**
- **Symmetrical 2-Second Seeks**: Added `Shift + A` / `A` and `Shift + D` / `D` to precisely mimic the default 2-second forward and backward track scroll natively mapped to `LEFT` and `RIGHT` arrow keys.
- **Mode-Agnostic Access**: In Drum Window `w` (Static Reading Mode), arrow keys are hijacked to handle text viewport scrolling. Because `A`/`D` maps correctly via Shift, you can now freely scrub back and forth through video tracks by 2-second intervals without hiding the window or relying on standard arrow keys.
- **Native Dual Layout Support**: These keys are intrinsically mapped to both English (`A`/`D`) and Russian (`Ф`/`В`) layouts, enabling swift usage without manually toggling language keyboards. 

---

# Release Notes - v1.2.20 (Regression Audit & Documentation)

**Date**: 2026-03-11
**Version**: v1.2.20
**Request ZID**: 20260311044229
**RFC**: [docs/rfcs/20260311044229-release-v1.2.20.md](docs/rfcs/20260311044229-release-v1.2.20.md)

## Highlights

### ✅ **Comprehensive Regression Audit**
- **Hunk-by-Hunk Verification**: Full review of the +398/-46 line diff (10 hunks, 18 commits) between the pre-feature baseline and the final Mouse Selection commit confirmed zero regressions.
- **All Existing Functions Verified Intact**: `cmd_dw_copy`, `cmd_dw_word_move`, `cmd_dw_line_move`, `cmd_dw_scroll`, `cmd_toggle_drum`, `draw_drum`, `tick_dw`, `tick_autopause`, `master_tick`, `cmd_smart_space`, `cmd_toggle_sub_vis`, `cmd_cycle_sec_pos` — all untouched.
- **Selection Logic Preserved**: The `draw_dw` refactoring was verified to maintain functionally identical selection highlighting logic.
- 📋 **Full audit table**: [Hunk-by-Hunk Verdict](docs/rfcs/20260311044229-release-v1.2.20.md#hunk-by-hunk-verdict)

### 📝 **Release Documentation**
- **RFC Packaged**: Full technical write-up of the layout engine, hit-testing math, OS conflict resolution, and hardware-accelerated dragging decisions.
- **README Updated**: Version badge bumped, Static Reading Mode section expanded with Mouse Selection and Double-Click Seek features, keybindings table updated with `LMB` and `Ctrl+Arrows`.

---

# Release Notes - v1.2.18 (Advanced Mouse Selection)

**Date**: 2026-03-11
**Version**: v1.2.18
**Request ZID**: 20260311023622
**RFC**: [docs/rfcs/20260311023622-release-v1.2.18.md](docs/rfcs/20260311023622-release-v1.2.18.md)

## Highlights

### 🖱️ **Advanced Mouse Selection (Drum Window)**
- **Hardware-Accelerated Dragging**: Selecting text now tracks your cursor perfectly at your screen's refresh rate (+60fps) using native `mouse_move` bindings, instead of stuttering on a background timer.
- **Double-Click to Seek**: Double-clicking on any word inside the Drum Window will instantly seek video playback to that exact subtitle line, re-center your viewport, and re-engage "Follow" mode.
- **Point-to-Point Extension**: First click a word to set your anchor, then move your mouse to the end of your desired sentence and `Shift+Click`. The entire block will be cleanly highlighted.

### 🛡️ **UI & Native Conflict Resolution**
- **Window Dragging Fix**: Mpv's native "drag video to move window" functionality previously intercepted selection attempts. The script now temporarily disables OS window dragging while the Drum Window is open, ensuring your first click-and-drag always registers instantly.
- **Subtitle Overlap Shield**: Opening the Drum Window now aggressively snapshots and hides all underlying native subtitle tracks (and Drum Mode overlays), guaranteeing you'll never see garbled overlapping text again. Everything is restored perfectly when the window closes.

### ⌨️ **Synchronized Scrolling**
- **VSCode-Style Edge Snap**: By popular demand, `Ctrl+UP` and `Ctrl+DOWN` now scroll the viewport (just like the mouse wheel). If you scroll the cursor completely off-screen, pressing a standard arrow key will instantly snap the viewport to bring the cursor back onto the edge of your screen.

---

# Release Notes - v1.2.16 (Drum Window Evolution & Static Reading Mode)

**Date**: 2026-03-11
**Version**: v1.2.16
**Request ZIDs**: 20260311014935
**RFC**: [docs/rfcs/20260311014935-release-v1.2.16.md](docs/rfcs/20260311014935-release-v1.2.16.md)

## Highlights

### 🥁 **Drum Window Evolution**
- **Static Reading Mode**: Transformed the Drum Window into a robust "Static Reading Mode". The viewport now freezes when you navigate or scroll, providing a flicker-free environment for intensive reading during immersion.
- **Viewport Decoupling**: Completely decoupled playback tracking from manual navigation. The player's active position continues to be highlighted in Navy, but it won't move the window's view under your cursor.
- **Edge-Aware Scrolling**: Implemented text-editor style viewport control. The window only scrolls when you move the cursor to the top or bottom edges of the visible area.

### 📋 **Advanced Multi-line Selection**
- **Range Selection**: Hold **`Shift`** plus navigation keys to select and highlight text across multiple subtitle rows.
- **Substring Copy**: Refined the `Ctrl+C` behavior to support multi-line and substring extraction. Copying now aggregates all highlighted words into a clean, format-free clipboard export.
- **Word-Level Navigation**: Improved the red word-pointer's precision. It now automatically resets to the first word of the active subtitle line when navigating between lines or opening the window.

### ⌨️ **Enhanced Control Symmetrics**
- **Independent Seek/Highlight**: Seeking (`a`/`d`) now clears selection and re-centers the viewport, ensuring that highlighting and browsing do not interfere with playback navigation.
- **Dual-Layout Selection**: Full hotkey mapping for both English and Russian keyboards (`Shift + Arrows`).
- **Layout Cleanup**: Integrated `\q0` wrapping for long subtitles and tightened line spacing to maximize context without visual overlap.

---

# Release Notes - v1.2.14 (Terminology & Goals Refinement)

**Date**: 2026-03-10
**Version**: v1.2.14
**Request ZID**: 20260310145832
**RFC**: [docs/rfcs/20260310145832-release-v1.2.14.md](docs/rfcs/20260310145832-release-v1.2.14.md)

## Highlights

### 🎯 **Language Acquisition Pivot**
- **Terminology Standardization**: System-wide update to standardize on **"Language Acquisition"** and **"Immersion"** terminologies. This aligns the suite's identity with the philosophy of extensive, high-volume input.
- **Refined Philosophy**: Updated the core mission statement to focus on the **convenient consumption** of Dual-Subtitle (DualSubs) material for learners, emphasizing the use of the player for immersion sessions.

### 🧩 **Extensive Acquisition Goals**
- **Dual-Subtitle Synergy**: Formalized the project's goal of mastering the display of original and translated tracks simultaneously.
- **YouTube Context Protection**: Documented how the suite's unique features protect learners against context loss when consuming YouTube's auto-generated subtitle streams.
- **Local Workflow Authority**: Clarified the suite's role as the final destination for offline immersion following material preparation with companion tools.

---

# Release Notes - v1.2.12 (Dual Subtitle Positional Control)

**Date**: 2026-03-10
**Version**: v1.2.12
**Request ZID**: 20260310141127
**RFC**: [docs/rfcs/20260310141127-release-v1.2.12.md](docs/rfcs/20260310141127-release-v1.2.12.md)

## Highlights

### ↔️ **Dual Subtitle Positional Control**
- **Independent Shifting**: Introduced keybindings to move the secondary subtitle track vertically, independent of the primary track. This is essential for preventing overlaps in multi-line phrasal subtitles.
- **Manual Override**: Users can now tune the exact visual balance between target and translation tracks on-the-fly without editing configuration files.
- **Drum Sync**: Manual positioning persists and synergizes with "Drum Mode," allowing users to set a custom vertical baseline before activating the cascading context view.

### ⌨️ **Layout-Agnostic Positioning**
- **Primary Sub-Pos**: Explicitly mapped `r` / `t` (and Russian `к` / `е`) to ensure subtitle "nudging" works natively in both English and Cyrillic keyboard layouts.
- **Secondary Sub-Pos**: Added `Shift+R` / `Shift+T` (and Russian `К` / `Е`) for secondary track control.

---

# Release Notes - v1.2.10 (Centralized Config & Safety Gap)

**Date**: 2026-03-10
**Version**: v1.2.10
**Request ZID**: 20260310120822
**RFC**: [docs/rfcs/20260310120822-release-v1.2.10.md](docs/rfcs/20260310120822-release-v1.2.10.md)

## Highlights

### ⚙️ **Centralized Script Configuration**
- **External Overrides**: Enabled `script-opts` support in `lls_core.lua`. You can now manage script-specific toggle positions directly from `mpv.conf` without touching Lua files.
- **Dynamic Config Authority**: The script now treats `mpv.conf` as the single source of truth for all operational parameters.

### 🛡️ **Positioning Safety Guards**
- **Overlap Prevention**: Implemented a mandatory 5% "Safety Gap" between primary and secondary subtitles at the bottom of the screen. This resolves the regression where subtitles would "stick together."
- **Threshold-Based Toggling**: Replaced strict coordinate checks with robust threshold logic. The toggle now intelligently adapts to custom positions (e.g., if you set your 'Top' to 15% instead of 10%).

### ⌨️ **System Key Robustness**
- **Dual-Layout Quit**: Key `q` (and `Q` for save-position) now works in both English and Russian (`й`/`Й`) layouts.
- **Essential Controls**: Added native Russian layout mapping for Mute (`ь`), Playback Speed (`х`/`ъ`), and Frame Stepping (`ю`/`б`).

---

# Release Notes - v1.2.9 (Project Analytics & Automation)

**Date**: 2026-03-10
**Version**: v1.2.9
**Request ZID**: 20260310094822
**RFC**: [docs/rfcs/20260310094822-release-v1.2.9.md](docs/rfcs/20260310094822-release-v1.2.9.md)

## Highlights

### 📊 **New Repository Analytics**
- **Lifecycle Tracking**: Formally calculated the total development time (~24 hours intensive) and velocity (~5.6 commits/hour).
- **Inception Timestamp**: March 8, 2026 (11:06 AM).
- **Velocity Insights**: 134 commits to 16 files shows a highly granular, test-driven approach to feature development.

### 🛠️ **Analytics Automation**
- **New Tool**: Added `docs/scripts/analyze_repo.py` to the repository. This script allows for repeatable, session-based analysis of developer effort using clustered git timestamps. 
- **Usage**: Simply pipe `git log` into the script to get an updated view of project growth.

---

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
- Word-by-word pausing now works even if your "acquisition" track is set to the secondary position.
- Refined skip-logic to prevent "double-pausing" between languages.

### 🎨 **Minimalist Styled OSD**
- All status messages (Drum, Autopause, Position, Visibility) now use a unified **Left-Center** style.
- Reduced font size to **20pt** and duration to **500ms** to eliminate immersion distractions.
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
