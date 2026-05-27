## Context

The user currently downloads YouTube videos for language learning using external tools (newpipe, asbplayer, youtube-dl-gui, yt-dlp). The workflow involves manually copying YouTube URLs from TSV source files and configuring download parameters. This creates friction in the language acquisition workflow. The user wants a "Send to" integration that can process files containing YouTube URLs and automatically download videos at a configurable resolution to a specified directory.

## Goals / Non-Goals

**Goals:**
- Create a "Send to" integration that processes files containing YouTube URLs
- Download videos at configurable resolution (set in config)
- Use yt-dlp as the sole download backend (best solution for console-based downloads)
- Download videos with chapter metadata
- Automatically download SRT subtitle files separately
- Allow configuration of target download directory
- Integrate seamlessly with existing TSV source file workflow

**Non-Goals:**
- Supporting multiple download backends (yt-dlp is sufficient)
- Creating a new video player interface
- Modifying existing mpv playback functionality
- Implementing video transcoding or format conversion

## Decisions

1. **Use Python for download integration**

   Python provides excellent libraries for YouTube download (yt-dlp) and Windows shell integration. The existing project already uses Python for tooling (zid.py, sub-tts, sub-viewer).

2. **Use yt-dlp as the sole download backend**

   yt-dlp is the best solution for console-based YouTube downloads with comprehensive support for:
   - Chapter metadata extraction and embedding
   - Subtitle download in multiple formats including SRT
   - Resolution selection and fallback
   - Robust error handling and retry logic
   - Active maintenance and frequent updates

3. **Configuration-driven resolution, directory, updates, and chapters**

   Add four new configuration options:
   - `youtube_download_resolution` (default: "1080p")
   - `youtube_download_directory` (default: user's Videos folder or project-specific directory)
   - `youtube_download_auto_update` (default: true) - Check and install yt-dlp updates before downloads
   - `youtube_download_chapters_mode` (default: "embedded") - Chapter output mode: "embedded", "separate", or "both"

4. **File-based "Send to" integration**

   Create a Windows shell integration that allows right-clicking on files containing YouTube URLs and selecting "Send to" → "Download YouTube Video". The script will:
   - Parse the file for YouTube URLs
   - Download videos using the configured backend
   - Save to the configured directory at the specified resolution

5. **Automatic subtitle and chapter download**

   The integration will automatically download:
   - SRT subtitle files separately (for each available language)
   - Chapter metadata (either embedded in the video file or saved to a separate file based on configuration)
   This eliminates the need for manual subtitle download via newpipe/asbplayer.

6. **Automatic yt-dlp updates**

   The integration will check for and install yt-dlp updates before starting downloads (configurable). This ensures compatibility with YouTube's frequent changes and provides the latest features and bug fixes.

7. **Minimal disruption to existing workflow**

   The integration should be optional and not interfere with existing mpv functionality.

## Risks / Trade-offs

- [Risk] YouTube URLs may change or videos may be deleted, causing download failures.
  - Mitigation: Provide clear error messages and logging for failed downloads.
- [Risk] Windows "Send to" integration requires registry modifications and may not work on all systems.
  - Mitigation: Provide alternative invocation methods (command-line, drag-and-drop) and clear setup instructions.
- [Risk] Downloading at high resolutions may consume significant bandwidth and storage.
  - Mitigation: Default to reasonable resolution (1080p) and allow user configuration.

## Migration Plan

1. Create Python download script in `scripts/_tools/youtube-downloader/`
2. Add configuration options to `mpv.conf` or a separate config file
3. Create Windows "Send to" integration script/shortcut
4. Add documentation for setup and usage
5. Add acceptance tests for download functionality
6. Update user-facing documentation

## Open Questions

- Should the integration support batch processing of multiple URLs in a single file? (Yes, for efficiency)
- Should there be a progress indicator for long downloads? (Yes, yt-dlp provides this)
- How should the integration handle videos that are already downloaded (skip or overwrite)? (Skip by default, configurable)