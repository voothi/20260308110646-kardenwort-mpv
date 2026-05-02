# Kardenwort MPV - Language Acquisition Suite

[![Version](https://img.shields.io/badge/version-v1.58.30-blue)](https://github.com/voothi/20260308110646-kardenwort-mpv/releases/tag/v1.58.30) 
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) 

A high-performance [mpv](https://mpv.io/) configuration specifically engineered for immersion-based language acquisition, optimized for the convenient consumption of **Dual-Subtitle** (DualSubs) content.

> **Attribution & Source**
>
> Developed and maintained by **Denis Novikov (voothi)** as part of the Kardenwort ecosystem.
>
> *   **Repository**: [Source Code](https://github.com/voothi/20260308110646-kardenwort-mpv)

> [!IMPORTANT]
> **Optimized Acquisition Environment**
>
> **Validated Setup:**
> *   **Platform**: Windows 11, macOS, Linux, Android (Termux).
> *   **Workflow**: Optimized for both merged `.ass` and separate `.srt` files.
> *   **Interface**: Distraction-free OSC (hidden by default).


## Table of Contents

- [Project Goals](#project-goals)
- [Distinctive Advantages](#distinctive-advantages)
- [Advanced Subtitle Workflow](#advanced-subtitle-workflow)
- [Intelligent Scripts](#intelligent-scripts)
  - [Universal Subtitle Search](#universal-subtitle-search)
  - [Karaoke-Safe Autopause](#karaoke-safe-autopause)
  - [Drum Mode (Dynamic Multi-line Flow)](#drum-mode)
  - [Static Reading Mode (Drum Window)](#static-reading-mode)
  - [Anki Highlighting & Export](#anki-mining)
  - [Intelligent Range Selection & Copy](#intelligent-range-selection)
  - [Smart Spacebar](#smart-spacebar)
  - [Smart Font Scaling](#smart-font-scaling)
- [Immersion-Centric Keybindings](#immersion-centric-keybindings)
- [Configuration Guide (mpv.conf)](#configuration-guide-mpvconf)
- [Installation](#installation)
- [Development Analytics](#development-analytics)
- [License](#license)

---

## Project Goals

The primary objective of this suite is to provide a highly optimized environment for the **Extensive Acquisition** of languages through the convenient consumption of video content. 

This project is specifically designed for learners who work with **Dual Subtitles** (DualSubs)—where original target-language captions are paired with a secondary translation track.

### Core Objectives:
1.  **Dual-Subtitle Optimization**: Engineered to handle the visual and technical challenges of displaying two subtitle tracks (Original & Translated) in `.srt` or `.ass` formats simultaneously. 
2.  **Convenient Content Consumption**: Focuses on the *playback phase* of intensive acquisition. Every feature—from [Independent Shifting](#positional-flexibility) to [Smart Spacebar](#smart-spacebar)—is built to remove friction during long, high-volume immersion sessions.
3.  **YouTube Auto-Subtitle Handling**: Provides specialized tools like [Static Reading Mode](#static-reading-mode) to maintain linguistic context when dealing with poorly synchronized or lower-quality YouTube-extracted captions.
4.  **Local Offline Focus**: Aimed at a robust local-first workflow. Learners can download media and subtitles, prepare them using external tools, and then consume them offline with maximum stability and control.
5.  **Anki Workflow Core**: Deep integration with Anki/TSV databases. Highlighting, context extraction, and non-contiguous term matching are built-in native features, not just afterthoughts.

### Workflow Integration
While this project focuses on the **consumption** of material, it is designed to be the final step in a broader acquisition workflow:
- **Preparation**: For downloading and translating your material, we recommend companion tools like [voothi/subtitles](https://github.com/voothi/20251228104300-subtitles/).
- **Consumption**: Use this suite to engage with the prepared Dual-Subtitle content for extensive acquisition.

[Return to Top](#table-of-contents)

## Distinctive Advantages

This suite solves problems that standard video players and generic scripts ignore:
1.  **Dual-Layout Keybindings**: Native support for both English and Cyrillic keyboard layouts. Your hotkeys work flawlessly without needing to constantly switch your system input language.
2.  **Karaoke-Ready Autopause**: Unlike standard autopause scripts that stutter on `.ass` word-by-word highlights, this suite precisely scans for formatting tags to stop *only* when a phrase is complete.
3.  **Non-Intrusive OSD Design**: All status popups (Play/Pause, Layout, Visibility) are minimized and pushed to the **Left-Center** of the screen. Your visual field remains 100% clear.
4.  **ASS Mathematics Protection**: The suite dynamically sizes simple text, but completely respects the baked-in layout geometry of complex immersive video files.
5.  **Watch-Later Cleanliness**: Temporary visibility toggles for intense immersion sessions are explicitly excluded from `watch-later` saving, ensuring you never corrupt your clean baseline configuration.
6.  **[Static Reading Mode](#static-reading-mode)**: Converts the standard scrolling subtitle "drum" into a frozen, text-editor style viewport. Navigate, mouse-select, double-click to seek, and edge-scroll without the text flickering or moving under your cursor.
7.  <span id="positional-flexibility">**Positional Flexibility**</span>: Fine-grained vertical adjustment for both primary and secondary tracks. Manually resolve overlaps and tune your visual field without touching a configuration file.
8.  **Universal Fuzzy Search**: Instantly look up vocabulary and phrases across the entire subtitle file with an independent, non-intrusive overlay. Supports clipboard pasting and direct mouse selection.
9.  **Hardware-Accelerated Mouse Selection**: Click-and-drag text selection inside the Drum Window tracks your cursor at 60fps using native `mouse_move` hardware events.
10. **Intelligent Anki Integration**: Save vocabulary with a single click. High-recall matching ensures your saved words stay highlighted (Amber/Purple/Mixed) across the entire session. Implements **Multi-Pivot Grounding** (`Line:Word:TermPos`) to mathematically eliminate highlight bleed.
11. **Contextual Tooltips**: Peek at translations instantly via keyboard (`e`) or Right-Click (`RMB`) in the reading window. Supports **full bidirectional synchronization** of Yellow/Pink highlights.
12. **Scanner-Based Precision**: A robust state-machine parser handles complex German boundaries and protects "Original Form" subtitle spacing.
13. **Smart Stacking Engine**: Unified layout coordination for dual-track subtitles that restores manual positioning control while preventing visual overlap by default.
14. **Selection Priority**: Persistent multi-word selections (Ctrl + LMB) now take visual precedence over transient cursor highlights.
15. **Dynamic Source Discovery**: Automatically extracts YouTube/Source URLs from local metadata files (`.url`, `.txt`, `.md`) for zero-touch Anki metadata population.
16. **Chromatic Selection Theme**: Implements a "Warm vs. Cool" workflow using Gold for contiguous and Neon Pink for split-phrase selections.
17. **Hardware Interaction Shielding**: A bulletproof 150ms "interaction shield" that ignores mouse jitter and "ghost clicks" from remote control software immediately after keyboard commands. Now **synchronized across all HUD modes** (Search, Drum, Tooltip).
18. **Multi-Layout Shortcut Lists**: All major command parameters now support space, comma, or semicolon separated lists. Map `t`, `е`, and `MBTN_LEFT` to the same action simultaneously in `mpv.conf`.
19. **Precision Context Verification**: Implements word-tokenized intersection for vocabulary matches, ensuring highlights persist through punctuation and formatting differences.
20. **Embedded Subtitle Support**: The Drum Window (Mode W) now supports internal/embedded subtitle tracks in MKV files, providing a consistent experience across all media formats.
21. **Footprint-based Precision Rendering**: Overhauled punctuation discipline with sub-token stack recalculation and 3-tier nesting gradients. Implements a strictly **Surgical Highlighting** model that eliminates visual ambiguity by coloring only word-body tokens.
22. **Zero-Overhead Periodic Sync**: Implements `mtime` + `size` fingerprinting to bypass expensive parsing and filesystem scanning for TSV and URL sidecars when data is unchanged.
23. **Sticky Column Navigation**: Vertical keyboard movement in the Drum Window now preserves horizontal OSD position, snapping to the closest word on the target line for a professional, editor-like experience.
24. **Freeze-Proof Export Engine**: A hardened string search logic with mandatory forward-progress guards and empty-term validation to eliminate UI freezes during selection.
25. **Contiguous Multi-Line Selection**: Refined selection logic that reliably maintains the highlighting anchor across subtitle line boundaries, enabling seamless "mass selection" via keyboard navigation.
26. **Configurable Jump Distances**: Fully adjustable navigation speed. Users can customize the exact number of words or lines jumped during Ctrl-boosted navigation via `mpv.conf`.
27. **Independent Book Mode Pointer**: Visual focus remains stable during playback or navigation in Book Mode, preventing disruptive OSD jumps.
28. **Verbatim Selection with Context**: Compliant copy functionality that preserves punctuation and formatting while intelligently splicing focal lines into surrounding context.
29. **Unified Source Fallback**: Automatically detects and extracts text from the most relevant subtitle track (Target vs Translation) during copy/Anki operations, eliminating track-switching friction.
30. **Temporal Merging Guard**: Advanced navigation logic that prevents scrolling "stutter" by detecting and bridging natural gaps in subtitle timing during rapid seeks.
31. **Hardened Performance Pipeline**: Systemic O(1) performance invariants for character scanning and character-class lookup, ensuring fluid OSD interaction even with massive subtitle files.
32. **Absolute Verbatim Export**: 100% fidelity mining that preserves all source formatting, hyphens, and whitespace, strictly adhering to the "Source as Truth" philosophy.
33. **Dynamic Search Wrapping**: The Search HUD now features a robust **multi-line wrapping engine** with pixel-perfect hit-testing, ensuring all results remain selectable regardless of layout complexity.
34. **Intelligent Session Resumption**: Automatically reloads the last active media path on blank launch with high-resolution visual confirmation using a decoupled session manager.
35. **Smart Diagnostics & Logging**: Level-aware logging with log deduplication and single-summary startup health checks to eliminate console spam and report configuration errors professionally.
36. **Standardized Historicity**: Centralized "Ground Truth" for terminology and dual-notation color specifications (BGR/RGB) ensures long-term architectural integrity and AI consistency.
37. **Visual Line Awareness**: Vertical navigation in the Drum Window is now visual-line aware for multi-line wrapped subtitles, with deterministic landing logic and viewport tracking.

[Return to Top](#table-of-contents)

## Advanced Subtitle Workflow

Instead of relying on mpv's native dual-subtitle loading (which often strips formatting), this configuration advocates for a **Merged .ass Workflow**:

1.  **Multiple Tracks**: Use [Subtitle Edit](https://github.com/SubtitleEdit/subtitleedit) to merge target and native language tracks.
2.  **Custom Positioning**: Bake positioning (Top/Center/Bottom) and colors directly into a single `.ass` file.
3.  **Visual Protection**: Our `mpv.conf` respects the internal mathematics of the `.ass` file, ensuring margins and styles are never overridden by the player.

[Return to Top](#table-of-contents)

## Intelligent Scripts

### <span id="universal-subtitle-search"></span>Universal Subtitle Search
A high-performance navigation overlay that decouples content lookup from playback.
- **Dynamic Multi-Line Wrapping**: Both search queries and results now flow naturally across multiple visual lines, with the interface dynamically adjusting its height and dropdown position.
- **Synchronized Hit-Testing**: Introduced pixel-perfect mouse interaction for wrapped results using `FSM.SEARCH_HIT_ZONES`. Click targets now track the visual OSD position of the text.
- **Hard-Sync Logic**: Every jump uses explicit `seek absolute+exact` commands to ensure primary and secondary tracks are perfectly aligned.
- **Toggle**: `Ctrl + F` (English) or `Ctrl + А` (Russian).

#### **Search HUD Interaction**
| Key | Action |
|---|---|
| `Arrows Up/Down` | Navigate through result list |
| `ENTER` | Seek to selected subtitle and close search |
| `Ctrl + V` / `Ctrl + М` | Paste from clipboard |
| `Ctrl + A` / `Ctrl + Ф` | Select all text in query bar |
| `Ctrl + W` / `Ctrl + Ц` | Delete previous word (Bash-style) |
| `Shift + LEFT/RIGHT` | Select text range within query |
| `HOME` / `END` | Jump cursor to start/end of query |
| `ESC` | Discard query or close search |

### Karaoke-Safe Autopause
Advanced pause logic designed specifically for immersion students using `.ass` karaoke-formatted subtitles.
- **End of Phrase**: By default, it pauses only when the sentence is finished (detecting the end of the `{\c}` tag sequence).
- **Word by Word**: Toggle with `K` to pause after every word highlighted in your karaoke tracks.
- **Dual-Track Aware**: Intelligently tracks timings in both primary and secondary tracks to ensure you never miss a phrase.
- **Toggle**: `P` (English) or `З` (Russian).

### <span id="drum-mode"></span>Drum Mode (Dynamic Multi-line Flow)
The primary immersion mode designed for rapid reading and phrasal awareness during playback.
- **Continuous Context**: Synchronizes multiple historical and future subtitle lines into a single cohesive OSD block.
- **Dynamic Vertical Tracking**: Real-time position syncing with `secondary-sub-pos`. Adjust the entire block height on-the-fly using `Shift+R` / `Shift+T`.
- **Minimalist Aesthetic**: Forces an ultra-clean `outline-and-shadow` style to ensure maximum readability against any video background, decoupling it from regular subtitle styles.
- **Dual-Track Synergy**: Seamlessly renders both primary and secondary tracks in a unified stack, providing instant translation context without visual clutter.
- **Toggle**: `C` (English) or `С` (Russian).

### <span id="static-reading-mode"></span>Static Reading Mode (Drum Window)
A high-performance rolling context engine that has evolved into a robust **Static Reading Mode** for in-depth immersion analysis.
- **Advanced Mouse Selection**: Experience text-editor smooth interactions. Click and drag (`LMB`) to instantly highlight ranges, or `Shift+Click` to extend. Hardware-accelerated for 60fps tracking.
- **Actionable Text**: Double-Click any subtitle word to instantly seek video playback to that exact phrase and re-center the viewport.
- **Stationary "Book Mode"**: Toggle with **`b`** to lock the viewport. Navigating through lines or selecting words won't cause the window to scroll or flicker, providing a stable, reading-focused experience.
- **Selection Persistence**: Manual seeks via `a`/`d` no longer clear your yellow highlight, allowing you to check context and return to your pending export line.
- **"Original Form" Display**: Toggle `dw_original_spacing` to perfectly mirror any subtitle's whitespace and character-stream formatting without sacrificing word-level selection.
- **Contextual Tooltips**: Press **`e`** or **Right-Click** on any line to instantly see a translation hint. Supports **full word-wrapping** and **bidirectional highlight synchronization** with the primary window.
- **Static Viewport**: The viewport remains stable while navigating via arrows, providing a flicker-free environment for reading and selection.
- **Boundary-Aware Sliding Window**: The viewport intelligently shifts at track edges to maintain consistent line density and vertical positioning.
- **Interaction Shielding & Stability**: Features a 150ms shield that silences the mouse arrow following keyboard navigation, preventing accidental pointer "jumps" when using remote controls.
- **Active Line Visibility**: The current playback line is highlighted in a **high-contrast bright blue**, ensuring it remains perfectly legible against the window's dark theme.
- **Sticky Column Navigation**: Vertical movement (Arrows Up/Down) now preserves the horizontal OSD position, mimicking the VSCode carriage transition for more predictable keyboard navigation.
- **Performance Layout Cache**: A structure-aware caching engine that eliminates redundant OSD calculations during mouse movement, ensuring a smooth 60fps interaction experience.
- **Toggle**: `W` (English) or `Ц` (Russian).

### <span id="anki-mining"></span>Anki Highlighting & Export
A specialized subsystem that bridges the gap between immersion and flashcard creation.
- **High-Recall Highlighting**: Saved vocabulary and phrases are automatically highlighted across the entire video. 
  - **Orange**: Contiguous word sequences.
  - **Purple**: Split-word constructs (e.g., separable verbs).
  - **Mixed**: Blended colors for overlapping terms.
- **Precision Grounding**: Uses a comprehensive coordinate system (`Line:Word:TermPos`) to anchor highlights to specific scenes, preventing common words from bleeding across unrelated segments.
- **Multi-Word Selection**: 
  - `Ctrl + LMB`: Accumulate individual words into a yellow pending selection.
  - `MMB`: Commit the selected set as a highlight and export it to your TSV database.
- **Automatic Sanitization**: Strips leading/trailing punctuation and bracketed metadata (e.g. `[Musik]`) to ensure cards are optimized for dictionary matching. Smart joiners preserve hyphens/slashes in German compounds.
- **Drag-to-Pair (Range Conversion)**: High-performance mining upgrade. Contiguous yellow selection ranges can now be converted into discrete paired selection sets (Pink) in a single action via keyboard (`t`) or Ctrl+Drag.
- **Dynamic Context**: The engine intelligently scans surrounding lines to capture grammatically complete sentences for your flashcards.
- **Instant Record Access**: Press **`o`** within the Drum Window to instantly open your active TSV database in your default editor.
- **Dynamic Source Discovery**: Automatically scans for `.url`, `.txt`, or `.md` files in the media folder to extract `SourceURL` metadata for Anki exports.
- **Zero-Latency Mining**: In-memory row injection provides instantaneous feedback when saving words, bypassing the performance penalty of full TSV re-parsing.

### <span id="intelligent-range-selection"></span>Intelligent Range Selection & Copy
A sophisticated extraction tool that supports substring and multi-line range selection.
- **Range Selection**: Hold **`Shift`** with navigation keys to select exact word ranges or multiple consecutive subtitle lines.
- **Substring Copy**: `Ctrl+C` aggregates only the highlighted words into a clean, format-free clipboard export.
- **Symmetrical Traversal**: Intelligently leaps across dual-track layouts to retrieve pure target-language lines.
- **Copy Modes**: Toggle between Target text and Translation chunks (Toggle: `Z` / `Я`).
- **Context expansion**: Request surrounding sentences to export chronological paragraphs (Toggle: `X` / `Ч`). Requires separate subtitle files.

### Smart Spacebar
A custom key handler that distinguishes between quick taps and long holds.
- **Play While Held**: Pressing and holding `SPACE` bypasses ALL autopause rule sets (Word-by-word and End-of-phrase). The video plays smoothly as long as the key is down.
- **Tap to Toggle**: Quickly tapping `SPACE` (< 200ms) functions as a standard Play/Pause toggle.

### Smart Font Scaling
Ensures that your immersion material remains perfectly readable regardless of window size, while protecting complex layouts.
*   **For `.srt` Files**: Dynamically adjusts subtitle scaling so text doesn't become tiny on large monitors or giant in small windows. Includes a **Softer Scaling** formula to prevent aggressive wrapping.
*   **For `.ass` Files**: Intelligently detects the Advanced SubStation format and bypasses scaling, allowing the file's internal positioning mathematics to render flawlessly.
*   **Configurable**: Enable/Disable or tune the "scaling strength" directly in `mpv.conf`.

[Return to Top](#table-of-contents)

## Immersion-Centric Keybindings

Optimized `input.conf` for rapid review, featuring **dual-layout support** (English/Cyrillic).

| Key (EN) | Key (RU) | Action |
|---|---|---|
| `RIGHT` / `LEFT` | `RIGHT` / `LEFT` | Exact **2-second** seek forward / backward |
| `A` / `D` | `Ф` / `В` | Exact **2-second** seek **backward / forward** (Window Mode / Global) |
| `a` / `d` | `ф` / `в` | **Seek** to previous / next subtitle line |
| `q` / `Q` | `й` / `Й` | **Quit** / Quit and save position |
| `SPACE` / `LMB` | `SPACE` / `LMB` | **Smart Space**: Hold to Play, Tap to Toggle Pause |
| `TAB` | `TAB` | Cycle OSC Visibility (**Always ↔ Auto ↔ Never**) |
| `m` | `ь` | Toggle **Mute** |
| `0` / `9` | `0` / `9` | Adjust **Volume** (Up / Down) |
| `[` / `]` | `х` / `ъ` | Decrease / Increase **Playback Speed** (10%) |
| `{` / `}` | `Х` / `Ъ` | Halve / Double **Playback Speed** |
| `BS` | `BS` | **Reset Playback Speed** (Set to 1.0) |
| `.` / `,` | `ю` / `б` | Frame Step Forward / Backward |
| `v` | `м` | Toggle **Fullscreen** |
| `W` / `E` | `Ц` / `У` | **Panscan** (Zoom Out / In) |
| `r` / `t` | `к` / `е` | Adjust **Primary** Position (Up / Down) |
| `Shift+R` / `Shift+T` | `К` / `Е` | Adjust **Secondary** Position (Up / Down) |
| `j` | `о` | **Cycle Secondary Track** (Translation) |
| `s` | `ы` | Toggle Subtitle Visibility (Styled OSD) |
| `e` | `у` | **Toggle Tooltip** (Reading Mode Only) |
| `y` | `н` | Toggle Secondary Position (**Top ↔ Bottom**, SRT only) |
| `c` | `с` | Toggle **Drum Mode** (Dynamic Multi-line Context) |
| `w` | `ц` | Toggle **Static Reading Mode** (Drum Window) |
| `b` | `и` | Toggle **Book Mode** (Static Viewport Lock) |
| `n` | `т` | Toggle **Hover Tooltips** (Reading Mode) |
| `h` | `р` | Toggle **Global Highlighting** (Anki Matches) |
| `o` | `щ` | **Open Record File** (Active TSV database) |
| `Ctrl+f` | `Ctrl+а` | Toggle **Universal Subtitle Search** Overlay |
| `Ctrl+c` | `Ctrl+с` | **Copy Subtitle** (Extract clean text to clipboard) |
| `x` / `X` | `ч` / `Ч` | Toggle **Context Copy** (Include surrounding lines) |
| `z` / `Z` | `я` / `Я` | Cycle **Copy Mode** (Target ↔ Translation) |
| `p` / `P` | `з` / `З` | Toggle **Autopause** (ON/OFF) |
| `k` / `K` | `л` / `Л` | Toggle **Karaoke Mode** (Word-by-Word / End-of-Phrase) |
| `S` | `Ы` | Take a **Screenshot** |

[Return to Top](#table-of-contents)

---

## Configuration Guide (mpv.conf)

The project uses a centralized configuration model. All core script behaviors are controlled directly from `mpv.conf` using the `lls-` prefix.

### Key Operational Settings:
- **`sub-align-y=bottom`**: Standardizes the layout for drum mode.
- **`secondary-sub-pos=10`**: Places secondary tracks at the top of the frame.
- **`sub-pos=95`**: Places primary subtitle tracks near the bottom.
- **`sub-ass=yes`**: Enables high-quality subtitle rendering for native karaoke support.
- **`osc=no`**: Removes visual clutter from the screen.
- **`save-position-on-quit=yes`**: Pick up your immersion session exactly where you left off.

### Comprehensive Parameter Reference

#### **1. Font Scaling & Layout**
| Parameter | Default | Description |
|---|---|---|
| `lls-font_scaling_enabled` | `yes` | Enable smart scaling to keep text legible on small windows. |
| `lls-font_base_height` | `1080` | Target vertical resolution for scaling calculations. |
| `lls-font_base_scale` | `1.0` | Global scaling multiplier for all OSD text. |
| `lls-font_scale_strength` | `0.5` | Scaling intensity (0.0=Native, 1.0=Strictly fixed size). |
| `lls-sec_pos_top` | `10` | Top destination for `cycle-secondary-pos`. |
| `lls-sec_pos_bottom` | `90` | Bottom destination for `cycle-secondary-pos`. |

#### **2. AutoPause & Spacebar**
| Parameter | Default | Description |
|---|---|---|
| `lls-autopause_default` | `yes` | Enable automatic pausing at the end of each subtitle line by default. |
| `lls-karaoke_every_word` | `no` | If enabled, autopause stops after every highlighted word (Karaoke mode). |
| `lls-pause_padding` | `0.15` | Buffer delay (seconds) before pausing to ensure word completion. |
| `lls-karaoke_token` | `{\c}` | ASS markup tag used to identify active karaoke words. |
| `lls-space_tap_delay` | `0.2` | Time threshold to distinguish between tap (Toggle) and hold (Play) on Space. |

#### **3. Drum Mode (Dynamic Multi-line Context)**
| Parameter | Default | Description |
|---|---|---|
| `lls-drum_font_size` | `34` | Text size used in Drum Mode. |
| `lls-drum_font_name` | `Consolas` | Monospace font family for aligned context rendering. |
| `lls-drum_font_bold` | `no` | Apply bold styling to all text in Drum Mode. |
| `lls-drum_context_lines` | `3` | Number of surrounding subtitle lines shown for context. |
| `lls-drum_context_color` | `CCCCCC` | Text color for context (non-active) lines (BGR Hex). |
| `lls-drum_context_bold` | `no` | Apply bold styling to context lines specifically. |
| `lls-drum_context_size_mul` | `1.0` | Scale factor for context line text size. |
| `lls-drum_active_color` | `FFFFFF` | Text color for the currently active subtitle line (BGR Hex). |
| `lls-drum_active_bold` | `no` | Apply bold styling to the active playback line. |
| `lls-drum_active_size_mul` | `1.0` | Scale factor for the active line text size. |
| `lls-drum_active_opacity` | `00` | Transparency for active text (00=Opaque, FF=Transparent). |
| `lls-drum_context_opacity` | `20` | Transparency for context text (00=Opaque, FF=Transparent). |
| `lls-drum_bg_color` | `000000` | Background box color (BGR Hex). |
| `lls-drum_bg_opacity` | `60` | Background box transparency (ASS Hex 00-FF). |
| `lls-drum_border_size` | `1.5` | Size of the text outline/border. |
| `lls-drum_shadow_offset` | `1.0` | Depth of the text shadow. |
| `lls-drum_line_height_mul` | `0.87` | Vertical line spacing multiplier. |
| `lls-drum_double_gap` | `yes` | Use double spacing between distinct subtitle blocks. |
| `lls-drum_block_gap_mul` | `-0.27` | Extra spacing between distinct subtitle blocks. |
| `lls-drum_gap_adj` | `6` | Fine-tuning for vertical alignment (all tracks). |
| `lls-drum_vsp` | `0` | Vertical shift pixels (manual offset). |
| `lls-drum_track_gap" | `5.0` | Vertical spacing (%) between primary and secondary dual tracks. |
| `lls-osd_interactivity` | `yes` | Enable mouse word-selection for standard OSD subtitles. |

#### **4. SRT Style (Regular Mode)**
| Parameter | Default | Description |
|---|---|---|
| `lls-srt_font_size` | `34` | Text size for standard SRT rendering. |
| `lls-srt_font_name` | `Consolas` | Font family for standard SRT rendering. |
| `lls-srt_font_bold` | `no` | Apply bold styling to SRT subtitles. |
| `lls-srt_active_color` | `FFFFFF` | Primary text color for the active playback line. |
| `lls-srt_context_color` | `CCCCCC` | Color for non-active surrounding lines. |
| `lls-srt_active_opacity` | `00` | Transparency for the active line (00-FF). |
| `lls-srt_context_opacity` | `30` | Transparency for surrounding lines (00-FF). |
| `lls-srt_bg_color` | `000000` | Shadow/Frame color (BGR Hex). |
| `lls-srt_bg_opacity` | `60` | Background box transparency (ASS Hex 00-FF). |
| `lls-srt_border_size` | `1.5` | Size of text outline. |
| `lls-srt_shadow_offset` | `1.0` | Depth of text shadow. |
| `lls-srt_double_gap` | `yes` | Use expanded spacing for dual-track layouts. |
| `lls-srt_vsp` | `0` | Vertical spacing adjustment (pixels). |
| `lls-srt_block_gap_mul` | `-0.27` | Spacing between subtitle blocks in SRT mode. |
| `lls-srt_line_height_mul` | `0.87` | Vertical line spacing multiplier. |

#### **5. Copy Mode Configuration**
| Parameter | Default | Description |
|---|---|---|
| `lls-copy_default_mode` | `A` | Default track target for copy (A=Target, B=Translation). |
| `lls-copy_filter_russian` | `yes` | Automatically strip Cyrillic characters from Target-track copies. |
| `lls-copy_context_lines` | `2` | Number of surrounding lines to include in context copy (`X`). |
| `lls-copy_word_limit` | `3` | Number of words shown in the OSD copy notification. |

#### **6. Drum Window (Static Reading Mode)**
| Parameter | Default | Description |
|---|---|---|
| `lls-dw_font_name` | `Consolas` | Font family used in the Reading Mode window. |
| `lls-dw_font_size` | `34` | Base text size for the Static Reading Mode window. |
| `lls-dw_active_bold` | `no` | Bold active line in window. |
| `lls-dw_context_bold` | `no` | Bold context lines in window. |
| `lls-dw_active_opacity` | `00` | Transparency for active line (00-FF). |
| `lls-dw_context_opacity` | `30` | Transparency for context lines (00-FF). |
| `lls-dw_active_size_mul` | `1.0` | Scale active line font size. |
| `lls-dw_context_size_mul` | `1.0` | Scale context line font size. |
| `lls-dw_char_width` | `0.5` | Character width calibration (0.5 is exact for Consolas). |
| `lls-dw_line_height_mul` | `0.87` | Vertical line spacing multiplier. |
| `lls-dw_block_gap_mul` | `-0.27` | Spacing between distinct subtitle blocks. |
| `lls-dw_double_gap" | `yes` | Enable expanded dual-track spacing in the window. |
| `lls-dw_vsp` | `0` | Vertical shift pixels for hit-zone calibration. |
| `lls-dw_lines_visible` | `15` | Maximum number of subtitle lines visible in the viewport. |
| `lls-dw_scrolloff` | `3` | Margin lines maintained at top/bottom before the viewport scrolls. |
| `lls-dw_original_spacing` | `yes` | Preserve source subtitle's original whitespace and formatting. |
| `lls-dw_jump_words` | `5` | Words jumped during `Ctrl+Left/Right`. |
| `lls-dw_jump_lines` | `5` | Lines jumped during `Ctrl+Shift+Up/Down`. |
| `lls-dw_highlight_color` | `00CCFF` | Color for active word selection (Gold BGR). |
| `lls-dw_ctrl_select_color" | `FF88FF` | Color for split-word selection (Pink) in pending state. |
| `lls-dw_split_select_color` | `FF88B0` | Color for saved split-word highlights (Purple). |
| `lls-book_mode` | `no` | Lock viewport during navigation (True) or allow auto-scrolling (False). |

#### **7. Translation Tooltips**
| Parameter | Default | Description |
|---|---|---|
| `lls-tooltip_font_name` | `Consolas` | Font family for translation hints. |
| `lls-tooltip_font_size` | `34` | Text size for translation hints. |
| `lls-tooltip_font_bold` | `no` | Bold styling for tooltips. |
| `lls-tooltip_active_color` | `FFFFFF` | Color for the primary translation line. |
| `lls-tooltip_context_color` | `CCCCCC` | Color for surrounding context lines. |
| `lls-tooltip_active_opacity` | `00` | Transparency for the primary line. |
| `lls-tooltip_context_opacity` | `30` | Transparency for context lines. |
| `lls-tooltip_bg_color` | `222222` | Background color for tooltips (BGR Hex). |
| `lls-tooltip_bg_opacity` | `60` | Background box transparency (00-FF). |
| `lls-tooltip_context_lines` | `3` | Surrounding lines captured for tooltip context. |
| `lls-tooltip_line_height_mul` | `0.87` | Vertical spacing multiplier for tooltips. |
| `lls-tooltip_y_offset_lines` | `0` | Manual vertical offset for tooltip positioning. |

#### **8. Search HUD Styling**
| Parameter | Default | Description |
|---|---|---|
| `lls-search_font_name` | `Consolas` | Font family for the Search overlay. |
| `lls-search_font_size` | `34` | Text size for the Search input field. |
| `lls-search_results_font_size` | `0` | Scaling for results list (0=100%, -1=80% of base size). |
| `lls-search_bg_color` | `000000` | Background color for search panels (BGR Hex). |
| `lls-search_bg_opacity` | `20` | Background box transparency (00-FF). |
| `lls-search_text_color` | `FFFFFF` | Primary text color in search HUD. |
| `lls-search_line_height_mul` | `1.2` | Line height for search results. |
| `lls-search_hit_color` | `0088FF` | Color for query matches in results (BGR Hex). |
| `lls-search_hit_bold` | `no` | Bold query matches in result list. |
| `lls-search_sel_color` | `FFFFFF` | Color for the currently selected result (BGR Hex). |
| `lls-search_sel_bold` | `no` | Bold selected result. |
| `lls-search_query_hit_color` | `0088FF` | Color for hits within the input query itself. |

#### **9. Anki & Mining Aesthetics**
| Parameter | Default | Description |
|---|---|---|
| `lls-anki_highlight_depth_1/2/3` | - | Colors for contiguous matches (Light -> Deep Orange). |
| `lls-anki_split_depth_1/2/3` | - | Colors for split-phrase matches (Light -> Deep Purple). |
| `lls-anki_mix_depth_1/2/3` | - | Colors for mixed/overlapping matches (Light -> Deep Blue). |
| `lls-anki_sync_period` | `5` | Interval (seconds) for automatic TSV database reloading. |
| `lls-anki_context_lines` | `6` | Surrounding lines captured in Anki flashcard context. |
| `lls-anki_context_max_words` | `40` | Maximum word count allowed per exported context sentence. |
| `lls-anki_highlight_bold` | `no` | Apply bold styling to database-matched highlights. |

#### **10. Detailed Key Mapping (Internal)**
These parameters allow remapping internal script actions in `mpv.conf`. Values can be space, comma, or semicolon separated lists.

| Parameter | Default Keys |
|---|---|
| `lls-dw_key_seek_prev` | `a ф` |
| `lls-dw_key_seek_next` | `d в` |
| `lls-dw_key_copy` | `Ctrl+c Ctrl+с` |
| `lls-dw_key_search` | `Ctrl+f Ctrl+а` |
| `lls-dw_key_add` | `g п MBTN_MID` |
| `lls-dw_key_pair` | `f а Ctrl+MBTN_LEFT` |
| `lls-dw_key_open_record` | `o щ` |
| `lls-dw_key_select` | `MBTN_LEFT` |
| `lls-dw_key_tooltip_pin` | `MBTN_RIGHT` |
| `lls-dw_key_tooltip_hover` | `n т` |
| `lls-dw_key_tooltip_toggle` | `e у` |
| `lls-dw_key_mouse_seek` | `MBTN_LEFT_DBL` |
| `lls-dw_key_scroll_up/down` | `Ctrl+UP/DOWN` |
| `lls-key_sub_pos_up/down` | `r/t к/е` |
| `lls-key_sec_sub_pos_up/down`| `R/T К/Е` |

#### **Mapping Keywords**
When configuring `anki_mapping.ini`, use these keywords to pull dynamic data:
- `source_word`: The selected term or phrase.
- `source_sentence`: The full sentence context captured around the selection.
- `source_index`: The sequential index of the line in the subtitle file.
- `time`: The exact timestamp (HH:MM:SS,ms) of the selection.
- `source_url`: The discovered URL (YouTube, etc.) for the media.
- `deck_name`: The filename-derived deck category.

---

### PotPlayer-style UI Optimization

To achieve the "Premium Dark" aesthetic seen in project demonstrations, ensure these standard `mpv` properties are set in your `mpv.conf`:

| Property | Value | Description |
|---|---|---|
| `sub-border-style` | `background-box` | Places a semi-transparent black box behind subtitles. |
| `sub-back-color` | `"#C0000000"` | 75% opaque black background for readability. |
| `osd-border-style` | `background-box` | Applies the same box aesthetic to all OSD notifications. |
| `osc` | `no` | Hides the default controller for a distraction-free view. |
| `osd-bar` | `no` | Disables the low-resolution seek bar during navigation. |
| `geometry` | `50%:50%` | Centers the player window on the screen at startup. |
| `autofit` | `1920x1080` | Forces a consistent high-resolution starting window size. |

---

### Switchable Layout Modes:

The configuration supports a **Mode-based architecture**. You can define and switch between different font size calibrations (e.g., MODE 1 for size 30, MODE 2 for size 34) directly in `mpv.conf` to ensure hit-testing remains pixel-perfect regardless of your chosen font scale.

(Refer to the heavily commented `mpv.conf` file in the repository for a complete list of all 150+ adjustable parameters and functional templates.)

[Return to Top](#table-of-contents)

## Installation

1.  **Locate Config**: Open `%APPDATA%\mpv\` (Windows).
2.  **Deploy**: Copy `mpv.conf`, `input.conf`, and the `scripts/` folder into the directory.
3.  **Self-Documenting Hotkeys**: `input.conf` is fully commented with detailed explanations for every key. Refer to it as your primary manual.
4.  **Scripts**: The core logic is powered by the unified `lls_core.lua` script. Ensure it's saved with **UTF-8** encoding.
5.  **Restart**: Relaunch mpv to apply the optimized v1.58.30 settings.

[Return to Top](#table-of-contents)

## Development Analytics

This project maintains a data-driven approach to development tracking. We use a custom clustering algorithm to estimate human effort from git commitment intervals.

- **Project Inception**: March 8, 2026
- **Current Maturity**: ~1541 Commits (v1.58.30)
- **Intensity Profile**: 5.4 Commits/Hour 

To repeat the analysis on your local machine, use the provided Python tool:
```powershell
git log --pretty=format:"%ad" --date=iso-strict | python docs/scripts/analyze_repo.py
```

[Return to Top](#table-of-contents)

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

[Return to Top](#table-of-contents)
