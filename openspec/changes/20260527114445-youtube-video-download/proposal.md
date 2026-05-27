## Why

The current workflow for downloading YouTube videos for language learning involves multiple manual steps: copying YouTube URLs, opening external tools (newpipe, asbplayer, youtube-dl-gui, yt-dlp), and configuring download directories. This friction disrupts the language acquisition flow. Adding a "Send to" integration for files containing YouTube links would allow seamless video download directly from the TSV source file context, matching the user's existing tools (newpipe, asbplayer, youtube-dl-gui, yt-dlp) and configurable resolution settings.

## What Changes

- Add a "Send to" integration that processes files containing YouTube URLs
- Download videos at configurable resolution (set in config) to a specified directory
- Integrate with existing download tools: newpipe, asbplayer, youtube-dl-gui, yt-dlp
- Support TSV source file workflow where the YouTube link file is used as Source
- Maintain existing subtitle download workflow (user continues to use newpipe or asbplayer for subtitles)

## Capabilities

### New Capabilities
- `youtube-video-download`: Enables automated YouTube video download from files containing URLs via "Send to" integration
- `configurable-download-resolution`: Allows setting preferred video resolution in configuration
- `configurable-download-directory`: Allows setting target download directory in configuration

### Modified Capabilities
- None (this is a standalone integration feature)

## Impact

- **`scripts/_tools/`**: New download integration tool/script
- **`mpv.conf` / configuration**: New options for download resolution and directory settings
- **`docs/`**: Documentation for the new "Send to" workflow
- **Tests**: Acceptance tests for download integration functionality