## ADDED Requirements

### Requirement: OSD-Independent Clipboard Extraction
The system SHALL ensure that global copy operations correctly retrieve subtitle text even when native `mpv` subtitle visibility is disabled for custom OSD rendering.

#### Scenario: Copying in White Subtitles Mode
- **WHEN** the user is in "Regular Mode" (Drum Window OFF) with OSD rendering for SRT enabled.
- **AND** the user presses `Ctrl+c` while `COPY_CONTEXT` is "OFF".
- **THEN** the system SHALL correctly identify the current subtitle from the internal track table and copy it to the clipboard.

### Requirement: Unified Source Fallback
The system SHALL utilize the internal subtitle index as the primary source for standard copy operations, falling back to native properties only if internal data is unavailable.

#### Scenario: Copying with language filter
- **WHEN** the user has multiple tracks loaded and `COPY_MODE` is set to "B" (Russian).
- **AND** the user presses `Ctrl+c`.
- **THEN** the system SHALL extract the Russian translation line from the internal `Tracks.sec.subs` table if the primary track is English.
