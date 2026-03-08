# mpv Language Learning Suite - Optimized Subtitle Workflow

[![Version](https://img.shields.io/badge/version-v0.39.0-blue)](https://github.com/voothi/20260308110646-mpv-config/releases) 
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) 

A high-performance [mpv](https://mpv.io/) configuration specifically engineered for immersion-based language learning. This suite resolves common friction points in subtitle management, navigation, and focus.

> **Attribution & Source**
>
> Developed and maintained by **Denis Novikov (voothi)** as part of the Kardenwort ecosystem.
>
> *   **Repository**: [Source Code](https://github.com/voothi/20260308110646-mpv-config)

> [!IMPORTANT]
> **Optimized Study Environment**
>
> **Validated Setup:**
> *   **Platform**: Windows 11 (Supports Android via configuration port).
> *   **Workflow**: Optimized for merged `.ass` subtitle files and karaoke-style immersion.
> *   **Interface**: distraction-free OSC (hidden by default).


## Table of Contents

- [Core Philosophy](#core-philosophy)
- [Advanced Subtitle Workflow](#advanced-subtitle-workflow)
- [Intelligent Scripts](#intelligent-scripts)
  - [Karaoke-Safe Autopause](#karaoke-safe-autopause)
  - [Fixed Font Scaling](#fixed-font-scaling)
- [Study-Centric Keybindings](#study-centric-keybindings)
- [Configuration Guide (mpv.conf)](#configuration-guide-mpvconf)
- [Installation](#installation)
- [License](#license)

---

## Core Philosophy

Traditional video players treat subtitles as a side-effect. This suite treats them as the **primary data source** for learning. Every setting—from pixel-perfect scaling to phrase-based pausing—is designed to help you focus on the language, not the player.

## Advanced Subtitle Workflow

Instead of relying on mpv's native dual-subtitle loading (which often strips formatting), this configuration advocates for a **Merged .ass Workflow**:

1.  **Multiple Tracks**: Use [Subtitle Edit](https://github.com/SubtitleEdit) to merge target and native language tracks.
2.  **Custom Positioning**: Bake positioning (Top/Center/Bottom) and colors directly into a single `.ass` file.
3.  **Visual Protection**: Our `mpv.conf` respects the internal mathematics of the `.ass` file, ensuring margins and styles are never overridden by the player.

[Return to Top](#table-of-contents)

## Intelligent Scripts

### Karaoke-Safe Autopause
Standard autopause scripts break on "Karaoke" subtitles (per-word highlighting), causing stuttering at every word. 

*   **Logic**: Our `autopause.lua` (implemented as **Karaoke-Safe Autopause**) scans for the `{\c}` color tag. It only triggers a pause when the tag is *absent*, signifying the **final frame of a complete phrase**.

*   **Buffer**: Includes a `0.15s` padding to ensure a smooth transition before the text disappears.
*   **Toggle**: Use `Shift + P` to enable/disable during playback.

### Smart Font Scaling (fixed_font.lua)
Ensures that your study material remains perfectly readable regardless of window size, while protecting complex layouts.
*   **For `.srt` Files**: Dynamically adjusts subtitle scaling so text doesn't become tiny on large monitors or giant in small windows.
*   **For `.ass` Files**: Intelligently detects the Advanced SubStation format and bypasses scaling, allowing the file's internal positioning mathematics to render flawlessly.

[Return to Top](#table-of-contents)

## Study-Centric Keybindings

Optimized `input.conf` for rapid review, featuring **dual-layout support** (English/Cyrillic) to ensure your workflow is never interrupted by your keyboard language.

| Key (EN) | Key (RU) | Action |
|---|---|---|
| `RIGHT` | `RIGHT` | Exact **2-second** seek forward |
| `LEFT` | `LEFT` | Exact **2-second** seek backward |
| `Ctrl + C` | `Ctrl + С` | **Copy** current subtitle text to clipboard |
| `A` / `D` | `Ф` / `В` | Jump to **Previous / Next** phrase |
| `S` | `Ы` | Toggle Subtitle Visibility |
| `TAB` | `TAB` | Hold to show OSC (hidden by default) |
| `P` | `З` | Toggle **Karaoke-Safe Autopause** |
| `L` | `Л` | Toggle **Karaoke Mode** |

[Return to Top](#table-of-contents)

## Configuration Guide (mpv.conf)

Key settings to protect your learning environment:

- **`sub-ass=yes`**: Enables high-quality subtitle rendering.
- **`osc=no`**: Removes visual clutter from the screen.
- **`sub-scale-with-window=no`**: Critical for maintaining the layout of complex `.ass` files.
- **`save-position-on-quit=yes`**: Pick up your study session exactly where you left off.

[Return to Top](#table-of-contents)

## Installation

1.  **Locate Config**: Open `%APPDATA%\mpv\` (Windows).
2.  **Deploy**: Copy `mpv.conf`, `input.conf`, and the `scripts/` folder into the directory.
3.  **Scripts**: Ensure `autopause.lua` is saved with **UTF-8** encoding.
4.  **Restart**: Relaunch mpv to apply the study-optimized settings.

[Return to Top](#table-of-contents)

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
