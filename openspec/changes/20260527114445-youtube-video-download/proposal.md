## Why

The current workflow for downloading YouTube videos for language learning involves multiple manual steps: copying YouTube URLs, opening external tools (newpipe, asbplayer, youtube-dl-gui, yt-dlp), and configuring download directories. This friction disrupts the language acquisition flow. Adding a "Send to" integration for files containing YouTube links would allow seamless video download directly from the TSV source file context, matching the user's existing tools (newpipe, asbplayer, youtube-dl-gui, yt-dlp) and configurable resolution settings.

## What Changes

- Add a "Send to" integration that processes files and directories containing YouTube URLs
- Download videos at configurable resolution (set in config) to a specified directory
- Use yt-dlp as the download backend (best solution for console-based downloads with chapters and SRT subtitles)
- Support TSV source file workflow where the YouTube link file is used as Source
- Download videos with chapters and separately download SRT subtitle files
- Option to check and install yt-dlp updates before starting downloads
- Option to save chapters: embedded only, separate file only, or both (configurable)
- Generate unique ZID-based filenames using the same naming convention as `zid_name.py`
- Support directory processing: search for files with links and download each link in each file in queue order
- Configurable subtitle download: specify which languages to download (original, list of languages)
- Option to download auto-subtitles if no manual ones are available
- Subtitle naming: same ZID and name as video, differing only in language code postfix and .srt extension (separate files)

## Capabilities

### New Capabilities
- `youtube-video-download`: Enables automated YouTube video download from files/directories via "Send to" integration
- `configurable-download-resolution`: Allows setting preferred video resolution in configuration (default: 360p)
- `configurable-download-directory`: Allows setting target download directory in configuration
- `zid-based-naming`: Generates unique ZID-based filenames using video title (same convention as `zid_name.py`)
- `directory-processing`: Supports directory selection, searches for files with links, processes in queue order
- `chapter-support`: Downloads videos with chapter metadata
- `chapter-output-mode`: Configurable chapter output: embedded, separate, or both
- `subtitle-download`: Automatically downloads SRT subtitle files separately
- `subtitle-language-selection`: Configurable which subtitle languages to download (original, list)
- `subtitle-auto-fallback`: Option to download auto-subtitles if no manual ones available
- `subtitle-zid-naming`: Subtitles use same ZID and name as video, with language code postfix
- `auto-update-ytdlp`: Allows checking and installing yt-dlp updates before downloads

### Modified Capabilities
- None (this is a standalone integration feature)

## Impact

- **`scripts/_tools/`**: New download integration tool/script
- **`scripts/_tools/youtube-downloader/config.ini`**: New downloader options (resolution, directory, duplicate handling, subtitles, chapters, companion audio, and post-processing)
- **`docs/`**: Documentation for the new "Send to" workflow
- **Tests**: Unit tests with mocked yt-dlp and manual verification checkpoints (no full end-to-end network acceptance suite in CI)
