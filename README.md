# Kardenwort MPV - Language Acquisition Suite

[![Version](https://img.shields.io/badge/version-v1.26.2-blue)](https://github.com/voothi/20260308110646-kardenwort-mpv/releases/tag/v1.26.2) 
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
> *   **Platform**: Windows 11 (Supports Android via configuration port).
> *   **Workflow**: Optimized for both merged `.ass` and separate `.srt` files.
> *   **Interface**: Distraction-free OSC (hidden by default).


## Table of Contents

- [Project Goals](#project-goals)
- [Distinctive Advantages](#distinctive-advantages)
- [Advanced Subtitle Workflow](#advanced-subtitle-workflow)
- [Intelligent Scripts](#intelligent-scripts)
  - [Universal Subtitle Search](#universal-subtitle-search)
  - [Karaoke-Safe Autopause](#karaoke-safe-autopause)
  - [Static Reading Mode](#static-reading-mode)
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
7.  <span id="positional-flexibility">**Positional Flexibility**</span>: Fine-grained vertical adjustment for both primary and secondary tracks (and their Russian layout equivalents). Manually resolve overlaps and tune your visual field without touching a configuration file.
8.  **Universal Fuzzy Search**: Instantly look up vocabulary and phrases across the entire subtitle file with an independent, non-intrusive overlay. Supports clipboard pasting and direct mouse selection.
9.  **Hardware-Accelerated Mouse Selection**: Click-and-drag text selection inside the Drum Window tracks your cursor at 60fps using native `mouse_move` hardware events rather than a polling timer.

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
- **Cyrillic Parity**: Fully case-insensitive Russian search support.
- **Professional Editing**: Support for `Ctrl+A` (Select All) and Bash-style `Ctrl+W` (Delete Word).
- **Clipboard Integration**: Paste queries directly with `Ctrl+V` (EN) or `Ctrl+М` (RU).
- **Hit Highlighting**: Elegant visual feedback highlighting exact matching letters (Subsequence-aware).
- **Interactive Dropdown**: Navigate results via arrow keys or click directly on an item with the mouse to seek.
- **Hard-Sync Logic**: Every jump uses explicit `seek absolute+exact` commands to ensure primary and secondary tracks are perfectly aligned.
- **Toggle**: `Ctrl + F` (English) or `Ctrl + А` (Russian).

#### **How the Search Engine Works**
The search bar uses a multi-stage **Keyword-Based Fuzzy Matching** engine:
1.  **Tokenization**: Your query is split into individual keywords (separated by spaces).
2.  **Order-Independent Matching**: The engine finds results containing all keywords, regardless of the sequence you typed them in.
3.  **"Really Fuzzy" Subsequence**: Each keyword matches if its letters appear in the correct order within a word, even if other letters are in between (e.g., `mne` matches **m**a**n**ag**e**).
4.  **Relevance Ranking**:
    -   **Exact Match**: Literal matches are prioritized first.
    -   **Compactness Bonus**: Higher priority is given to "dense" matches where letters are clustered within a single word rather than scattered across the whole line.
    -   **Structural Bonus**: Matches at the start of a subtitle line receive a specific weight.

### Karaoke-Safe Autopause
Advanced pause logic designed specifically for immersion students using `.ass` karaoke-formatted subtitles.
- **End of Phrase**: By default, it pauses only when the sentence is finished (detecting the end of the `{\c}` tag sequence).
- **Word by Word**: Toggle with `K` to pause after every word highlighted in your karaoke tracks.
- **Dual-Track Aware**: Intelligently tracks timings in both primary and secondary tracks to ensure you never miss a phrase.
- **Toggle**: `P` (English) or `З` (Russian).

### <span id="static-reading-mode"></span>Static Reading Mode (Drum Window)
A high-performance rolling context engine that has evolved into a robust **Static Reading Mode** for in-depth immersion analysis.
- **Advanced Mouse Selection**: Experience text-editor smooth interactions. Click and drag (`LMB`) to instantly highlight ranges, or `Shift+Click` to extend. Hardware-accelerated for 60fps tracking.
- **Actionable Text**: Double-Click any subtitle word to instantly seek video playback to that exact phrase and re-center the viewport.
- **Static Viewport**: Once you begin navigating via arrows, the viewport "freezes" synchronously, providing a stable, flicker-free environment for reading and selection.
- **Edge-Aware Scrolling**: The window only scrolls when the cursor hits the top or bottom edges, or via standard `Mouse Wheel`/`Ctrl+Arrows`.
- **Conflict Free**: Opening the window auto-hides overlapping subtitle tracks and native OS window-drag behaviors to guarantee distraction-free reading.
- **Active Line Visibility**: The current playback line is highlighted in a **high-contrast bright blue**, ensuring it remains perfectly legible against the window's parchment background.
- **Toggle**: `W` (English) or `Ц` (Russian).

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
*   **For `.srt` Files**: Dynamically adjusts subtitle scaling so text doesn't become tiny on large monitors or giant in small windows.
*   **For `.ass` Files**: Intelligently detects the Advanced SubStation format and bypasses scaling, allowing the file's internal positioning mathematics to render flawlessly.

[Return to Top](#table-of-contents)

## Immersion-Centric Keybindings

Optimized `input.conf` for rapid review, featuring **dual-layout support** (English/Cyrillic).

| Key (EN) | Key (RU) | Action |
|---|---|---|
| `RIGHT` / `LEFT` | `RIGHT` / `LEFT` | Exact **2-second** seek forward / backward |
| `A` / `D` | `Ф` / `В` | Exact **2-second** seek forward / backward (Window Mode / Global) |
| `a` / `d` | `ф` / `в` | **Seek** to previous / next subtitle line |
| `q` / `Q` | `й` / `Й` | **Quit** / Quit and save position |
| `SPACE` | `SPACE` | **Smart Space**: Hold to Play, Tap to Toggle Pause |
| `m` | `ь` | Toggle **Mute** |
| `[` / `]` | `х` / `ъ` | Decrease / Increase **Playback Speed** (10%) |
| `{` / `}` | `Х` / `Ъ` | Halve / Double **Playback Speed** |
| `.` / `,` | `ю` / `б` | Frame Step Forward / Backward |
| `r` / `t` | `к` / `е` | Adjust **Primary** Position (Up / Down) |
| `Shift+R` / `Shift+T` | `К` / `Е` | Adjust **Secondary** Position (Up / Down) |
| `s` | `ы` | Toggle Subtitle Visibility (Styled OSD) |
| `j` | `о` | Cycle Secondary Subtitle Track |
| `y` | `н` | Toggle Secondary Position (**Top ↔ Bottom**, SRT only) |
| `c` | `с` | Toggle **Drum Mode** (Legacy Multi-line Context) |
| `w` | `ц` | Toggle **Static Reading Mode** (Drum Window) |
| `Ctrl+f` | `Ctrl+а` | Toggle **Universal Subtitle Search** Overlay |
| `Ctrl+a` | `Ctrl+ф` | **Select All** (Inside Search HUD) |
| `Ctrl+w` | `Ctrl+ц` | **Delete Word** (Bash-style, Search HUD) |
| `LMB (Drag)` | `LMB (Drag)` | **Select Text** (Click and drag to highlight) |
| `LMB (Double)` | `LMB (Double)` | **Seek** to clicked subtitle line |
| `Shift + UP/DN` | `Shift + В/Н` | Multi-line Range Selection (Arrows) |
| `Ctrl + Shift + LEFT/RIGHT` | `Ctrl+Shift+Л/П` | Block-word Selection (Navigation) |
| `Ctrl + Shift + UP/DOWN` | `Ctrl+Shift+В/Н` | Multi-line Jump Selection |
| `Ctrl + UP/DN` | `Ctrl + В/Н` | Viewport Scroll (Matches Mouse Wheel) |
| `Ctrl+c` | `Ctrl+с` | **Copy Range** (Exact highlighted words to clipboard) |
| `x` | `ч` | Toggle **Context Copy** (Include surrounding lines) |
| `z` | `я` | Cycle **Copy Mode** (Foreign ↔ Translation) |
| `TAB` | `TAB` | Cycle OSC Visibility (**Always ↔ Auto ↔ Never**) |
| `p` | `з` | Toggle **Autopause** (ON/OFF) |
| `k` | `л` | Toggle **Karaoke Mode** (Word-by-Word / End-of-Phrase) |
| `S` | `Ы` | Take a **Screenshot** |

[Return to Top](#table-of-contents)

---

## Configuration Guide (mpv.conf)

Key settings to protect your acquisition environment:

- **`sub-align-y=bottom`**: Standardizes the layout for drum mode.
- **`secondary-sub-pos=10`**: Places the secondary tracks at the top of the frame.
- **`sub-pos=95`**: Places the primary tracks safely near the bottom.
- **`sub-ass=yes`**: Enables high-quality subtitle rendering for native karaoke support.
- **`osc=no`**: Removes visual clutter from the screen.
- **`sub-scale-with-window=no`**: Critical for maintaining the layout of complex `.ass` files.
- **`save-position-on-quit=yes`**: Pick up your immersion session exactly where you left off.
- **`script-opts-append=lls-sec_pos_bottom=90`**: Configures the script's toggle position directly from `mpv.conf`.

[Return to Top](#table-of-contents)

## Installation

1.  **Locate Config**: Open `%APPDATA%\mpv\` (Windows).
2.  **Deploy**: Copy `mpv.conf`, `input.conf`, and the `scripts/` folder into the directory.
3.  **Self-Documenting Hotkeys**: `input.conf` is fully commented with detailed explanations for every key. Refer to it as your primary manual.
4.  **Scripts**: The core logic is powered by the unified `lls_core.lua` script. Ensure it's saved with **UTF-8** encoding.
5.  **Restart**: Relaunch mpv to apply the optimized v1.25.2 settings.

[Return to Top](#table-of-contents)

## Development Analytics

This project maintains a data-driven approach to development tracking. We use a custom clustering algorithm to estimate human effort from git commitment intervals.

- **Project Inception**: March 8, 2026
- **Current Maturity**: ~325 Commits (v1.26.2)
- **Intensity Profile**: 9.6 Commits/Hour 

To repeat the analysis on your local machine, use the provided Python tool:
```powershell
git log --pretty=format:"%ad" --date=iso-strict | python docs/scripts/analyze_repo.py
```

[Return to Top](#table-of-contents)

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

[Return to Top](#table-of-contents)
