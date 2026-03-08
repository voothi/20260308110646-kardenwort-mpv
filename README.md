# Modern mpv Configuration - Optimized Playback Suite

[![Version](https://img.shields.io/badge/version-v0.39.0-blue)](https://github.com/voothi/mpv-config/releases) 
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) 

This is a curated and optimized configuration for [mpv](https://mpv.io/), a free, open-source, and cross-platform media player. This suite enhances the playback experience with refined subtitle handling, UI tweaks, and automated scripts.

> **Attribution & Source**
>
> This configuration is maintained by **Denis Novikov (voothi)**.
>
> *   **Repository**: [Source Code](https://github.com/voothi/20260308110646-mpv-config)

> [!NOTE]
> **Windows Optimized Environment**
>
> **Developed & Validated Environment:**
> *   **OS**: Windows 11
> *   **mpv**: Version 0.39.0-x86_64
> *   **Components**: Lua scripts, custom keybindings, and optimized rendering settings.


## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Scripts & Automation](#scripts--automation)
- [Key Configuration Files](#key-configuration-files)
- [Usage](#usage)
- [License](#license)

---

## Features

* **Advanced Subtitle Rendering**:
    *   Subtitles aligned to the **top** for better visibility during certain types of content.
    *   Full support for **ASS/SSA** tags and complex styles.
    *   Independent scaling: Subtitles do not bloat or shrink with window resizing, maintaining consistency.
* **Streamlined UI**:
    *   **Minimalist Interface**: OSC (On-Screen Controller) is hidden by default and configured to remain invisible even on hover for a truly distraction-free experience.
    *   **Smart Geometry**: Automatically fits the window to **1920x1080** while respecting screen boundaries.
* **Persistent Playback**: Automatically saves the last playback position, allowing you to resume exactly where you left off.
* **Integrated Scripts**: Includes custom Lua scripts for enhanced functionality like auto-pausing and font management.

[Return to Top](#table-of-contents)

## Prerequisites

* **mpv Media Player**: Ensure you have mpv installed. You can download it from the [official website](https://mpv.io/installation/).
* **Windows OS**: While mpv is cross-platform, this specific configuration is validated on Windows.

[Return to Top](#table-of-contents)

## Installation

### Manual Installation

1.  Navigate to your mpv configuration directory.
    *   **Windows**: `%APPDATA%\mpv\`
2.  Clone or copy the contents of this repository into that directory.
3.  Ensure the following structure is maintained:
    ```text
    mpv/
    ├── scripts/
    │   ├── autopause.lua
    │   └── fixed_font.lua
    ├── fonts.conf
    ├── input.conf
    └── mpv.conf
    ```
4.  Restart mpv.

[Return to Top](#table-of-contents)

## Scripts & Automation

This configuration includes powerful Lua scripts to automate your workflow:

* **autopause.lua**: Intelligently manages playback state (e.g., pausing when the window is minimized or loses focus).
* **fixed_font.lua**: Ensures consistent font rendering across different media types and subtitle files.

[Return to Top](#table-of-contents)

## Key Configuration Files

- **mpv.conf**: The primary configuration file containing rendering, subtitle, and UI settings.
- **input.conf**: Custom keybindings for refined control.
- **fonts.conf**: Font configuration for proper subtitle and OSD display.

[Return to Top](#table-of-contents)

## Usage

1.  **Launch mpv**: Open any video file with mpv.
2.  **Subtitles**: Observe the top-aligned subtitles and consistent scaling.
3.  **UI**: Move your mouse; the OSC will remain hidden as per the `osc-visibility=never` policy.
4.  **Resume**: Close the player and reopen the same file to confirm the position is saved.

[Return to Top](#table-of-contents)

## License

This project is licensed under the **MIT License**.

See the [LICENSE](LICENSE) file for details.
