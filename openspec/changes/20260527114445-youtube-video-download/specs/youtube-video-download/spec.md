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

### Requirement: Multiple Download Backend Support
The download system SHALL support multiple download backends: yt-dlp, youtube-dl-gui, newpipe, and asbplayer. The system SHALL expose `youtube_download_backend` as a string setting to select the backend.

#### Scenario: Backend is set to yt-dlp
- **WHEN** `youtube_download_backend` is `"yt-dlp"`
- **AND** a video is downloaded
- **THEN** the system SHALL use yt-dlp for the download

#### Scenario: Backend is set to youtube-dl-gui
- **WHEN** `youtube_download_backend` is `"youtube-dl-gui"`
- **AND** a video is downloaded
- **THEN** the system SHALL use youtube-dl-gui for the download

#### Scenario: Backend is set to newpipe
- **WHEN** `youtube_download_backend` is `"newpipe"`
- **AND** a video is downloaded
- **THEN** the system SHALL use newpipe for the download

#### Scenario: Backend is set to asbplayer
- **WHEN** `youtube_download_backend` is `"asbplayer"`
- **AND** a video is downloaded
- **THEN** the system SHALL use asbplayer for the download

#### Scenario: Backend is not available
- **WHEN** the selected backend is not installed or available
- **THEN** the system SHALL display an error message
- **AND** the system SHALL not attempt the download

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