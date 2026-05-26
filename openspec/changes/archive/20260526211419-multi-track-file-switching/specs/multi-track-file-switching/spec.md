## ADDED Requirements

### Requirement: Companion Track File Discovery
The system SHALL scan the parent directory of the currently active media file on load and dynamic request to index all companion media files. Companion media files are defined as files in the same directory sharing the exact same base prefix but possessing a language postfix before the extension (e.g., `video.mp4` has companion files `video.ru.mp4` and `video.de.mp4`).
The system SHALL normalize postfix tags to uppercase languages (e.g., `.ru` -> `RU`, `.de` -> `DE`, no postfix -> `ORIGINAL`).

#### Scenario: Indexing multiple companion files in directory
- **WHEN** a media file `video.mp4` is loaded and directory contains `video.ru.mp4` and `video.de.mp4`
- **THEN** the system successfully indexes the tracks: `ORIGINAL` (active), `RU`, and `DE`.

### Requirement: Unified Audio and Companion Cycling (Shift+3)
The system SHALL support unified, dynamic track cycling bound layout-safely to `Shift+3`, `SHARP`, and `№`.
If more than 1 companion media file is indexed in the folder, the hotkey SHALL attach companion file audio tracks as external audio tracks and cycle `aid` across internal and external audio options.
If 1 or fewer companion media files exist, the hotkey SHALL cycle the internal multiplexed audio tracks inside the media container, adhering to the standard GBoard-style time-threshold cycle behavior.

#### Scenario: Shift+3 cycles audio without replacing media file
- **WHEN** a media file `video.mp4` is loaded and companion files `video.ru.mp4` and `video.de.mp4` exist
- **THEN** pressing `Shift+3` attaches companion audio tracks and cycles active audio using `aid`
- **AND** the active media file path remains `video.mp4`.

### Requirement: Companion Audio Attachment
The system SHALL treat companion files as audio providers and SHALL NOT replace the active media file for companion audio switching.
During companion handling, the system MUST:
1. Discover and attach missing companion file audio tracks via MPV external audio track APIs.
2. Keep current playback position, speed, and pause state naturally unchanged because no `loadfile replace` occurs.
3. Continue using one unified `Shift+3` cycle flow for both internal and companion-provided audio tracks.

#### Scenario: Companion file audio is added as external track
- **WHEN** user triggers audio cycling on `video.mp4` and companion file `video.ru.mp4` exists
- **THEN** `video.ru.mp4` audio is attached as an external audio track
- **AND** the media file is not replaced.

### Requirement: Companion Attachment Safety
The system SHALL prevent redundant or self-referential companion audio attachment to keep the audio track-list stable in long-running sessions.

#### Scenario: Active postfix file is not re-attached as external audio
- **GIVEN** the active media path is `video.ru.mp4`
- **AND** sibling files include `video.mp4` and `video.de.mp4`
- **WHEN** companion discovery/attachment runs
- **THEN** `video.ru.mp4` is not attached as an external audio track.

#### Scenario: Repeated cycling does not duplicate companion tracks
- **GIVEN** companion audio tracks for `video.ru.mp4` and `video.de.mp4` are already attached
- **WHEN** the user triggers `Shift+3` repeatedly
- **THEN** the number of companion external audio tracks remains unchanged.

### Requirement: Companion Configuration Controls
The system SHALL expose runtime options in `kardenwort` script options to support production-safe rollout and rollback.

#### Scenario: Companion behavior can be toggled and pre-attached on load
- **WHEN** `kardenwort-companion_audio_enabled=yes` and `kardenwort-companion_audio_attach_on_load=yes`
- **THEN** companion audio discovery is enabled for both `file-loaded` and on-demand cycle execution.
- **AND** setting either option to `no` disables that specific behavior without requiring code changes.


### Requirement: Themed HUD Notification
The system SHALL display an instant OSD confirmation when switching active audio tracks.
The OSD confirmation MUST be rendered using the custom themed, semi-transparent Kardenwort OSD notice box rather than plain, unstyled MPV OSD.

#### Scenario: OSD feedback on companion file cycle
- **WHEN** the user cycles the companion track file to `DE`
- **THEN** the system displays a themed OSD box containing `"Audio: DE"` for a short duration.
