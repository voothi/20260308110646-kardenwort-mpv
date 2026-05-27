## ADDED Requirements

### Requirement: YouTube URL Detection
The download system SHALL detect YouTube URLs in input files and directories. The system SHALL support standard YouTube URL formats including youtube.com and youtu.be links.

#### Scenario: Single YouTube URL in file
- **WHEN** a file contains a single YouTube URL
- **THEN** the system SHALL identify and extract the URL for download

#### Scenario: Multiple YouTube URLs in file
- **WHEN** a file contains multiple YouTube URLs
- **THEN** the system SHALL identify and extract all URLs for batch download

#### Scenario: Directory with multiple files containing URLs
- **WHEN** a directory is selected via "Send to"
- **AND** the directory contains multiple files with YouTube URLs
- **THEN** the system SHALL search for files containing YouTube URLs
- **AND** the system SHALL process files in queue order
- **AND** the system SHALL extract URLs from each file in order

#### Scenario: No YouTube URL in file
- **WHEN** a file contains no YouTube URLs
- **THEN** the system SHALL display an error message
- **AND** the system SHALL not attempt any download

#### Scenario: No files with URLs in directory
- **WHEN** a directory is selected via "Send to"
- **AND** the directory contains no files with YouTube URLs
- **THEN** the system SHALL display an error message
- **AND** the system SHALL not attempt any download

### Requirement: ZID-Based Filename Generation
The download system SHALL generate unique ZID-based filenames for downloaded videos using the same naming convention as `zid_name.py`.

#### Scenario: Generate ZID-based filename
- **WHEN** a video is downloaded
- **THEN** the system SHALL generate a unique ZID in YYYYMMDDHHMMSS format
- **AND** the system SHALL extract the video title from YouTube metadata
- **AND** the system SHALL apply `zid_name.py` sanitization rules to the title
- **AND** the system SHALL format the filename as `{ZID}-{sanitized-title}.mp4`

#### Scenario: Handle special characters in title
- **WHEN** a video title contains special characters
- **THEN** the system SHALL sanitize the title according to `zid_name.py` rules
- **AND** the system SHALL replace special characters with appropriate alternatives
- **AND** the system SHALL preserve file extension

#### Scenario: Generate unique ZID for each download
- **WHEN** multiple videos are downloaded
- **THEN** each video SHALL receive a unique ZID based on its download timestamp
- **AND** no two videos SHALL have the same ZID

#### Scenario: ZID collision in batch download
- **WHEN** two or more videos are queued for download within the same second
- **THEN** the system SHALL detect the duplicate ZID before use
- **AND** the system SHALL wait 1 second and generate a new ZID
- **AND** the resulting filenames SHALL still be unique

### Requirement: Configurable Download Resolution
The download system SHALL expose `youtube_download_resolution` as a string setting. This setting SHALL define the preferred video resolution for downloads. The default value SHALL be "360p".

#### Scenario: Resolution is set to default (360p)
- **WHEN** `youtube_download_resolution` is not explicitly set
- **AND** a video is downloaded
- **THEN** the downloaded video SHALL be at 360p resolution or the closest available resolution

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

#### Scenario: yt-dlp is not available and auto-update is enabled
- **WHEN** yt-dlp is not installed
- **AND** `youtube_download_auto_update` is `true`
- **THEN** the system SHALL attempt to install yt-dlp via `pip install yt-dlp`
- **AND** the system SHALL log a message about the installation
- **AND** if installation succeeds the system SHALL proceed with the download
- **AND** if installation fails the system SHALL display an error with manual installation instructions

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

### Requirement: Download Mode
The download system SHALL expose `youtube_download_mode` as a string setting controlling what is fetched for each URL. Valid values are `"video+subtitles"` (default), `"video"`, and `"subtitles"`.

#### Scenario: Mode is "video+subtitles" (default)
- **WHEN** `youtube_download_mode` is `"video+subtitles"`
- **AND** a URL is processed
- **THEN** the system SHALL download the video file
- **AND** the system SHALL download subtitle files according to `youtube_download_subtitle_languages` and `youtube_download_subtitle_auto_fallback`

#### Scenario: Mode is "video"
- **WHEN** `youtube_download_mode` is `"video"`
- **AND** a URL is processed
- **THEN** the system SHALL download the video file only
- **AND** the system SHALL not perform any subtitle operations
- **AND** the system SHALL not log subtitle-related messages

#### Scenario: Mode is "subtitles"
- **WHEN** `youtube_download_mode` is `"subtitles"`
- **AND** a URL is processed
- **THEN** the system SHALL download subtitle files only
- **AND** the system SHALL NOT download the video file
- **AND** the subtitle files SHALL be named `{ZID}-{sanitized-title}.{lang}.srt`

### Requirement: SRT Subtitle Download
The download system SHALL automatically download SRT subtitle files when `youtube_download_mode` is `"video+subtitles"` or `"subtitles"`. The system SHALL expose `youtube_download_subtitle_languages` and `youtube_download_subtitle_auto_fallback` as configuration options. Subtitles SHALL always be converted to SRT format via `--convert-subs srt` regardless of the format provided by YouTube.

#### Scenario: Download original subtitles only
- **WHEN** `youtube_download_subtitle_languages` is `"original"`
- **AND** a YouTube video has original subtitles available
- **AND** the video is downloaded
- **THEN** the system SHALL resolve the video's detected language from YouTube metadata (`language` field in yt-dlp JSON output)
- **AND** the system SHALL download SRT subtitle files for that detected language
- **AND** the subtitle files SHALL be saved in the same directory as the video
- **AND** the subtitle files SHALL have the same ZID and name as the video with language code postfix (e.g., `{ZID}-{name}.en.srt`)

#### Scenario: Original language field absent in metadata
- **WHEN** `youtube_download_subtitle_languages` is `"original"`
- **AND** the video's YouTube metadata does not contain a `language` field
- **THEN** the system SHALL download all available manual subtitle tracks
- **AND** the system SHALL log a message that language auto-detection fell back to all available subtitles

#### Scenario: Download specific languages
- **WHEN** `youtube_download_subtitle_languages` is a comma-separated list (e.g., "en,de,ru")
- **AND** a YouTube video has subtitles for the specified languages
- **AND** the video is downloaded
- **THEN** the system SHALL download separate SRT subtitle files for each specified language
- **AND** the subtitle files SHALL be saved in the same directory as the video
- **AND** the subtitle files SHALL have the same ZID and name as the video with language code postfix

#### Scenario: Auto-subtitle fallback enabled
- **WHEN** `youtube_download_subtitle_auto_fallback` is `true`
- **AND** a YouTube video has no manual subtitles for the requested language
- **AND** the video is downloaded
- **THEN** the system SHALL download auto-generated subtitles for the requested language
- **AND** the system SHALL log a message that auto-subtitles were downloaded

#### Scenario: Auto-subtitle fallback disabled
- **WHEN** `youtube_download_subtitle_auto_fallback` is `false`
- **AND** a YouTube video has no manual subtitles for the requested language
- **AND** the video is downloaded
- **THEN** the system SHALL not download subtitles for that language
- **AND** the system SHALL log a message that no manual subtitles were available

#### Scenario: Video has no subtitles
- **WHEN** a YouTube video has no subtitles available (manual or auto)
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

### Requirement: Duplicate File Handling
The download system SHALL expose `youtube_download_duplicate_mode` as a string setting controlling what happens when an output file already exists. Valid values are `"zid-dir"` (default), `"skip"`, and `"overwrite"`. The session ZID used for `"zid-dir"` SHALL be shared across all downloads in one "Send to" invocation via a `zid_cache` dict initialized once per session.

#### Scenario: Duplicate mode is "zid-dir" (default) — file already exists
- **WHEN** `youtube_download_duplicate_mode` is `"zid-dir"`
- **AND** the target output file already exists in `youtube_download_directory`
- **THEN** the system SHALL create a subdirectory named `{session-ZID}/` inside `youtube_download_directory`
- **AND** the system SHALL place the downloaded file inside that subdirectory
- **AND** the system SHALL log a message indicating the file was placed in the ZID subfolder

#### Scenario: Duplicate mode is "zid-dir" — multiple duplicates in one session
- **WHEN** `youtube_download_duplicate_mode` is `"zid-dir"`
- **AND** multiple URLs in one session produce files that already exist
- **THEN** all duplicate files SHALL be placed in the same `{session-ZID}/` subfolder
- **AND** the session ZID SHALL be the same for all duplicates within one "Send to" invocation

#### Scenario: Duplicate mode is "skip"
- **WHEN** `youtube_download_duplicate_mode` is `"skip"`
- **AND** the target output file already exists
- **THEN** the system SHALL skip the download
- **AND** the system SHALL log a message that the file was skipped

#### Scenario: Duplicate mode is "overwrite"
- **WHEN** `youtube_download_duplicate_mode` is `"overwrite"`
- **AND** the target output file already exists
- **THEN** the system SHALL overwrite the existing file
- **AND** the system SHALL log a message that the file was overwritten

### Requirement: MP4 Container Enforcement
The download system SHALL always produce MP4 output files by remuxing the downloaded streams into an MP4 container without re-encoding. This is achieved via `--merge-output-format mp4` passed to yt-dlp.

#### Scenario: yt-dlp selects non-MP4 format
- **WHEN** yt-dlp's best-quality format selection would produce a `.webm` or `.mkv` output
- **AND** a video is downloaded
- **THEN** the system SHALL pass `--merge-output-format mp4` to yt-dlp
- **AND** the downloaded file SHALL have a `.mp4` extension
- **AND** no video or audio re-encoding SHALL occur

#### Scenario: Filename extension matches container
- **WHEN** a video download completes
- **THEN** the output filename SHALL always end with `.mp4`
- **AND** the filename format SHALL be `{ZID}-{sanitized-title}.mp4`