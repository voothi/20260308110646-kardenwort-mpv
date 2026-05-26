## ADDED Requirements

### Requirement: Companion Track File Discovery
The system SHALL scan the parent directory of the currently active media file on load and dynamic request to index all companion media files. Companion media files are defined as files in the same directory sharing the exact same base prefix but possessing a language postfix before the extension (e.g., `video.mp4` has companion files `video.ru.mp4` and `video.de.mp4`).
The system SHALL normalize postfix tags to uppercase languages (e.g., `.ru` -> `RU`, `.de` -> `DE`, no postfix -> `ORIGINAL`).

#### Scenario: Indexing multiple companion files in directory
- **WHEN** a media file `video.mp4` is loaded and directory contains `video.ru.mp4` and `video.de.mp4`
- **THEN** the system successfully indexes the tracks: `ORIGINAL` (active), `RU`, and `DE`.

### Requirement: Unified Audio and Companion Cycling (Shift+3)
The system SHALL support unified, dynamic track cycling bound layout-safely to `Shift+3`, `SHARP`, and `№`.
If more than 1 companion media file is indexed in the folder, the hotkey SHALL cycle between companion files.
If 1 or fewer companion media files exist, the hotkey SHALL cycle the internal multiplexed audio tracks inside the media container, adhering to the standard GBoard-style time-threshold cycle behavior.

### Requirement: State-Preserving Companion Swapping
The system SHALL support dynamic, seamless swapping of the active media file to a companion track file upon user request.
During swapping, the system MUST preserve:
1. Current playback position (`time-pos`) in seconds.
2. Current playback speed multiplier (`speed`).
3. Current playback state (paused vs. playing).
The system SHALL trigger the replacement using the native `loadfile` MPV command with exact time restoration, resuming playback smoothly.

#### Scenario: Seamless swap of media file during playback
- **WHEN** user triggers a companion track file swap from `video.mp4` (playing at 42.5 seconds, speed 1.1x) to `video.ru.mp4`
- **THEN** the system reloads the file with `video.ru.mp4`, restoring position to 42.5 seconds, speed to 1.1x, and continues playing.


### Requirement: Themed HUD Notification
The system SHALL display an instant OSD confirmation when swapping companion files.
The OSD confirmation MUST be rendered using the custom themed, semi-transparent Kardenwort OSD notice box rather than plain, unstyled MPV OSD.

#### Scenario: OSD feedback on companion file cycle
- **WHEN** the user cycles the companion track file to `DE`
- **THEN** the system displays a themed OSD box containing `"Track: DE"` for a short duration.
