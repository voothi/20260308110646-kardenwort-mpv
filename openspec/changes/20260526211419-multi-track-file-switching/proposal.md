## Why

During language acquisition, users often deal with multi-lingual material where different language tracks (audio/video/subtitles) are stored in separate companion files in the same directory rather than multiplexed within a single container (e.g., `20260525163647-executive-briefing-your-ai.mp4` along with `20260525163647-executive-briefing-your-ai.ru.mp4` and `20260525163647-executive-briefing-your-ai.de.mp4`). 

Currently, MPV track switching only operates on multiplexed tracks within the active container, leaving users with no seamless way to switch languages across physical companion files without losing playback position, speed, and overall immersion. 

## What Changes

- **Companion Discovery**: Automatically scans the active media directory to identify and index companion media files sharing the same prefix but possessing language postfixes (e.g., `<name>.<lang>.<ext>`).
- **Unified Switcher Logic**: Consolidates both companion file track switching and standard internal track cycling under a single keyboard shortcut (`Shift+3`, `SHARP`, or `№`). If multiple companion files are found, `Shift+3` cycles through files. If no companion files exist, it falls back seamlessly to cycling multiplexed tracks inside the container.
- **Seamless State-Preserving Swapping**: Dynamically swaps the active video file using a dedicated script-binding. Swapping perfectly preserves:
  - Playback position (`time-pos`)
  - Playback speed (`speed`)
  - Playback state (playing vs. paused)
- **Themed HUD Confirmation**: Reports track swaps instantly with a premium, semi-transparent Kardenwort OSD card matching the suite's theme.
- **Layout-Agnostic Keybindings**: Registers hotkeys in both English and Russian keyboards for unified track cycling.

## Capabilities

## Impact

- **`scripts/kardenwort/main.lua`**: Implements directory scanning, base/postfix matching, time/speed preservation, file loading, and themed OSD notification logic under the unified `cmd_cycle_audio` action.
- **`input.conf`**: Cleans up secondary key bindings to keep all track switching actions unified on `Shift+3`.
- **`mpv.conf`**: Exposes config options to toggle companion loading behaviors.
- **`README.md`**: Documents the new capabilities, shortcuts, and directory structure expectations.
