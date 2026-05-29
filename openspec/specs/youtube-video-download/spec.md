# youtube-video-download Specification

## Purpose
TBD - created by archiving change 20260527114445-youtube-video-download. Update Purpose after archive.
## Requirements
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

When executing in a TTY environment, the system SHALL render an in-place, carriage-returned, premium pip-style progress bar (green/grey block aesthetic) for both the video stream and the subtitle stream of every URL.

When executing in a non-TTY environment, the system SHALL emit textual progress lines using a delta-based throttling pattern. For the **video** byte-progress stream, the system SHALL print:
1. The very first progress event (the first emission with a parseable percent value).
2. Every progress event whose percent value has increased by at least 10% since the last printed line.
3. The completion event (the explicit `[download] 100% of ... in ... at ...` line).

For the **subtitle** byte-progress stream (which yt-dlp emits without a percent value), the system SHALL print at least one progress line per subtitle file in non-TTY mode so that subtitle progress is not silently dropped, and SHALL print the subtitle completion summary on a clean new line.

The system SHALL print queue section headers with the per-URL counter brackets (e.g. `[3/10]`) wrapped in dim grey ANSI styling to match the project's premium pip-style cue counter convention.

Upon transition between processing stages (URL → metadata → video stream → subtitle stream → companion-audio stream → final OK summary), the system SHALL call the parameterized line-clearing helper before printing any standalone summary log line, so that no carriage-return residue from prior in-place output leaks into the next line.

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

#### Scenario: Queue section header styling
- **WHEN** the system prints the section header for one entry in the URL processing queue
- **THEN** the `[idx/total]` counter SHALL be wrapped in ANSI dim grey styling
- **AND** the source label (file name or "Direct URL") SHALL be wrapped in ANSI bold styling
- **AND** in non-TTY environments the styling SHALL collapse to plain text without raw escape sequences

#### Scenario: Non-TTY video progress throttling
- **WHEN** a video download is in progress
- **AND** stdout is not a TTY
- **THEN** the system SHALL print the first parseable progress event
- **AND** SHALL print only subsequent events whose percent value has increased by at least 10% since the last printed event
- **AND** SHALL print the completion event on its own line

#### Scenario: Non-TTY subtitle progress is not silently dropped
- **WHEN** a subtitle file is being downloaded
- **AND** stdout is not a TTY
- **THEN** the system SHALL print at least one subtitle-progress line for that file
- **AND** SHALL print the subtitle completion summary line when the file completes

#### Scenario: Inter-stage transition cleanup
- **WHEN** a TTY-mode in-place progress bar has just been emitted
- **AND** the system is about to print a standalone `[OK]`, `[INFO]`, `[WARN]`, or section header line
- **THEN** the system SHALL call the line-clearing helper before printing the next line
- **AND** no carriage-return residue from the prior bar SHALL appear on the new line

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

### Requirement: SRT Subtitle Post-Processing
The download system SHALL apply configurable post-processing to downloaded SRT files to clean up common artifacts from YouTube's rolling-caption and auto-translation pipelines.

#### Scenario: Clean leading hyphens from subtitle lines
- **WHEN** `youtube_download_clean_hyphens` is `true`
- **AND** a subtitle file has been downloaded
- **THEN** the system SHALL strip leading `-`, `–`, or `—` characters (and any following spaces) from each subtitle text line

#### Scenario: Unbreak multi-line subtitle blocks into single lines
- **WHEN** `youtube_download_unbreak_lines` is `true`
- **AND** a subtitle block contains multiple text lines
- **THEN** the system SHALL join those lines into a single line
- **AND** the system SHALL handle word-hyphenation breaks (e.g. `hyphen-\nnation` → `hyphenation`)
- **AND** the system SHALL preserve compositional hyphens when a line is broken before a conjunction listed in `youtube_download_compositional_conjunctions`

#### Scenario: Fix sentence-split artifacts from auto-translated tracks
- **WHEN** `youtube_download_fix_sentence_splits` is `true`
- **AND** a subtitle block's entire text content is a punctuation character only (e.g. `.`)
- **THEN** the system SHALL append that punctuation to the previous block's last line
- **AND** the system SHALL remove the punctuation-only block

#### Scenario: Fix leading-punctuation artifacts from auto-translated tracks
- **WHEN** `youtube_download_fix_sentence_splits` is `true`
- **AND** a subtitle block's text begins with a punctuation character (e.g. `. Next sentence` or `, continuation`)
- **THEN** the system SHALL strip the leading punctuation from the block
- **AND** the system SHALL append it to the previous block's last line
- **AND** if text remains after the punctuation, the system SHALL preserve it as the block's content

#### Scenario: Post-processing is disabled by default
- **WHEN** `youtube_download_clean_hyphens` is `false`
- **AND** `youtube_download_unbreak_lines` is `false`
- **AND** `youtube_download_fix_sentence_splits` is `false`
- **THEN** the system SHALL write the cleaned (deduplicated) SRT without any further modifications

### Requirement: Secondary Subtitle Timestamp Synchronization
The download system SHALL expose `youtube_download_sync_secondary_timestamps` as a boolean setting. When enabled, after all subtitle tracks are downloaded and cleaned, the system SHALL re-timestamp all secondary subtitle tracks to match the primary (first-downloaded) track using time-based nearest-neighbour matching.

#### Scenario: Sync is enabled and multiple tracks were downloaded
- **WHEN** `youtube_download_sync_secondary_timestamps` is `true`
- **AND** two or more subtitle files have been written for a video
- **THEN** the system SHALL use the first downloaded track as the primary timeline
- **AND** for each secondary track block, the system SHALL find the primary block whose start time is closest by time (binary search, monotonic forward progress)
- **AND** the system SHALL write the matched primary timestamps onto the secondary track
- **AND** the secondary track's text content SHALL remain untouched
- **AND** the system SHALL log the number of re-timestamped blocks

#### Scenario: Sync is disabled (default)
- **WHEN** `youtube_download_sync_secondary_timestamps` is `false`
- **THEN** downloaded subtitle tracks SHALL retain their original timestamps from YouTube

#### Scenario: Secondary file is missing
- **WHEN** `youtube_download_sync_secondary_timestamps` is `true`
- **AND** the secondary subtitle file does not exist
- **THEN** the system SHALL log a warning and continue without error

#### Scenario: Block counts differ between primary and secondary tracks
- **WHEN** the primary track has more blocks than the secondary track (or vice versa)
- **THEN** the system SHALL match each secondary block to the nearest primary block by time
- **AND** all secondary blocks SHALL be preserved in the output (no trimming)
- **AND** secondary blocks beyond the primary timeline SHALL map to the last available primary block

### Requirement: Skip-Mode Recovery Correctness
When `youtube_download_duplicate_mode` is `"skip"` and a matching video file already exists, the system SHALL recover only truly missing artifacts and SHALL avoid reprocessing pre-existing subtitle files.

#### Scenario: Only companion audio is missing
- **WHEN** the video file already exists
- **AND** all expected subtitle/chapter artifacts already exist
- **AND** one or more companion audio files are missing
- **THEN** the system SHALL skip video download
- **AND** the system SHALL skip subtitle download
- **AND** the system SHALL download only the missing companion audio files

#### Scenario: Pre-existing subtitles during skip recovery
- **WHEN** skip-mode recovery runs for a video with some subtitle files already present
- **AND** additional subtitle files are newly downloaded in this recovery run
- **THEN** subtitle post-processing (`clean_srt_file`) SHALL run only on newly downloaded subtitle files
- **AND** already-existing subtitle files SHALL NOT be post-processed again

#### Scenario: Timestamp sync with mixed pre-existing and newly downloaded subtitles
- **WHEN** `youtube_download_sync_secondary_timestamps` is `true`
- **AND** skip-mode recovery has a mix of pre-existing and newly downloaded subtitle files
- **AND** at least two subtitle tracks are present after recovery
- **AND** at least one of those tracks was newly downloaded in this run
- **THEN** sync SHALL run using an ordered list that includes both pre-existing and newly downloaded tracks
- **AND** the first language in configured subtitle order SHALL remain the deterministic primary track

#### Scenario: Skip recovery with no newly downloaded subtitles
- **WHEN** skip-mode recovery runs and no subtitle file was downloaded in this run (e.g. only companion audio was missing)
- **THEN** subtitle timestamp sync SHALL NOT run on the already-present, already-synced subtitle files

### Requirement: Companion Audio Language Matching
The companion-audio track selector SHALL support regional language tags and SHALL use the matched metadata language tag when constructing the yt-dlp format selector.

#### Scenario: Configured base code matches regional metadata code
- **WHEN** `youtube_download_companion_audio_languages` contains a base code (for example `ru`)
- **AND** YouTube metadata exposes a matching dubbed track under a regional tag (for example `ru-RU`)
- **THEN** the system SHALL treat the track as a valid match
- **AND** the yt-dlp `-f` selector SHALL use the actual matched metadata tag (`ru-RU`) rather than the base configured code

### Requirement: Companion Audio Stream Fallback Strategy
Companion-audio download SHALL prioritize dubbed language correctness over strict container purity, because some dubbed tracks are only exposed by YouTube as combined video+audio streams.

#### Scenario: Only combined streams exist for requested dubbed language
- **WHEN** a requested companion language exists in metadata
- **AND** no audio-only stream is available for that language
- **AND** one or more combined streams with that language tag are available
- **THEN** the system SHALL still download the dubbed companion track using the matched metadata language tag
- **AND** the system SHALL not skip the language solely because `vcodec != "none"`

#### Scenario: Best-effort post-download audio extraction
- **WHEN** a companion file has been downloaded
- **THEN** the system MAY attempt to strip video (`ffmpeg -vn -c:a copy`) to minimize disk use
- **AND** if extraction fails or `ffmpeg` is unavailable, the download SHALL still be considered successful

### Requirement: Pip-Style Output and Fallback Log Accuracy
Progress rendering and fallback diagnostics SHALL remain accurate across TTY and non-TTY execution contexts.

TTY detection SHALL be performed once at module import time and cached in a module-level `_IS_TTY` constant. All downstream branching on TTY-versus-non-TTY behavior (including ANSI escape emission, in-place line redraw, the pause-console countdown, and the streaming subprocess wrapper's per-pipe handling) SHALL consult the cached constant, and SHALL NOT call `sys.stdout.isatty()` again at the hot path.

The line-clearing helper SHALL accept a `width` parameter (default 65) and SHALL be used uniformly across the module for every in-place line clear, including the pause-console countdown clear path. Inline ad-hoc `"\r" + " " * N + "\r"` snippets SHALL NOT be used.

Counter brackets in cue/queue progress lines (e.g. `[3/10]`, `[3/150]`) SHALL be wrapped in dim grey ANSI styling to match the project's premium pip-style aesthetic.

#### Scenario: Non-TTY progress output
- **WHEN** progress text is rendered while stdout is not a TTY
- **THEN** progress lines SHALL not contain raw ANSI escape sequences
- **AND** the textual progress information SHALL remain readable in plain logs

#### Scenario: Original-language fallback with no subtitle tracks
- **WHEN** `youtube_download_subtitle_languages` is `"original"`
- **AND** language detection fails
- **AND** neither manual subtitles nor automatic captions are present in metadata
- **THEN** the system SHALL NOT log that it fell back to all subtitles
- **AND** the system SHALL NOT log that it fell back to all auto-subtitles

#### Scenario: Cached TTY constant is the single source of truth
- **WHEN** the module is loaded
- **THEN** `_IS_TTY` SHALL be set exactly once via `sys.stdout.isatty()`
- **AND** the streaming subprocess wrapper's per-pipe branching SHALL use `_IS_TTY` rather than calling `sys.stdout.isatty()` again
- **AND** the pause-console countdown SHALL gate its TTY-only countdown logic on `_IS_TTY` rather than calling `sys.stdout.isatty()` again

#### Scenario: Parameterized line clearing helper
- **WHEN** any code path needs to clear the current console line
- **THEN** it SHALL call the `clear_line(width=...)` helper
- **AND** SHALL NOT emit ad-hoc whitespace-padded carriage returns
- **AND** the helper SHALL emit the standard ANSI `\x1b[K` "erase to end of line" escape followed by `width`-column whitespace padding as a legacy fallback

### Requirement: Unstable Connection Resilience
The downloader SHALL tolerate transient network failures on both metadata and media fetch paths without adding external runtime dependencies.

#### Scenario: Resilience flags are applied to yt-dlp commands
- **WHEN** the downloader launches yt-dlp for metadata, subtitle, video, or companion-audio operations
- **THEN** it SHALL pass `--socket-timeout`, `--retries`, `--fragment-retries`, and `--retry-sleep`
- **AND** values SHALL come from configuration defaults when unset or invalid

#### Scenario: Metadata fetch uses outer retry and timeout
- **WHEN** `yt-dlp --dump-json` fails or times out due to unstable connectivity
- **THEN** the downloader SHALL retry with exponential backoff using the configured max attempts
- **AND** cookie-enabled metadata fetch SHALL retry once more without cookies when cookie loading fails

#### Scenario: Stalled streaming download process is recovered
- **WHEN** a running yt-dlp download process produces no output for the watchdog threshold
- **THEN** the process SHALL be terminated
- **AND** the outer retry loop SHALL relaunch the same command

#### Scenario: Retry preserves partial progress
- **WHEN** a download attempt is interrupted and then relaunched
- **THEN** yt-dlp partial files (`.part`) SHALL be reused so progress resumes instead of restarting from zero

