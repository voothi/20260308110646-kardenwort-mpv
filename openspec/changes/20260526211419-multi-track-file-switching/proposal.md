## Why

During language acquisition, users often deal with multi-lingual material where different language tracks (audio/video/subtitles) are stored in separate companion files in the same directory rather than multiplexed within a single container (e.g., `20260525163647-executive-briefing-your-ai.mp4` along with `20260525163647-executive-briefing-your-ai.ru.mp4` and `20260525163647-executive-briefing-your-ai.de.mp4`). 

Currently, MPV track switching only operates on multiplexed tracks within the active container, leaving users with no seamless way to switch languages across physical companion files while staying in the same media session.

## What Changes

- **Companion Discovery**: Automatically scans the active media directory to identify and index companion media files sharing the same prefix but possessing language postfixes (e.g., `<name>.<lang>.<ext>`).
- **Unified Switcher Logic**: Consolidates companion audio and standard internal track cycling under a single keyboard shortcut (`Shift+3`, `SHARP`, or `№`). If multiple companion files are found, their audio is attached as external audio tracks and included in one `aid` cycle. If no companion files exist, it falls back seamlessly to cycling multiplexed tracks inside the container.
- **Audio-Only Continuity**: Keeps playback continuity by not replacing the active media file during companion language switches.
- **Themed HUD Confirmation**: Reports active audio instantly with a premium, semi-transparent Kardenwort OSD card matching the suite's theme.
- **Layout-Agnostic Keybindings**: Registers hotkeys in both English and Russian keyboards for unified track cycling.
- **Production Hardening**: Adds companion safety gates (no self-attachment, no duplicate re-attachment), plus explicit runtime toggles for staged rollout.

## Capabilities

## Impact

- **`scripts/kardenwort/main.lua`**: Implements directory scanning, base/postfix matching, companion audio attachment, and themed OSD notification logic under the unified `cmd_cycle_audio` action.
- **`input.conf`**: Cleans up secondary key bindings to keep all track switching actions unified on `Shift+3`.
- **`mpv.conf`**: Exposes config options to toggle companion loading behaviors.
- **`README.md`**: Documents the new capabilities, shortcuts, and directory structure expectations.
- **`tests/acceptance/*multi_track_production_hardening.py`**: Adds runtime checks for no-file-replace behavior, no duplicate attachment, and no self-attachment when booting from postfix media.
