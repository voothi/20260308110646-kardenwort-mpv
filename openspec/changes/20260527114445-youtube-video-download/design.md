## Context

The user currently downloads YouTube videos for language learning using external tools (newpipe, asbplayer, youtube-dl-gui, yt-dlp). The workflow involves manually copying YouTube URLs from TSV source files and configuring download parameters. This creates friction in the language acquisition workflow. The user wants a "Send to" integration that can process files containing YouTube URLs and automatically download videos at a configurable resolution to a specified directory.

## Goals / Non-Goals

**Goals:**
- Create a "Send to" integration that processes files containing YouTube URLs
- Download videos at configurable resolution (set in config)
- Support multiple download backends: newpipe, asbplayer, youtube-dl-gui, yt-dlp
- Allow configuration of target download directory
- Integrate seamlessly with existing TSV source file workflow
- Maintain existing subtitle download workflow (user continues to use newpipe/asbplayer for subtitles)

**Non-Goals:**
- Implementing subtitle download functionality (user already handles this via newpipe/asbplayer)
- Creating a new video player interface
- Modifying existing mpv playback functionality
- Implementing video transcoding or format conversion

## Decisions

1. **Use Python for download integration**

   Python provides excellent libraries for YouTube download (yt-dlp) and Windows shell integration. The existing project already uses Python for tooling (zid.py, sub-tts, sub-viewer).

2. **Support multiple download backends**

   The user mentions four tools: newpipe, asbplayer, youtube-dl-gui, yt-dlp. The integration should support selecting which backend to use via configuration, with yt-dlp as the default since it's the most robust and actively maintained.

3. **Configuration-driven resolution and directory**

   Add two new configuration options:
   - `youtube_download_resolution` (default: "1080p")
   - `youtube_download_directory` (default: user's Videos folder or project-specific directory)

4. **File-based "Send to" integration**

   Create a Windows shell integration that allows right-clicking on files containing YouTube URLs and selecting "Send to" → "Download YouTube Video". The script will:
   - Parse the file for YouTube URLs
   - Download videos using the configured backend
   - Save to the configured directory at the specified resolution

5. **Minimal disruption to existing workflow**

   The integration should be optional and not interfere with existing mpv functionality. Subtitle download remains a separate manual process via newpipe/asbplayer as the user prefers.

## Risks / Trade-offs

- [Risk] YouTube URLs may change or videos may be deleted, causing download failures.
  - Mitigation: Provide clear error messages and logging for failed downloads.
- [Risk] Different download backends have different command-line interfaces and capabilities.
  - Mitigation: Implement a unified abstraction layer that handles backend-specific differences.
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

- Should the integration support batch processing of multiple URLs in a single file?
- Should there be a progress indicator for long downloads?
- How should the integration handle videos that are already downloaded (skip or overwrite)?