## Context

The user currently downloads YouTube videos for language learning using external tools (newpipe, asbplayer, youtube-dl-gui, yt-dlp). The workflow involves manually copying YouTube URLs from TSV source files and configuring download parameters. This creates friction in the language acquisition workflow. The user wants a "Send to" integration that can process files containing YouTube URLs and automatically download videos at a configurable resolution to a specified directory.

## Goals / Non-Goals

**Goals:**
- Create a "Send to" integration that processes files and directories containing YouTube URLs
- Download videos at configurable resolution (set in config)
- Use yt-dlp as the sole download backend (best solution for console-based downloads)
- Generate unique ZID-based filenames using video title (same convention as `zid_name.py`)
- Download videos with chapter metadata
- Automatically download SRT subtitle files separately
- Allow configuration of target download directory
- Support directory processing: search for files with links and process in queue order
- Integrate seamlessly with existing TSV source file workflow

**Non-Goals:**
- Supporting multiple download backends (yt-dlp is sufficient)
- Creating a new video player interface
- Modifying existing mpv playback functionality
- Re-encoding video or converting codecs (container remuxing to MP4 is done without re-encoding)

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

3. **Configuration-driven resolution, directory, updates, chapters, and subtitles**

   Add eight new configuration options:
   - `youtube_download_resolution` (default: "360p")
   - `youtube_download_directory` (default: user's Videos folder or project-specific directory)
   - `youtube_download_mode` (default: "video+subtitles") - What to download: "video+subtitles", "video", or "subtitles"
   - `youtube_download_duplicate_mode` (default: "zid-dir") - How to handle existing files: "zid-dir", "skip", or "overwrite"
   - `youtube_download_auto_update` (default: true) - Check and install yt-dlp updates before downloads
   - `youtube_download_chapters_mode` (default: "embedded") - Chapter output mode: "embedded", "separate", or "both"
   - `youtube_download_subtitle_languages` (default: "original") - Languages to download: "original" (video's detected language), or comma-separated BCP-47 codes (e.g., "en,de,ru")
   - `youtube_download_subtitle_auto_fallback` (default: true) - Download auto-subtitles if no manual ones available

4. **File and directory-based "Send to" integration**

   Create a Windows shell integration that allows right-clicking on files/directories and selecting "Send to" → "Download YouTube Video". The script will:
   - For files: Parse the file for YouTube URLs
   - For directories: Search for files containing YouTube URLs
   - Process URLs in queue order (file by file, then links within each file)
   - Generate unique ZID-based filenames using video title (same convention as `zid_name.py`)
   - Download videos using the configured backend
   - Save to the configured directory at the specified resolution

5. **Mode-driven download: video, subtitles, or both**

   `youtube_download_mode` controls exactly what yt-dlp fetches per URL:
   - `"video+subtitles"` (default): download the video file and SRT subtitle files
   - `"video"`: download the video file only; no subtitle operations are performed
   - `"subtitles"`: download SRT subtitle files only; no video is downloaded — useful when the video already exists locally

   When subtitles are included (`"video+subtitles"` or `"subtitles"`):
   - Language selection: "original" (detected from metadata) or comma-separated BCP-47 codes
   - Auto-subtitle fallback if no manual ones available (configurable)
   - Naming: `{ZID}-{name}.{lang}.srt` — same ZID and base name as the video
   - Chapter metadata: embedded or separate file based on `youtube_download_chapters_mode`
   This eliminates the need for manual subtitle download via newpipe/asbplayer.

6. **Automatic yt-dlp updates**

   The integration will check for and install yt-dlp updates before starting downloads (configurable). This ensures compatibility with YouTube's frequent changes and provides the latest features and bug fixes.

7. **ZID-based filename generation**

   The integration will generate unique ZID-based filenames for downloaded videos using the same naming convention as `zid_name.py`:
   - Generate a unique ZID (YYYYMMDDHHMMSS format) for each download
   - Extract video title from YouTube metadata
   - Apply `zid_name.py` sanitization rules to the title
   - Format: `{ZID}-{sanitized-title}.mp4`
   - This ensures unique, traceable filenames consistent with the user's Zettelkasten workflow

8. **Minimal disruption to existing workflow**

   The integration should be optional and not interfere with existing mpv functionality.

9. **Enforce MP4 container via remux (no re-encoding)**

   yt-dlp's best-quality format selection often produces `.webm` or `.mkv` containers. To guarantee the `{ZID}-{title}.mp4` filename convention and compatibility with the existing mpv workflow, always pass `--merge-output-format mp4` to yt-dlp. This remuxes the output into an MP4 container without re-encoding the video or audio streams.

10. **ZID uniqueness guarantee for batch downloads**

    ZIDs are second-precision timestamps (YYYYMMDDHHMMSS). When downloading multiple videos in a batch, multiple downloads could start within the same second and produce duplicate ZIDs. Strategy: maintain a set of ZIDs already assigned in the current session. Before assigning a ZID, check the set; if the ZID is already taken, sleep 1 second and generate a new one. This guarantees uniqueness within a session with minimal overhead.

11. **SRT subtitle format via yt-dlp conversion**

    yt-dlp downloads subtitles in the format provided by YouTube (`.vtt`, `.srv3`, etc.). To guarantee `.srt` output as specified in the subtitle naming convention, always pass `--convert-subs srt` to yt-dlp. This conversion is lossless for timing and text content.

12. **"original" subtitle language resolved via yt-dlp language detection**

    The `"original"` value for `youtube_download_subtitle_languages` maps to the video's detected audio/caption language as reported by the YouTube metadata. Implementation: fetch video info with `yt-dlp --dump-json`, read the `language` field, and use that language code as the subtitle language selector. If the `language` field is absent, fall back to downloading all available manual subtitles and picking the first one.

13. **Duplicate file handling via `youtube_download_duplicate_mode` — mirrors sub-tts pattern**

    When a target output file already exists, three modes are supported (same as `duplicate_mode` in `scripts/_tools/sub-tts/sub_tts.py`):
    - `"zid-dir"` (default): create a subdirectory named after the session ZID (`{session-ZID}/`) inside `youtube_download_directory` and place the file there. The session ZID is shared across all downloads in one "Send to" invocation via a `zid_cache` dict, so all duplicates from one session land in the same subfolder.
    - `"skip"`: log a skip message and move on to the next URL
    - `"overwrite"`: replace the existing file

    The `zid_cache` is initialized once per session (one "Send to" invocation) and reused across all URLs, exactly as in sub-tts `process_srt` / main loop.

## Architecture Review (Chief Architect Pass, ZID: 20260527204017)

**Verdict:** The solution direction is sound and cohesive (single backend, config-driven behavior, strong naming discipline, and good workflow fit), but two correctness gaps remain in the `skip` recovery branch and one language-matching gap in companion audio.

**Confirmed inconsistencies / false assumptions:**
- The current `skip` recovery still forces `youtube_download_mode = "subtitles"` unconditionally, which triggers unnecessary subtitle download attempts when only companion audio is missing.
- Existing subtitle files are post-processed again during `skip` recovery, which risks non-idempotent transformations (`fix_sentence_splits`) on already-cleaned tracks.
- Companion audio matching currently requires exact `language == lang`; this can miss valid tracks when metadata uses regional tags like `ru-RU` and config uses `ru`.
- Documentation drift: one config comment says longer subtitle tracks are "trimmed"; implementation/spec behavior preserves all secondary blocks and remaps timestamps.

**Design alignment decision:**
- Keep section 15 as mandatory stabilization work before considering this change implementation-complete.
- Treat the companion language normalization as part of the core matching contract, not a nice-to-have optimization.

## Risks / Trade-offs

- [Risk] YouTube URLs may change or videos may be deleted, causing download failures.
  - Mitigation: Provide clear error messages and logging for failed downloads.
- [Risk] Windows "Send to" integration requires registry modifications and may not work on all systems.
  - Mitigation: Provide alternative invocation methods (command-line, drag-and-drop) and clear setup instructions.
- [Risk] Downloading at high resolutions may consume significant bandwidth and storage.
  - Mitigation: Default to conservative resolution (360p) and allow user configuration.

## Migration Plan

1. Create Python download script in `scripts/_tools/youtube-downloader/`
2. Add configuration options to `scripts/_tools/youtube-downloader/config.ini`
3. Create Windows "Send to" integration script/shortcut
4. Add documentation for setup and usage
5. Add unit tests (mocked yt-dlp) and manual verification checkpoints for download functionality
6. Update user-facing documentation

## Open Questions

- None at design level. Remaining uncertainty is implementation-level and tracked in `tasks.md` section 15.
