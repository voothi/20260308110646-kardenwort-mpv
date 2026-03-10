# Kardenwort MPV - Language Acquisition Suite

[![Version](https://img.shields.io/badge/version-v1.2.16-blue)](https://github.com/voothi/20260308110646-kardenwort-mpv/releases/tag/v1.2.16) 
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
3.  **YouTube Auto-Subtitle Handling**: Provides specialized tools like [Drum Context Mode](#drum-context-mode) to maintain linguistic context when dealing with poorly synchronized or lower-quality YouTube-extracted captions.
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
3.  **Non-Intrusive OSD Design**: All status popups (Play/Pause, Layout, Visilibity) are minimized and pushed to the **Left-Center** of the screen. Your visual field remains 100% clear.
4.  **Ass Mathematics Protection**: The suite dynamically sizes simple text, but completely respects the baked-in layout geometry of complex immersive video files.
5.  **Watch-Later Cleanliness**: Temporary visibility toggles for intense immersion sessions are explicitly excluded from `watch-later` saving, ensuring you never corrupt your clean baseline configuration.
6.  <span id="positional-flexibility">**Positional Flexibility**</span>: Fine-grained vertical adjustment for both primary and secondary tracks (and their Russian layout equivalents). Manually resolve overlaps and tune your visual field without touching a configuration file.

[Return to Top](#table-of-contents)

## Advanced Subtitle Workflow

Instead of relying on mpv's native dual-subtitle loading (which often strips formatting), this configuration advocates for a **Merged .ass Workflow**:

1.  **Multiple Tracks**: Use [Subtitle Edit](https://github.com/SubtitleEdit/subtitleedit) to merge target and native language tracks.
2.  **Custom Positioning**: Bake positioning (Top/Center/Bottom) and colors directly into a single `.ass` file.
3.  **Visual Protection**: Our `mpv.conf` respects the internal mathematics of the `.ass` file, ensuring margins and styles are never overridden by the player.

[Return to Top](#table-of-contents)

## Intelligent Scripts

### Karaoke-Safe Autopause
Advanced pause logic designed specifically for immersion students using `.ass` karaoke-formatted subtitles.
- **End of Phrase**: By default, it pauses only when the sentence is finished (detecting the end of the `{\c}` tag sequence).
- **Word by Word**: Toggle with `K` to pause after every word highlighted in your karaoke tracks.
- **Dual-Track Aware**: Intelligently tracks timings in both primary and secondary tracks to ensure you never miss a phrase.
- **Toggle**: `P` (English) or `З` (Russian).

### <span id="static-reading-mode"></span>Static Reading Mode (Drum Window)
A high-performance rolling context engine that has evolved into a robust **Static Reading Mode** for in-depth immersion analysis.
- **Static Viewport**: Once you begin navigating via arrows, the viewport "freezes" synchronously, providing a stable, flicker-free environment for reading and selection.
- **Edge-Aware Scrolling**: The window only scrolls when the cursor hits the top or bottom edges, similar to a modern text editor.
- **Follow Mode**: Automatically centers on the active playback line when the window is opened or when seeking with `a`/`d`.
- **Styled OSD**: Status messages and text are rendered in a clean, non-intrusive **Left-Center** style (`{\an4}`).
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
| `RIGHT` | `RIGHT` | Exact **2-second** seek forward |
| `LEFT` | `LEFT` | Exact **2-second** seek backward |
| `Q` | `Й` | **Quit** (and save position) |
| `SPACE` | `SPACE` | **Smart Space**: Hold to Play, Tap to Toggle Pause |
| `r` / `t` | `к` / `е` | Adjust **Primary** Position (Up / Down) |
| `Shift+R` / `Shift+T` | `К` / `Е` | Adjust **Secondary** Position (Up / Down) |
| `S` | `Ы` | Toggle Subtitle Visibility (Styled OSD) |
| `J` | `О` | Cycle Secondary Subtitle Track |
| `Y` | `Н` | Toggle Secondary Position (**Top ↔ Bottom**, SRT only) |
| `C` | `С` | Toggle **Drum Mode** (Legacy Multi-line Context) |
| `W` | `Ц` | Toggle **Static Reading Mode** (Drum Window) |
| `Shift + UP/DN` | `Shift + В/Н` | Multi-line Range Selection |
| `Ctrl+C` | `Ctrl+С` | **Copy Range** (Exact highlighted words to clipboard) |
| `X` | `Ч` | Toggle **Context Copy** (Include surrounding lines) |
| `Z` | `Я` | Cycle **Copy Mode** (Foreign ↔ Translation) |
| `TAB` | `TAB` | Cycle OSC Visibility (**Always ↔ Auto ↔ Never**) |
| `P` | `З` | Toggle **Autopause** (ON/OFF) |
| `K` | `Л` | Toggle **Karaoke Mode** (Word-by-Word / End-of-Phrase) |

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
5.  **Restart**: Relaunch mpv to apply the optimized v1.2.10 settings.

[Return to Top](#table-of-contents)

## Development Analytics

This project maintains a data-driven approach to development tracking. We use a custom clustering algorithm to estimate human effort from git commitment intervals.

- **Project Inception**: March 8, 2026
- **Current Maturity**: ~200 Commits (v1.2.16)
- **Intensity Profile**: 7.2 Commits/Hour 

To repeat the analysis on your local machine, use the provided Python tool:
```powershell
git log --pretty=format:"%ad" --date=iso-strict | python docs/scripts/analyze_repo.py
```

[Return to Top](#table-of-contents)

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

[Return to Top](#table-of-contents)
