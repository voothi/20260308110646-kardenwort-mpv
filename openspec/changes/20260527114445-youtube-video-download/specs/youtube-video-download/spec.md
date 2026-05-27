## ADDED Requirements

### Requirement: YouTube URL Detection
The download system SHALL detect YouTube URLs in input files. The system SHALL support standard YouTube URL formats including youtube.com and youtu.be links.

#### Scenario: Single YouTube URL in file
- **WHEN** a file contains a single YouTube URL
- **THEN** the system SHALL identify and extract the URL for download

#### Scenario: Multiple YouTube URLs in file
- **WHEN** a file contains multiple YouTube URLs
- **THEN** the system SHALL identify and extract all URLs for batch download

#### Scenario: No YouTube URL in file
- **WHEN** a file contains no YouTube URLs
- **THEN** the system SHALL display an error message
- **AND** the system SHALL not attempt any download

### Requirement: Configurable Download Resolution
The download system SHALL expose `youtube_download_resolution` as a string setting. This setting SHALL define the preferred video resolution for downloads.

#### Scenario: Resolution is set to 1080p
- **WHEN** `youtube_download_resolution` is `"1080p"`
- **AND** a video is downloaded
- **THEN** the downloaded video SHALL be at 1080p resolution or the closest available resolution

#### Scenario: Resolution is set to 720p
- **WHEN** `youtube_download_resolution` is `"720p"`
- **AND** a video is downloaded
- **THEN** the downloaded video SHALL be at 720p resolution or the closest available resolution

#### Scenario: Requested resolution is unavailable
- **WHEN** the requested resolution is not available for a video
- **THEN** the system SHALL download the closest available resolution
- **AND** the system SHALL log a message about the resolution fallback

### Requirement: Configurable Download Directory
The download system SHALL expose `youtube_download_directory` as a string setting. This setting SHALL define the target directory for downloaded videos.

#### Scenario: Directory is set to valid path
- **WHEN** `youtube_download_directory` is set to a valid directory path
- **AND** a video is downloaded
- **THEN** the video SHALL be saved to the specified directory

#### Scenario: Directory does not exist
- **WHEN** `youtube_download_directory` is set to a path that does not exist
- **THEN** the system SHALL create the directory
- **AND** the system SHALL download the video to the newly created directory

#### Scenario: Directory is not writable
- **WHEN** `youtube_download_directory` is set to a path that is not writable
- **THEN** the system SHALL display an error message
- **AND** the system SHALL not attempt the download

### Requirement: yt-dlp Backend
The download system SHALL use yt-dlp as the sole download backend. The system SHALL verify that yt-dlp is installed and available.

#### Scenario: yt-dlp is available
- **WHEN** yt-dlp is installed and available
- **AND** a video is downloaded
- **THEN** the system SHALL use yt-dlp for the download

#### Scenario: yt-dlp is not available
- **WHEN** yt-dlp is not installed or not available
- **THEN** the system SHALL display an error message
- **AND** the system SHALL not attempt the download
- **AND** the system SHALL provide installation instructions

### Requirement: yt-dlp Auto-Update
The download system SHALL check for and install yt-dlp updates before starting downloads. The system SHALL expose `youtube_download_auto_update` as a boolean setting.

#### Scenario: Auto-update is enabled and update is available
- **WHEN** `youtube_download_auto_update` is `true`
- **AND** a yt-dlp update is available
- **AND** a video download is initiated
- **THEN** the system SHALL download and install the yt-dlp update
- **AND** the system SHALL log a message about the update
- **AND** the system SHALL proceed with the video download

#### Scenario: Auto-update is enabled and no update is available
- **WHEN** `youtube_download_auto_update` is `true`
- **AND** no yt-dlp update is available
- **AND** a video download is initiated
- **THEN** the system SHALL proceed with the video download without updating

#### Scenario: Auto-update is disabled
- **WHEN** `youtube_download_auto_update` is `false`
- **AND** a video download is initiated
- **THEN** the system SHALL proceed with the video download without checking for updates

#### Scenario: Update check fails
- **WHEN** the yt-dlp update check fails
- **THEN** the system SHALL log a warning message
- **AND** the system SHALL proceed with the video download using the current yt-dlp version

### Requirement: Chapter Metadata Download
The download system SHALL download videos with chapter metadata. The system SHALL expose `youtube_download_chapters_mode` as a string setting to control chapter output mode: "embedded", "separate", or "both".

#### Scenario: Chapters embedded in video (default)
- **WHEN** `youtube_download_chapters_mode` is `"embedded"`
- **AND** a YouTube video has chapter metadata
- **AND** the video is downloaded
- **THEN** the downloaded video SHALL contain embedded chapter markers
- **AND** the chapters SHALL be accessible during playback
- **AND** no separate chapter file SHALL be created

#### Scenario: Chapters saved to separate file only
- **WHEN** `youtube_download_chapters_mode` is `"separate"`
- **AND** a YouTube video has chapter metadata
- **AND** the video is downloaded
- **THEN** the system SHALL save chapter metadata to a separate file
- **AND** the chapter file SHALL have the same base name as the video with a `.chapters.txt` suffix
- **AND** the chapter file SHALL contain chapter titles and timestamps in a readable format
- **AND** the video SHALL NOT contain embedded chapter markers

#### Scenario: Chapters embedded and saved to separate file
- **WHEN** `youtube_download_chapters_mode` is `"both"`
- **AND** a YouTube video has chapter metadata
- **AND** the video is downloaded
- **THEN** the downloaded video SHALL contain embedded chapter markers
- **AND** the chapters SHALL be accessible during playback
- **AND** the system SHALL also save chapter metadata to a separate file
- **AND** the chapter file SHALL have the same base name as the video with a `.chapters.txt` suffix
- **AND** the chapter file SHALL contain chapter titles and timestamps in a readable format

#### Scenario: Video has no chapters
- **WHEN** a YouTube video has no chapter metadata
- **AND** the video is downloaded
- **THEN** the system SHALL download the video without chapters
- **AND** the system SHALL not create a chapter file
- **AND** the system SHALL not display an error

### Requirement: SRT Subtitle Download
The download system SHALL automatically download SRT subtitle files separately for each available language.

#### Scenario: Video has subtitles
- **WHEN** a YouTube video has subtitles available
- **AND** the video is downloaded
- **THEN** the system SHALL download SRT subtitle files for each available language
- **AND** the subtitle files SHALL be saved in the same directory as the video
- **AND** the subtitle files SHALL have the same base name as the video with language code suffix

#### Scenario: Video has no subtitles
- **WHEN** a YouTube video has no subtitles available
- **AND** the video is downloaded
- **THEN** the system SHALL download the video without subtitles
- **AND** the system SHALL log a message that no subtitles were available

#### Scenario: Subtitle download fails
- **WHEN** subtitle download fails
- **THEN** the system SHALL log a warning message
- **AND** the system SHALL continue with video download

### Requirement: Windows "Send to" Integration
The download system SHALL provide a Windows "Send to" integration that allows right-clicking on files and selecting "Download YouTube Video".

#### Scenario: File sent via "Send to"
- **WHEN** a user right-clicks on a file containing YouTube URLs
- **AND** selects "Send to" → "Download YouTube Video"
- **THEN** the system SHALL process the file
- **AND** download the videos using configured settings

#### Scenario: Multiple files sent via "Send to"
- **WHEN** a user selects multiple files containing YouTube URLs
- **AND** selects "Send to" → "Download YouTube Video"
- **THEN** the system SHALL process all files
- **AND** download videos from all files

### Requirement: Download Progress Feedback
The download system SHALL provide progress feedback for downloads.

#### Scenario: Download in progress
- **WHEN** a video is being downloaded
- **THEN** the system SHALL display download progress
- **AND** the system SHALL show estimated time remaining

#### Scenario: Download completes successfully
- **WHEN** a video download completes successfully
- **THEN** the system SHALL display a success message
- **AND** the system SHALL show the file path of the downloaded video

#### Scenario: Download fails
- **WHEN** a video download fails
- **THEN** the system SHALL display an error message
- **AND** the system SHALL log the error details

### Requirement: Existing File Handling
The download system SHALL handle cases where a video file already exists in the target directory.

#### Scenario: File already exists
- **WHEN** a video file with the same name already exists in the target directory
- **THEN** the system SHALL skip the download
- **AND** the system SHALL log a message that the file was skipped

#### Scenario: File already exists with overwrite option
- **WHEN** a video file with the same name already exists
- **AND** an overwrite option is enabled
- **THEN** the system SHALL overwrite the existing file
- **AND** the system SHALL log a message that the file was overwritten