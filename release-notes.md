# Release Notes - v1.34.2 (Keyboard Tooltips & Selection Persistence)

**Date**: 2026-04-16
**Version**: v1.34.2
**Implementation ZIDs**: 20260416103557, 20260416151047

## Highlights

### ⌨️ **Keyboard-Driven Tooltip Logic**
- **Unified Toggle Shortcut**: Introduced **`e`** (Russian **`у`**) to toggle translation tooltips in the Drum Window. This enhances keyboard-driven study sessions by eliminating the need for mouse interaction to peek at hints.
- **Dynamic Scroll Tracking**: Tooltips now intelligently follow their parent subtitle line during scrolling and navigation. The hint remains vertically anchored to the text rather than "float" at a static screen position.
- **Contextual Priority Targeting**: 
  - **Playback Mode**: While the video is running, the keyboard tooltip automatically follows the currently active subtitle (White).
  - **Study Mode**: When paused, the toggle prioritizes the user's manual selection/cursor (Yellow) for precise, word-by-word analysis.
- **RMB Interaction Hardening**: Restored and refined the Right-MouseButton (RMB) hold behavior. Tooltips now reliably appear during hold and correctly dismiss when focus is lost in non-hover modes.

### 🛡️ **Selection Persistence & Focus Stability**
- **Non-Destructive Navigation**: Manual seeking via **`a`** and **`d`** now preserves the active yellow selection in the Drum Window. This allows learners to jump back and forth between lines to check context without losing their current highlighted phrase.
- **Intelligent Autopause Focus**: Implemented a priority logic that keeps tooltips centered on the active playback line after an autopause trigger, preventing the UI from "snapping" back to a distant manual cursor unless explicit interaction occurs.

---

# Release Notes - v1.32.2 (TSV Recovery & Visual Depth)

**Date**: 2026-04-14
**Version**: v1.32.2
**Implementation ZIDs**: 20260414091237, 20260414100928, 20260414123431, 20260414150031

## Highlights

### 🎨 **Advanced Highlight Intersections & Nesting**
- **Paired Word Nesting (Purple Gradient)**: Non-contiguous/split highlights (Purple) now feature full nesting awareness. Overlapping split-word terms now exhibit a three-tier depth gradient (`anki_split_depth_1/2/3`), harmonizing their visual style with existing contiguous highlights.
- **Mixed Intersection Blending**: Introduced a sophisticated "Mixed" highlight state. When a word belongs to both a contiguous (Orange) and non-contiguous (Purple) saved term, the system now renders a distinct blended color (`anki_mix_depth_1/2/3`) to visualize the intersection accurately.
- **Decoupled Depth Tracking**: Refactored the internal stack-calculation engine to independently track `orange_stack` and `purple_stack`, enabling more precise multi-layer rendering and developer debugging.

### 🛡️ **TSV State Recovery & Initialization Hardening**
- **Auto-Creation Healing**: The Drum Window now automatically detects missing `.tsv` record files and creates a fresh template on startup. This ensures immediate UI recovery if the file is cleared or deleted mid-session.
- **Dynamic Header Skipping**: Upgraded the TSV parser to dynamically detect and ignore the header row, regardless of the custom term field configured in `anki_mapping.ini`.
- **Fail-Safe Observer Loop**: Wrapped all core mpv property observers in protected `pcall` execution. This prevents rogue subtitle errors from fatally crashing the player's internal state tracking.
- **Terminal Diagnostics**: Critical subsystem errors now bypass mpv's internal logging filter and print directly to the terminal for visibility.

---

# Release Notes - v1.32.0 (Multi-Word Ctrl-Selection & Dynamic Anki Mappings)

**Date**: 2026-04-14
**Version**: v1.32.0
**Implementation ZIDs**: 20260413133147, 20260413144355, 20260413163703, 20260413173817, 20260413213102, 20260413224742, 20260413234639, 20260414004717, 20260414015131, 20260414023304, 20260414033418

## Highlights

### 🖱️ **Multi-Word & Non-Contiguous Selection (Ctrl-Selection)**
- **Ctrl-Multiselect Gesture**: Introduced a sophisticated new workflow for marking non-contiguous constructs (e.g., German separable-prefix verbs or English phrasal verbs).
  - `Ctrl + LMB`: Click individual words to accumulate them into a yellow pending selection.
  - `Ctrl + MMB`: Commit the accumulated set as a persistent highlight and Anki export.
- **Split-Word Highlighting (Purple)**: Non-contiguous saved terms now feature a distinct **Purple** highlight to clearly distinguish them from contiguous selections.
- **Robust Highlighting Matcher**: Refactored the internal matching algorithm to reliably detect and style both contiguous (Orange) and split (Purple) multi-word terms, even when overlapping within the same subtitle block.
- **Center-Proximity Context Search**: Implemented a proximity-based search fallback for non-contiguous selections. This ensures that even when words are scattered across multiple sentences, the exported Anki context correctly captures the full logical span.

### 📋 **Dynamic Anki Mappings & Smart Export**
- **External Mapping Engine**: Migrated Anki field definitions to a dedicated `anki_mapping.ini` file. Users can now define an unlimited number of fields, use blank "holes" for alignment, and configure static text literals.
- **Automated TSV Headers**: The export engine now automatically generates Anki-compatible headers (e.g., `#deck column:N`) and field names at the top of every record file for zero-touch imports.
- **Track-Aware Metadata**: Enhanced the data pipeline to automatically extract deck names from filenames and generate language-specific TTS flags (`tts_source_[lang]`) based on active subtitle tracks.
- **Forward-Search Context Preservation**: Refined the context extraction logic to search for sentence boundaries starting from the *end* of a selection. This prevents premature truncation in multi-sentence selections.
- **Metadata & Punctuation Sanitization**: 
  - **Tag Stripping**: Automatic removal of bracketed metadata like `[musik]` or `[Lachen]` from exported cards.
  - **Period Restoration**: Naturally restores a terminal period to capitalized sentence exports that lost their original punctuation during the cleaning phase.

### 📚 **"Book Mode" & UI Stability**
- **Stationary Viewport Navigation**: Toggle **Book Mode** with **`b`** (Russian **`и`**) to lock the Drum Window UI. This freezes the viewport center while navigating (`a`/`d`) or selecting vocabulary, providing a flicker-free, book-like reading experience.
- **Synchronized Scroll Stability**: Resolved the "scroll-drift" bug. Viewport scrolling (`MouseWheel`) now perfectly preserves active selections and prevents the highlight pointer from "snapping" to the mouse during motion.
- **Hardened Subtitle Suppression**: Centralized the multi-track suppression logic in `master_tick`. Native subtitles are now rigorously hidden across all script modes, including during rapid track cycling.

### 🛠️ **Workflow Optimizations**
- **Instant Record Access**: Added the **`o`** (Russian **`щ`**) shortcut within the Drum Window to instantly open the currently active TSV record file in your system's default editor (e.g., VSCode).

---

# Release Notes - v1.28.16 (Unified Styling & FSM Hardening)


**Date**: 2026-04-13
**Version**: v1.28.16
**Implementation ZIDs**: 20260413121002, 20260413124623

## Highlights

### 🎨 **Unified Styling Architecture**
- **Mode-Specific Fonts**: Introduced the ability to specify independent `font_name`, `font_bold`, and `font_size` for all four rendering modes: Regular SRT, Drum Mode (`c`), Drum Window (`w`), and Tooltips.
- **Enhanced Legibility**: Updated default styling to **Consolas** across the suite for superior monospace alignment and professional aesthetic.
- **Monospace Calibration**: Finely tuned hit-testing and word-wrapping logic for Consolas, ensuring pixel-perfect mouse selection and pointer alignment.

### 🛡️ **FSM Architecture & Visibility Hardening**
- **Continuous Background Suppression**: The `master_tick` loop now rigorously monitors both `sub-visibility` and `secondary-sub-visibility` properties to prevent duplicate native overlays, especially when cycling tracks with `j`.
- **Visibility Conflict Resolution**: Resolved "flickering" issues by centralizing all property mutations into a single-source-of-truth logic engine.
- **Mode Mutex**: Implemented strict mutual exclusion between Drum Mode, Drum Window, and Regular OSD-SRT rendering to prevent frame buffer collisions.

### 🖼️ **Refactored Text Framing & Dark Theme**
- **Dynamic Background Boxes**: Refactored the internal text frame renderer to use hardware-weighted ASS alpha calculations. Background transparency is now perfectly balanced across all UI elements.
- **Premium Dark Aesthetics**: Implemented a "Dark Theme" baseline for the Drum Window, using consistent semi-transparent backgrounds that preserve cinematic immersion while providing high-contrast reading surfaces.

### 🛠️ **Anki Highlight Restoration**
- **Selection Fidelity**: Restored the `anki_highlight_bold` functionality within the Drum Window. Saved words and phrases now correctly display bold/color emphasis without desynchronizing from the viewport tracking.

---

# Release Notes - v1.28.12 (MMB Drag-Export & Occurrence Persistence)

**Date**: 2026-04-13
**Version**: v1.28.12
**Request ZID**: 20260413013335 (Archived: 20260413004525)

## Highlights

### 🖱️ **MMB Drag-to-Export**
- **Unified Selection Logic**: The Middle Mouse Button (MMB) now supports high-performance drag selection, identical to the Left Mouse Button.
- **Instant Commitment**: Releasing MMB now automatically triggers the Anki export process. Draw a phrase and release to instantly save it with full context and timing.
- **SCM Compatibility**: Middle-clicking an existing red selection range still commits and exports it, preserving the "Second Click Mode" workflow.

### 🎨 **Multi-Occurrence Persistence**
- **Non-Destructive Bookmarking**: Resolved the issue where saving a word in a new location would "un-highlight" previous occurrences. The engine now supports multiple time-anchors per word.
- **Global Context Fidelity**: All bookmarked instances of a word or phrase remain visible across the entire timeline, regardless of which specific instance was saved last.

### ⚖️ **Overlap-Only Intensity**
- **Intelligent Stacking**: Color intensity (highlight depth) now strictly reflects textual overlap between *different* saved items (e.g., a single word vs. a phrase).
- **Redundancy Guard**: Duplicate bookmarks of the exact same term across different locations no longer artificially darken the highlight, maintaining a clean and professional visual style.

---

# Release Notes - v1.28.10 (Sanitized Anki Export)

**Date**: 2026-04-13
**Version**: v1.28.10
**Request ZID**: 20260413004318

## Highlights

### 📋 **Universal Sanitized Capture**
- **Hardened Export Engine**: The Middle-Click (`MBTN_MID`) Anki export engine has been unified with the surgical stripping logic.
- **Boundary Sanitization**: Exporting words like `Umbruch.` or `ehrlich,` now automatically strips trailing punctuation before saving to the TSV. This ensures your Anki database remains pristine and optimized for dictionary matching.
- **Phrasal Integrity**: Internal punctuation within multi-word selections (e.g., `im Umbruch. Während`) is accurately preserved to maintain grammatical context.

### 🎨 **Bitwise-OR Highlight Aggregation**
- **Overlapping Match Fidelity**: Resolved a visual bug where commas would lose their color if a word was covered by both a single-word card and a phrase.
- **Logical Priority**: The engine now aggregates all active matches for a word. If **any** of the overlapping highlights is a multi-word phrase, the system prioritized **Continuity Mode**, ensuring commas and periods stay green for a perfect visual flow.

---

# Release Notes - v1.28.8 (High-Recall & Adaptive Highlighting)

## Highlights

### 🎨 **Adaptive Punctuation & Visual Continuity**
- **Logical Flow Balancing**: Highlights now intelligently distinguish between single vocabulary words and long-form phrases. 
  - **Single Words**: Word boundaries remain "surgical" (colored word body, white periods/commas) for a professional dictionary look.
  - **Phrases & Paragraphs**: Internal punctuation marks are now fully highlighted green to maintain visual flow and prevent "white holes" in long subtitle blocks.
- **Priority Logic**: When a single-word card overlaps with a larger phrase match, the system automatically prioritizes **Continuity Mode** to ensure a seamless visual experience.

### 📋 **Clean Capture Pipeline**
- **Boundary Sanitization**: All exported clips (clipboard copy) now automatically strip leading and trailing punctuation/whitespace. This ensures your Anki database remains clean and cards are optimized for perfect dictionary matching.
- **Internal Preservation**: Commas and periods inside a captured phrase are accurately preserved to maintain grammatical integrity.

### 🛡️ **Hardened High-Recall Engine**
- **Deep-Peek Verification**: The engine now recursively traverses up to 5 adjacent subtitle segments to verify phrase integrity, even if the text is heavily fragmented across single-word subtitles.
- **Adaptive Temporal Windows**: Introduced a dynamic fuzzy window that scales by **+0.5s per word** for long paragraphs. This prevents massive news report highlights from expiring prematurely as you read.
- **Inter-Segment Bridging**: Refined the 1.5s temporal threshold to bridge natural speaker pauses while preventing unrelated subtitle clusters from bleeding together.

### ⚡ **Performance & Data Integrity**
- **Lazy-Caching Logic**: Implemented high-performance caching for highlight terms. Word lists, cleaned keys, and context lookups are now pre-processed on first access.
- **Result**: Zero UI latency or mouse "sticking" even when hundreds of paragraph-long terms are active simultaneously.

---

# Release Notes - v1.28.6 (ReadEra Vocabulary Highlighting)

## Highlights

### 🎨 **ReadEra-Style Premium Highlighting**
- **Absolute Coordinate Rendering**: Vocabulary highlights now use a high-performance rendering engine that anchors to the physical top-left of the screen (`\an7\pos(0,0)`). This ensures every highlight box and word is placed with sub-pixel precision, eliminating visual desync.
- **Translucent Background Boxes**: Replaced invasive text-color gradients with semi-transparent rectangular "marker" underlays. This preserves the original subtitle colors while providing clear, stackable visual depth.
- **Amber/Gold Palette**: Implemented a sophisticated, depth-aware palette using correct ASS `BBGGRR` byte ordering. Highlights now shift from Light Amber (Depth 1) to Deep Rust (Depth 3) as multiple terms overlap.
- **Human-Centric Padding**: Every highlight box features soft horizontal padding (+4px) and vertical alignment offsets to mimic the look of a professional e-reader selection.

### 📋 **Intelligent Anki Mining Workflow**
- **Sentence-Aware Context**: The mining engine now prioritizes capturing grammatically complete sentences. It scans for `.`, `!`, and `?` boundaries within your context window before applying word-count truncation.
- **Automated TSV Synchronization**: Highlights are now managed via a localized `.tsv` database. The script reloads this file automatically every 30 seconds (or on demand), allowing for external cards to be edited without restarting the player.
- **Atomic Database Handling**: Uses protected `pcall` logic and atomic memory swaps during syncs to ensure the UI remains responsive and the database stays protected against corruption.

### 🛡️ **Hardened Matching & Stability**
- **Strict Whole-Word Filtering**: The highlight engine now uses tokenized word matching. Highlighting "auf" will no longer accidentally trigger on substrings like "Aufgaben," ensuring your vocabulary focus stays accurate.
- **Temporal Fuzzy Windowing**: Introduced a 10s "Fuzzy Window" that allows highlights to correctly stack and track even when a phrase spans across multiple subtitle file boundaries.
- **Particle Pollution Guard**: Implemented a 3-character minimum filter for automatic highlights, preventing common particles (like "de", "il") from cluttering your reading view while preserving high-value vocabulary.

---

# Release Notes - v1.28.4 (Selection-Aware Tooltip Suppression)

**Date**: 2026-04-12
**Version**: v1.28.4
**Request ZID**: 20260412162936

## Highlights

### 🛡️ **Analytical Immersion: Selection-Aware Suppression**
- **Symmetrical Action Suppression**: Tooltips now intelligently hide whenever you click or drag the mouse. This suppression is "sticky," remaining active on the exact line where you released the mouse until you move the focus to a different subtitle.
- **Persistent Selection Guard**: Any line within an active red-selection range is now automatically shielded from auto-hover tooltips. These lines enter a "Manual Only" mode to prevent visual clutter while reading, ensuring clues only appear when you explicitly Right-Click (RMB).
- **Manual Hint Priority**: Explicitly pressing **MBTN_RIGHT** (RMB) now resets all suppression locks for that line, allowing you to instantly peek at a hint even if the area was previously suppressed or part of a selection.

### ⚙️ **Refined Interaction Logic**
- **LMB & MMB Hold Suppression**: Tooltips now remain suppressed as long as the **Left** or **Middle (Wheel)** Mouse Button is held down. This allows you to "sweep" across lines while selecting or analyzing without any auto-hover popups interfering with your focus.
- **Improved Focus Stability**: Manual tooltip pins can be instantly dismissed with a standard click (LMB/MMB). The system is fully aware of multi-line selection drags, ensuring the UI remains professionally clean throughout complex study operations.

### 🧹 **Architectural Cleanup**
- **Functional Naming**: Internal mouse handles have been refactored (e.g., `cmd_dw_mouse_select`) to more accurately reflect their role in the selection and suppression lifecycle, ensuring the codebase remains maintainable as new interactions are added.

---

# Release Notes - v1.28.3 (Startup Fix)

**Date**: 2026-04-12
**Version**: v1.28.3
**Request ZID**: 20260412135354

## Bug Fixes

### 🛠️ **Resolved Startup Navigation Latency**
- **Eager Memory Loading**: Fixed an issue where navigation keys (`a`/`d`) were unresponsive immediately after starting a video. The script now eagerly loads subtitle data into memory as soon as a track is detected, regardless of whether a specialized mode (Drum/Window) is active.
- **Improved Initializer**: Consolidated all track-loading logic into the core media state handler, ensuring consistent behavior from the very first frame of playback.

---

# Release Notes - v1.28.2 (Unified Smooth Navigation Repeat)

**Date**: 2026-04-12
**Version**: v1.28.2
**Request ZID**: 20260412131945

## Highlights

### 🚄 **Unified Smooth Navigation Repeat**
- **Hold-to-Scroll Engine**: Replaced native OS key-repeat with a custom, high-precision script-controlled engine for subtitle seeking (`a`/`d`).
- **Universal Parity**: Navigation now behaves identically with smooth auto-scrolling in **Normal Mode**, **Drum Mode (`c`)**, and **Drum Window Mode (`w`)**.
- **Configurable Dynamics**: Introduced `seek_hold_delay` (default: 500ms) and `seek_hold_rate` (default: 10/sec) options. Fine-tune your scrolling experience via `mpv.conf`.
- **Zero-Stick Precision**: Leverages complex key bindings to ensure auto-scrolling stops instantly upon key release, eliminating "sticky" jumps during rapid navigation.

---

# Release Notes - v1.28.0 (Contextual Translation Tooltips)

**Date**: 2026-04-12
**Version**: v1.28.0
**Request ZID**: 20260412105348

## Highlights

### 🔦 **Contextual Translation Tooltips**
- **On-Demand Peeking**: Press **MBTN_RIGHT** (Right Click) in the Drum Window (`w`) to instantly see a secondary subtitle translation in a translucent balloon. 
- **Hold to Peek (Scanned Hover)**: Innovative interaction—hold the Right Mouse button and move across subtitles to "scan" translations fluently. Releasing the button preserves the pin on your last focus.
- **Dedicated Hover Mode**: Toggle permanent hover-based translations using **`n`** (or Russian **`т`**) for hands-free reading.

### 🎨 **Visual Unity & Customization**
- **Style Synchronization**: Tooltips are visually unified with the Drum Mode (Reel C) aesthetic, featuring matched font sizes (32) and translucent background boxes.
- **Independent Alpha Control**: Introduced separate controls for text and background opacity (`dw_tooltip_text_opacity` vs `dw_tooltip_bg_opacity`), allowing for perfectly balanced legibility.
- **Native OSD Framing**: Leverages mpv's native Style 3 background boxes for a premium, integrated look that respects global player themes.

### ⚙️ **Architectural Shortcut Management**
- **Temporary Key Overlays**: Implemented a "Hijack & Release" system where tooltip keys (RMB, `n`, etc.) are only active while the Drum Window is open, preventing global shortcut pollution.
- **Script-Opt Exposure**: Every aspect of the tooltip—shortcuts, colors, fonts, and behavior—is now fully configurable via `mpv.conf` without editing script files.
- **Enhanced Discoverability**: Integrated internal shortcut documentation directly into `input.conf` for a single, comprehensive reference hub.

---

# Release Notes - v1.26.36 (Visual Style Persistence)

**Date**: 2026-04-12
**Version**: v1.26.36
**Request ZID**: 20260412080107

## Highlights

### 🛡️ **Visual Style Persistence & Isolation**
- **Drum Mode C Fix**: Resolved a visual bug where the "Black Frame" (background box) around subtitles would disappear whenever the Search UI was active.
- **Granular Styling**: Switched from global property mutations to per-element ASS styling using the `{\\4a&HFF&}` (shadow alpha) tag. This allows the Search UI and Drum Window to stay "light" and clean without polluting the native styling of the actual reading track.
- **Safety Net Recovery**: Added an automatic recovery routine (`recover_native_osd_style`) that detects and reverts any "stuck" OSD properties left over from previous script crashes, ensuring your preferred visual theme is always respected.
- **Enhanced Context**: Refined default Drum Mode behavior with support for increased context lines (3) for better phrasal awareness during immersion.

---

# Release Notes - v1.26.34 (Universal Navigation Reliability)

**Date**: 2026-03-22
**Version**: v1.26.34
**Request ZID**: 20260322202226
**RFC**: [docs/rfcs/20260322202226-v1.26.34.md](docs/rfcs/20260322202226-v1.26.34.md)

## Highlights

### 🚄 **Universal Navigation Reliability**
- **Seamless Logic**: Exported the reliable, table-based seeking engine as global script-bindings (`lls-seek_prev` and `lls-seek_next`).
- **Global Smoothness**: Subtitle navigation (`a`/`d`) now behaves with identical high-precision reliability whether the Drum Window is open or closed. No more "double-tapping" after an autopause in any mode.

---

# Release Notes - v1.26.32 (Navigation & Pointer Fixes)

**Date**: 2026-03-22
**Version**: v1.26.32
**Request ZID**: 20260322191027
**RFC**: [docs/rfcs/20260322191027-release-v1.26.32.md](docs/rfcs/20260322191027-release-v1.26.32.md)

## Highlights

### 🚄 **Immediate Navigation Response**
- **Double-Tap Fix**: Resolved a persistent issue where jumping to the next subtitle (`d`) required two presses when the video was paused after an autopause.
- **Custom Seeking Logic**: Replaced the native `sub-seek` command with robust internal logic that calculates the exact subtitle start time from the loaded track, ensuring snappier and more reliable navigation in the Drum Window.

### 🥁 **Predictable Pointer Behavior**
- **Smart Deactivation**: The Drum Window now consistently opens with the word pointer deactivated (`-1`). This also applies after selecting search results or scrolling, preventing visual clutter and accidental word copying.
- **Focused Interaction**: Red Highlights now only appear when you explicitly engage with them via the arrow keys or mouse selection.

---

# Release Notes - v1.26.30 (Search Selection Fix)

**Date**: 2026-03-22
**Version**: v1.26.30
**Request ZID**: 20260322171238
**RFC**: [docs/rfcs/20260322171238-release-v1.26.30.md](docs/rfcs/20260322171238-release-v1.26.30.md)

## Highlights

### 🛡️ **Critical Search Selection Fix**
- **Scoping Resolution**: Fixed a Lua execution error where the script would crash when performing word-based selection in the Search HUD (`Ctrl+Shift+Arrows`). 
- **Definition Reordering**: Corrected the internal variable scope by reordering utility functions, ensuring all components are properly initialized before usage.
- **Enhanced Reliability**: The Search HUD and Drum Window are now more robust against rapid navigation and selection actions, preventing session-ending script failures.

### 🥁 **Selection State Consistency**
- **State Logic Refinement**: Fixed a naming discrepancy in the Drum Window's selection memory, ensuring that shift-selection highlights track correctly across multi-word ranges.

---

# Release Notes - v1.26.28 (Search Box Visibility Fix)

## Highlights

### 🔦 **Search HUD & Drum Window Visibility Fix**
- **Clean Interface**: Fixed a severe visual bug where enabling the "Black Frame" aesthetic (`osd-border-style=background-box`) rendered the Search and Drum Window UI unreadable.
- **Intelligent Style Override**: The script now dynamically detects when these custom UI panels are active and temporarily forces the OSD to a clean `outline-and-shadow` style. This prevents overlapping black boxes from obscuring your search results and reading context.
- **Preserved Aesthetics**: Your global `mpv` styling preferences are automatically restored the moment you close the Search or Drum Window, ensuring your immersive experience remains exactly how you like it.

---

# Release Notes - v1.26.26 (Cross-Platform Clipboard Support)

**Date**: 2026-03-22
**Version**: v1.26.26
**Request ZID**: 20260322161222
**RFC**: [docs/rfcs/20260322161222-release-v1.26.26.md](docs/rfcs/20260322161222-release-v1.26.26.md)

## Highlights

### 📋 **Universal Clipboard Integration**
- **Native OS Support**: Removed the hard dependency on Windows PowerShell. The suite now natively detects and supports the system clipboard on **Windows**, **macOS**, **Linux** (Wayland/X11), and **Android** (Termux).
- **Zero-Config Logic**: Automatically uses `pbcopy/pbpaste` (macOS), `wl-copy/wl-paste` (Wayland), `xclip/xsel` (Linux), or `termux-clipboard-*` (Android) as appropriate.
- **Improved Reliability**: Centralized clipboard handling into unified helper functions ensures that future features will automatically benefit from cross-platform compatibility.

---

# Release Notes - v1.26.24 (Isotropic Mouse Hit-Testing)

**Date**: 2026-03-22
**Version**: v1.26.24
**Request ZID**: 20260322154532
**RFC**: [docs/rfcs/20260322154532-release-v1.26.24.md](docs/rfcs/20260322154532-release-v1.26.24.md)

## Highlights

### 🎯 **Isotropic Mouse Hit-Testing**
- **Window Snap Immunity**: Fixed a severe selection bug where hit-test alignment completely drifted when the mpv window was resized or snapped to half the screen (non-16:9 aspect ratios).
- **Mathematical Overhaul**: The X-coordinate mapping now strictly anchors to the physical center of the screen and calculates horizontal offsets using the height-derived scaling factor (`scale_isotropic = oh / 1080`). 
- **Pixel-Perfect Tracking**: This mathematically guarantees that the invisible hit-test grid precisely tracks the physical pixels of the ASS-rendered text, completely irrespective of window stretching, letterboxing, or snapping.

---

# Release Notes - v1.26.22 (Drum Window Hit-Test Calibration)

**Date**: 2026-03-22
**Version**: v1.26.22
**Request ZID**: 20260322153215
**RFC**: [docs/rfcs/20260322153215-release-v1.26.22.md](docs/rfcs/20260322153215-release-v1.26.22.md)

## Highlights

### 🥁 **Precise Drum Window Hit-Testing**
- **Configurable Calibration**: Introduced `dw_vline_h_mul`, `dw_sub_gap_mul`, and `dw_char_width` as tunable options. This eliminates "click-drift" where selecting a word would hit the line above or below at large font sizes.
- **Consolas Optimization**: Calibrated the default multipliers specifically for the Consolas monospace font family, ensuring that highlights (red) align exactly with character boundaries regardless of text length.
- **Multi-Size Modes**: Reorganized `mpv.conf` into switchable "Modes" (e.g., MODE 1 for size 30, MODE 2 for size 34), allowing for instant calibration swapping when changing font sizes.

---

# Release Notes - v1.26.20 (Agent Config Standardization)

**Date**: 2026-03-22
**Version**: v1.26.20
**Request ZID**: 20260322135917
**RFC**: [docs/rfcs/20260322135917-release-v1.26.20.md](docs/rfcs/20260322135917-release-v1.26.20.md)

## Highlights

### 🚄 **Agent Configuration Standardization**
- **Documentation Parity**: Corrected a discrepancy in `AGENTS.md` where the specialized configuration folder was incorrectly referenced as `.agents/`. It is now correctly documented as **`.agent/`**, matching the actual filesystem structure.
- **Improved Clarity**: Standardized the terminology used to describe agent capabilities and OpenSpec workflows to ensure a more cohesive developer experience.

---

# Release Notes - v1.26.18 (Centralized Config & Styling)

**Date**: 2026-03-22
**Version**: v1.26.18
**Request ZID**: 20260322135347
**RFC**: [docs/rfcs/20260322135347-release-v1.26.18.md](docs/rfcs/20260322135347-release-v1.26.18.md)

## Highlights

### ⚙️ **Centralized Configuration Management**
- **Unified Control**: All adjustable script parameters from the core engine have been migrated into your main `mpv.conf`. You can now fine-tune AutoPause, Drum Mode, and Search HUD behavior directly without touching a single Lua file.
- **Improved Discoverability**: Added clear, in-line documentation for each parameter, explaining its use cases and default value.
- **Functional Templates**: Restored common configuration templates (e.g. `alang`, `slang`, `sub-visibility`) as easy-to-use commented-out examples in `mpv.conf`.

### 🎨 **Stylized & Uniform Configuration**
- **Cohesive Design Language**: Standardized both `mpv.conf` and `input.conf` with a uniform visual style. Every section now features a 75-character wide header for maximum clarity and professionalism.
- **Sectioned Documentation**: Reorganized parameters and keybindings into logical blocks, making the configuration files self-documenting and easier to navigate.

---

# Release Notes - v1.26.16 (Smart Font Scaling Integration)

**Date**: 2026-03-22
**Version**: v1.26.16
**Request ZID**: 20260322132514
**RFC**: [docs/rfcs/20260322132514-release-v1.26.16.md](docs/rfcs/20260322132514-release-v1.26.16.md)

## Highlights

### 📏 **Smart Font Scaling Core integration**
- **Native Logic**: Ported the experimental font scaling logic from `fixed_font.lua` directly into the core `lls_core.lua` engine for a more robust and unified architecture.
- **Softer Scaling Formula**: Implemented a mathematically weighted "Softer Scaling" algorithm. This ensures subtitles remain legible on small windows without causing aggressive multi-line text wrapping that obscures the video.
- **Centralized Config**: Added formal `script-opts` to `mpv.conf`. You can now enable/disable scaling and tune its "strength" (e.g., `lls-font_scale_strength=0.5`) directly from your main configuration file.
- **Architectural Cleanup**: Deleted the standalone `scripts/fixed_font.lua` script, simplifying the installation and reducing file clutter.

### 🛡️ **Drum Mode Consistency Fix**
- **Sync Fidelity**: Internal improvements to how Drum Mode and OSD overlays interact with the new scaling engine to prevent layout desync during rapid window resizing or track switching.

---

# Release Notes - v1.26.14 (Subtitle Parsing Fix)

**Date**: 2026-03-22
**Version**: v1.26.14
**Request ZID**: 20260322123553
**RFC**: [docs/rfcs/20260322123553-release-v1.26.14.md](docs/rfcs/20260322123553-release-v1.26.14.md)

## Highlights

### 🥁 **Subtitle Parsing Robustness**
- **BOM Handling**: Improved the custom `.srt` parser to correctly handle files starting with a UTF-8 Byte Order Mark (BOM). This fixes a bug where the very first subtitle of a BOM-encoded file was consistently skipped in Drum Mode.
- **Invisible Character Removal**: The parser now proactively strips invisible architectural markers at the file's start, ensuring the first subtitle ID is correctly identified as a numeric sequence.

---

# Release Notes - v1.26.12 (Drum Formatting & Sync Fidelity)

**Date**: 2026-03-21
**Version**: v1.26.12
**Request ZID**: 20260321213543
**RFC**: [docs/rfcs/20260321213543-release-v1.26.12.md](docs/rfcs/20260321213543-release-v1.26.12.md)

## Highlights

### 🥁 **Seamless Drum Mode Layout**
- **Unified Block Rendering**: Drum Mode now mathematically glues all historical, active, and future text lines into a single, cohesive ASS rendering block. This totally eliminates all visual gaps, padded box overlaps, and the previous split "bifurcation" between top/bottom lines.
- **Strict OSD Styling**: Standard Subtitles and Drum Mode now have physically decoupled style commands. Drum Mode strictly forces an ultra-clean `outline-and-shadow` appearance, while regular subtitles can still natively enjoy the PotPlayer "Black Frame" aesthetic without polluting Drum readability.

### 🛡️ **Position Sync Fidelity**
- **Dynamic Live Tracking**: Drum Mode's vertical position explicitly reads the native `secondary-sub-pos` directly from mpv in real-time. Manually moving the secondary track with `Shift+R`/`Shift+T` (or `К`/`Е`) now yields immediate, pixel-perfect position tracking within the Drum UI itself.
- **Position Toggle Repaired**: Fixed a state-desync bug where tapping `y` to jump between Top/Bottom would update internal script variables without successfully notifying mpv's actual property renderer.

### 🤫 **UI Interference Cleanup**
- **Sleek Navigating**: Forcibly disabled the native, low-res mpv `osd-bar` (timeline scale) globally. Frantically skipping through subtitle lines with `a` or `d` will no longer trigger ugly timeline artifacts. The visual timeline remains cleanly sequestered within the elegant OSC invoked via your `TAB` key.

---

# Release Notes - v1.26.10 (OpenSpec Integration)

**Date**: 2026-03-21
**Version**: v1.26.10
**Request ZID**: 20260321182207
**RFC**: [docs/rfcs/20260321182207-release-v1.26.10.md](docs/rfcs/20260321182207-release-v1.26.10.md)

## Highlights

### 🚄 **OpenSpec Workflow Integration**
- **Spec-Driven Development**: The project now supports a formal OpenSpec workflow, enabling precise alignment between human intent and AI implementation.
- **Structured Changes**: New features and fixes are now managed through a unified **Propose → Apply → Archive** lifecycle, ensuring every change is documented, designed, and verified.

### 🤖 **Enhanced Agent Capabilities**
- **Specialized Slash Commands**: Added native support for `/opsx-propose`, `/opsx-apply`, `/opsx-archive`, and `/opsx-explore` directly within the Antigravity chat.
- **Discovery Document**: Created `AGENTS.md` to provide a central reference for all specialized agent skills and workflows available in the repository.
- **Informed Assistance**: Configured `openspec/config.yaml` with deep project context (Tech stack, Design philosophy) to ensure more relevant and "premium" AI assistance.

---

# Release Notes - v1.26.8 (Subtitle Feature Consistency & Feedback)

**Date**: 2026-03-14
**Version**: v1.26.8
**Request ZID**: 20260313235721
**RFC**: [docs/rfcs/20260314000819-release-v1.26.8.md](docs/rfcs/20260314000819-release-v1.26.8.md)

## Highlights

### 🛡️ **Robust Feature Guarding**
- **External Track Detection**: The advanced feature suite (Drum Mode, Drum Window, and Search HUD) now intelligently verifies whether the currently active subtitles are external files before activating.
- **Explicit Feedback**: If you are using embedded subtitles (e.g., inside an `.mkv`), these features will now gracefully inform you that they "Require external subtitle files" instead of silently failing or getting stuck in an "ON" state.

### 📋 **Descriptive Mode Cycling**
- **Copy Mode (`z`)**: Pressing `z` to cycle the subtitle copying mode now presents clear, descriptive OSD labels: `A (Primary/Target)` and `B (Secondary/Translation)`. When only a single `.srt` track is loaded, the engine reports "Fixed to Primary (Single Track)".
- **Secondary Subtitles (`j`)**: When attempting to cycle translation tracks with only one file loaded, the engine now provides format-aware context. Instead of just asserting "OFF", the status will explain if translations are "Managed internally by ASS styling" or if there is simply "Only 1 track available."

---

# Release Notes - v1.26.4 (Cyrillic Import Fix & UI Silence)

**Date**: 2026-03-13
**Version**: v1.26.4
**Request ZID**: 20260313225638
**RFC**: [docs/rfcs/20260313225638-release-v1.26.4.md](docs/rfcs/20260313225638-release-v1.26.4.md)

## Highlights

### 🥁 **Cyrillic-Free .ass Import**
- **Targeted Filtering**: Subtitle parsing now proactively filters out Cyrillic lines when importing `.ass` files for the Drum Window.
- **Pure Environment**: This ensures your primary reading track remains a focused, target-language only environment, even if the source file contains interleaved translations.

### 🤫 **Silent UI transitions**
- **Cleaner UX**: Removed the "OPEN/CLOSED" OSD messages when toggling the Drum Window.
- **Contextual Feedback**: The visual emergence of the window provides sufficient feedback, resulting in a more professional and cinematic feel during immersion.

### 🛠️ **Hoisted Core Utilities**
- **Architectural Cleanup**: Hoisted all text-processing helpers (`has_cyrillic`, `is_word_char`, etc.) to the top of `lls_core.lua` for global reliability.
- **Nil-Safety Hardening**: Added defensive guards to all core string functions to prevent runtime crashes on malformed subtitle inputs.

---

# Release Notes - v1.26.2 (Externalized Search Styles)

**Date**: 2026-03-12
**Version**: v1.26.2
**Request ZID**: 20260312212143
**RFC**: [docs/rfcs/20260312212143-release-v1.26.2.md](docs/rfcs/20260312212143-release-v1.26.2.md)

## Highlights

### 🔦 **Externalized Search Styling**
- **Precision Configuration**: Added new parameters for hit colors, selection colors, and bolding toggles.
- **Ultra-Minimalist Defaults**: The project now defaults to a high-contrast "Black & Bold" look while allowing full user customization via the `Options` table.
- **Selection Marker Legacy**: The selection marker (`> `) and colored highlights are now optional architectural components controllable via logic or config.

---

# Release Notes - v1.26.0 (Visual Search Feedback)

**Date**: 2026-03-12
**Version**: v1.26.0
**Request ZID**: 20260312202316
**RFC**: [docs/rfcs/20260312202316-release-v1.26.0.md](docs/rfcs/20260312202316-release-v1.26.0.md)

## Highlights

### 🔦 **Hit-Highlighting in Search**
- **Elegant Visual Cues**: The search results list now elegantly highlights matching characters using **Bold High-Contrast** colors.
- **Intelligent Contrast**: Highlights adapt to the selection state—turning **White** when a line is selected to ensure maximum readability against the red selection bar.
- **Fuzzy Accuracy**: Even non-contiguous matches (e.g., `mne` matching **m**a**n**ag**e**) are precisely highlighted.

---

# Release Notes - v1.25.2 (UI Visibility Enhancement)

**Date**: 2026-03-12
**Version**: v1.25.2
**Request ZID**: 20260312195256
**RFC**: [docs/rfcs/20260312195256-release-v1.25.2.md](docs/rfcs/20260312195256-release-v1.25.2.md)

## Highlights

### 🎨 **Brighter Active Subtitles**
- **Enhanced Contrast**: The active subtitle line in the Drum Window (Static Reading Mode) is now colored in a **Brighter Blue** for significantly better visibility against the window's beige background.
- **Improved Focus**: This makes it much easier to track the current playback position when reading through a long subtitle track.

---

# Release Notes - v1.25.1 (Compact Proximity Search)

**Date**: 2026-03-12
**Version**: v1.25.1
**Request ZID**: 20260312194600
**RFC**: [docs/rfcs/20260312194622-release-v1.25.1.md](docs/rfcs/20260312194622-release-v1.25.1.md)

## Highlights

### 🎯 **Compact Proximity Ranking**
- **Intelligent Density**: The search engine now evaluates how "compact" a fuzzy match is. If you type `mne`, results where these letters are found within a single word (like "**m**a**n**ag**e**") are ranked significantly higher than results where they are scattered across the entire sentence.
- **UX Refinement**: This drastically reduces "noise" in the search results when using short fuzzy queries while maintaining the flexibility of order-independent keyword matching.

---

# Release Notes - v1.25.0 (True Fuzzy Keyword Search)

**Date**: 2026-03-12
**Version**: v1.25.0
**Request ZID**: 20260312192633
**RFC**: [docs/rfcs/20260312192633-release-v1.25.0.md](docs/rfcs/20260312192633-release-v1.25.0.md)

## Highlights

### 🔍 **True Fuzzy Keyword Search (Bash-Style)**
- **Order-Independent Matching**: You can now type keywords in any order (e.g., `fox quick` finds `The Quick Brown Fox`).
- **Approximate Keywords**: Each word in your search can be fuzzy (e.g., `tst ths` finds `tested this`).
- **Intelligent Ranking**: While order is independent, the engine explicitly rewards correct sequences and literal matches, keeping the most "natural" results at the top.

---

# Release Notes - v1.24.10 (Search Relevance & Cyrillic Parity)

**Date**: 2026-03-12
**Version**: v1.24.10
**Request ZID**: 20260312185300
**RFC**: [docs/rfcs/20260312185338-release-v1.24.10.md](docs/rfcs/20260312185338-release-v1.24.10.md)

## Highlights

### 🎯 **Relevance-Based Search Sorting**
- **Scoring Engine**: Results are now sorted by "Relevance" rather than chronological order. Exact matches and prefix-substring matches now always appear at the very top of the list.
- **Cyrillic Case Parity**: Implemented a custom UTF-8 lowercase helper. Search is now fully case-insensitive for Russian characters, ensuring consistent discovery of Cyrillic phrases regardless of input case.

---

# Release Notes - v1.24.9 (Search HUD UX Enhancements)

**Date**: 2026-03-12
**Version**: v1.24.9
**Request ZID**: 20260312175031
**RFC**: [docs/rfcs/20260312175031-release-v1.24.9.md](docs/rfcs/20260312175031-release-v1.24.9.md)

## Highlights

### 📋 **Bash-Style Word Deletion**
- **Action**: Added `Ctrl + W` (and `Ctrl + Ц`) to the Search HUD.
- **Behavior**: Instantly deletes the word before the cursor, matching the behavior of terminal environments like Bash. This significantly improves editing efficiency when refining search queries.

---

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
