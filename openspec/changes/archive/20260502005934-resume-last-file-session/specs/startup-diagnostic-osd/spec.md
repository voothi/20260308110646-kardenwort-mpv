## ADDED Requirements

### Requirement: Display filename on resume
The system SHALL display the filename of the resumed media in the OSD immediately upon automatic session restoration.

#### Scenario: Successful auto-resume
- **WHEN** a file is automatically loaded on startup via the session-persistence mechanism
- **THEN** a clear OSD notification containing the filename is rendered in the primary viewing area

### Requirement: Display connected subtitle tracks
The system SHALL detect and display the full filenames of all matching sidecar subtitle files (SRT/ASS) located in the same directory as the primary media.

#### Scenario: Multiple subtitles present
- **WHEN** the media directory contains one or more matching `.srt` or `.ass` files
- **THEN** the OSD message lists these files in a vertical column below the primary media filename

### Requirement: Prioritize subtitle display order
The system SHALL organize the subtitle file list such that the primary target language (non-Russian) is anchored at the top, followed by secondary support languages (Russian).

#### Scenario: Dual-language subtitle detection
- **WHEN** both `.en.srt` and `.ru.srt` files are detected for the current video
- **THEN** the OSD lists the English file first and the Russian file second

### Requirement: High-fidelity OSD rendering
The system SHALL render the diagnostic message using a high-resolution OSD overlay (1920x1080) to ensure consistent font sizing and aesthetic parity with the core LLS UI.

#### Scenario: Visual consistency
- **WHEN** the startup OSD is triggered
- **THEN** the message is rendered as a `ass-events` overlay with explicit border and shadow styling to ensure legibility against various video backgrounds

### Requirement: Customizable typography and duration
The system SHALL provide configuration options to adjust the OSD font name, font size, and message persistence duration.

#### Scenario: User-defined aesthetics
- **WHEN** the user modifies `osd_font_name` or `osd_font_size` in the script options
- **THEN** the startup OSD message applies these parameters during its display window
