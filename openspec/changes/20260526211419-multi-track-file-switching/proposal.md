## Why

During language acquisition, users often deal with multi-lingual material where different language tracks (audio/video/subtitles) are stored in separate companion files in the same directory rather than multiplexed within a single container (e.g., `20260525163647-executive-briefing-your-ai.mp4` along with `20260525163647-executive-briefing-your-ai.ru.mp4` and `20260525163647-executive-briefing-your-ai.de.mp4`). 

Currently, MPV track switching only operates on multiplexed tracks within the active container, leaving users with no seamless way to switch languages across physical companion files without losing playback position, speed, and overall immersion. 

## What Changes

- **Companion Discovery**: Automatically scans the active media directory to identify and index companion media files sharing the same prefix but possessing language postfixes (e.g., `<name>.<lang>.<ext>`).
- **Seamless State-Preserving Swapping**: Dynamically swaps the active video file using a dedicated script-binding. Swapping perfectly preserves:
  - Playback position (`time-pos`)
  - Playback speed (`speed`)
  - Playback state (playing vs. paused)
- **Automatic Subtitle Re-anchoring**: Automatically re-aligns and loads corresponding subtitle sidecar files (e.g., `.srt`) matching the newly active companion language to maintain the dual-subtitle display.
- **Themed HUD Confirmation**: Reports track swaps instantly with a premium, semi-transparent Kardenwort OSD card matching the suite's theme.
- **Layout-Agnostic Keybindings**: Registers hotkeys in both English and Russian keyboards for file cycling.

## Capabilities

### New Capabilities
- `multi-track-file-switching`: Dynamic indexing of companion multi-track media files in the same directory and state-preserving runtime swapping.

### Modified Capabilities
<!-- None -->

## Impact

- **`scripts/kardenwort/main.lua`**: Implements directory scanning, base/postfix matching, time/speed preservation, file loading, and themed OSD notification logic.
- **`input.conf`**: Maps dedicated shortcuts to cycle through discovered companion files.
- **`mpv.conf`**: Exposes config options to toggle companion loading behaviors.
- **`README.md`**: Documents the new capabilities, shortcuts, and directory structure expectations.
