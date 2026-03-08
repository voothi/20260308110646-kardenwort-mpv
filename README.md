# Kardenwort Mpv Configuration - Language Learning Suite

[![Version](https://img.shields.io/badge/version-v1.0.0-blue)](https://github.com/voothi/20260308110646-kardenwort-mpv-conf/releases/tag/v1.0.0) 
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) 

A high-performance [mpv](https://mpv.io/) configuration specifically engineered for immersion-based language learning. This suite resolves common friction points in subtitle management, navigation, and focus.

> **Attribution & Source**
>
> Developed and maintained by **Denis Novikov (voothi)** as part of the Kardenwort ecosystem.
>
> *   **Repository**: [Source Code](https://github.com/voothi/20260308110646-kardenwort-mpv-conf)

> [!IMPORTANT]
> **Optimized Study Environment**
>
> **Validated Setup:**
> *   **Platform**: Windows 11 (Supports Android via configuration port).
> *   **Workflow**: Optimized for both merged `.ass` and separate `.srt` files.
> *   **Interface**: Distraction-free OSC (hidden by default).


## Table of Contents

- [Core Philosophy](#core-philosophy)
- [Distinctive Advantages](#distinctive-advantages)
- [Advanced Subtitle Workflow](#advanced-subtitle-workflow)
- [Intelligent Scripts](#intelligent-scripts)
  - [Karaoke-Safe Autopause](#karaoke-safe-autopause)
  - [Drum Context Mode](#drum-context-mode)
  - [Smart Spacebar](#smart-spacebar)
  - [Smart Font Scaling](#smart-font-scaling-fixed_fontlua)
- [Study-Centric Keybindings](#study-centric-keybindings)
- [Configuration Guide (mpv.conf)](#configuration-guide-mpvconf)
- [Installation](#installation)
- [License](#license)

---

## Core Philosophy

Traditional video players treat subtitles as a side-effect. This suite treats them as the **primary data source** for learning. Every setting—from pixel-perfect scaling to phrase-based pausing—is designed to help you focus on the language, not the player.

[Return to Top](#table-of-contents)

## Distinctive Advantages

This suite solves problems that standard video players and generic scripts ignore:
1.  **Dual-Layout Keybindings**: Native support for both English and Cyrillic keyboard layouts. Your hotkeys work flawlessly without needing to constantly switch your system input language.
2.  **Karaoke-Ready Autopause**: Unlike standard autopause scripts that stutter on `.ass` word-by-word highlights, this suite precisely scans for formatting tags to stop *only* when a phrase is complete.
3.  **Non-Intrusive OSD Design**: All status popups (Play/Pause, Layout, Visilibity) are minimized and pushed to the **Left-Center** of the screen. Your visual field remains 100% clear.
4.  **Ass Mathematics Protection**: The suite dynamically sizes simple text, but completely respects the baked-in layout geometry of complex immersive video files.
5.  **Watch-Later Cleanliness**: Temporary visibility toggles for intense study sessions are explicitly excluded from `watch-later` saving, ensuring you never corrupt your clean baseline configuration.

[Return to Top](#table-of-contents)

## Advanced Subtitle Workflow

Instead of relying on mpv's native dual-subtitle loading (which often strips formatting), this configuration advocates for a **Merged .ass Workflow**:

1.  **Multiple Tracks**: Use [Subtitle Edit](https://github.com/SubtitleEdit) to merge target and native language tracks.
2.  **Custom Positioning**: Bake positioning (Top/Center/Bottom) and colors directly into a single `.ass` file.
3.  **Visual Protection**: Our `mpv.conf` respects the internal mathematics of the `.ass` file, ensuring margins and styles are never overridden by the player.

[Return to Top](#table-of-contents)

## Intelligent Scripts

### Karaoke-Safe Autopause (`autopause.lua`)
Advanced pause logic designed specifically for immersion students using `.ass` karaoke-formatted subtitles.
- **End of Phrase**: By default, it pauses only when the sentence is finished (detecting the end of the `{\c}` tag sequence).
- **Word by Word**: Toggle with `K` to pause after every word highlighted in your karaoke tracks.
- **Dual-Track Aware**: Intelligently tracks timings in both primary and secondary tracks to ensure you never miss a phrase.
- **Toggle**: `P` (English) or `З` (Russian).

### Drum Context Mode (`sub_context.lua`)
Displays previous and future subtitles around the active line, providing crucial context for fragmented sentences.
- **Rolling Context**: Shows historical and upcoming dialogue lines simultaneously.
- **Styled OSD**: Status messages appear in the **Left-Center** (`{\an4}`) using a small, non-intrusive 20pt font.
- **ASS Protection**: Automatically blocks itself on complex `.ass` tracks to prevent rendering visual artifacts or breaking karaoke animations.
- **Toggle**: `C` (English) or `С` (Russian).

### Smart Spacebar (Hold-to-Play)
A custom key handler that distinguishes between quick taps and long holds.
- **Play While Held**: Pressing and holding `SPACE` bypasses ALL autopause rule sets (Word-by-word and End-of-phrase). The video plays smoothly as long as the key is down.
- **Tap to Toggle**: Quickly tapping `SPACE` (< 200ms) functions as a standard Play/Pause toggle.

### Smart Font Scaling (`fixed_font.lua`)
Ensures that your study material remains perfectly readable regardless of window size, while protecting complex layouts.
*   **For `.srt` Files**: Dynamically adjusts subtitle scaling so text doesn't become tiny on large monitors or giant in small windows.
*   **For `.ass` Files**: Intelligently detects the Advanced SubStation format and bypasses scaling, allowing the file's internal positioning mathematics to render flawlessly.

[Return to Top](#table-of-contents)

## Study-Centric Keybindings

Optimized `input.conf` for rapid review, featuring **dual-layout support** (English/Cyrillic).

| Key (EN) | Key (RU) | Action |
|---|---|---|
| `RIGHT` | `RIGHT` | Exact **2-second** seek forward |
| `LEFT` | `LEFT` | Exact **2-second** seek backward |
| `SPACE` | `SPACE` | **Smart Space**: Hold to Play, Tap to Toggle Pause |
| `A` / `D` | `Ф` / `В` | Jump to **Previous / Next** phrase |
| `S` | `Ы` | Toggle Subtitle Visibility (Styled OSD) |
| `J` | `О` | Cycle Secondary Subtitle Track |
| `Y` | `Н` | Toggle Secondary Position (**Top ↔ Bottom**) |
| `C` | `С` | Toggle **Drum Mode** (Multi-line Context) |
| `TAB` | `TAB` | Cycle OSC Visibility (**Always ↔ Auto ↔ Never**) |
| `P` | `З` | Toggle **Autopause** (ON/OFF) |
| `K` | `Л` | Toggle **Karaoke Mode** (Word-by-Word / End-of-Phrase) |

[Return to Top](#table-of-contents)

---

## Configuration Guide (mpv.conf)

Key settings to protect your learning environment:

- **`sub-align-y=bottom`**: Standardizes the layout for drum mode.
- **`secondary-sub-pos=10`**: Places the secondary tracks at the top of the frame.
- **`sub-pos=95`**: Places the primary tracks safely near the bottom.
- **`sub-ass=yes`**: Enables high-quality subtitle rendering for native karaoke support.
- **`osc=no`**: Removes visual clutter from the screen.
- **`sub-scale-with-window=no`**: Critical for maintaining the layout of complex `.ass` files.
- **`save-position-on-quit=yes`**: Pick up your study session exactly where you left off.

[Return to Top](#table-of-contents)

## Installation

1.  **Locate Config**: Open `%APPDATA%\mpv\` (Windows).
2.  **Deploy**: Copy `mpv.conf`, `input.conf`, and the `scripts/` folder into the directory.
3.  **Scripts**: Ensure all scripts are saved with **UTF-8** encoding.
4.  **Restart**: Relaunch mpv to apply the optimized v1.0.0 settings.

[Return to Top](#table-of-contents)

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

[Return to Top](#table-of-contents)
