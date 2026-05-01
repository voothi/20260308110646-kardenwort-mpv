## ADDED Requirements

### Requirement: Display filename on resume
The system SHALL display the filename of the resumed media in the OSD upon automatic session restoration.

#### Scenario: Successful auto-resume
- **WHEN** the last file is automatically loaded on startup
- **THEN** an OSD message containing the filename is displayed

### Requirement: Display connected subtitle tracks
The system SHALL identify and display the filenames of any matching sidecar subtitle files (SRT/ASS) in the same directory as the media.

#### Scenario: Multiple subtitles present
- **WHEN** a video with multiple `.srt` or `.ass` files is loaded
- **THEN** the OSD message lists the subtitle filenames in a vertical column below the media filename

### Requirement: Prioritize subtitle display order
The system SHALL sort the displayed subtitle files such that the primary target language (non-Russian) appears before secondary support languages (Russian).

#### Scenario: Both English and Russian subtitles found
- **WHEN** `movie.en.srt` and `movie.ru.srt` are detected
- **THEN** the OSD lists `movie.en.srt` first and `movie.ru.srt` second

### Requirement: Customizable OSD aesthetics
The system SHALL provide configuration options to adjust the OSD font size and message duration for the startup notification.

#### Scenario: Low-resolution display
- **WHEN** the user sets `osd_font_size` to a specific value
- **THEN** the startup OSD message uses that font size via temporary property adjustment
