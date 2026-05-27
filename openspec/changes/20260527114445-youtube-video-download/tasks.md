## 1. Project Setup

- [ ] 1.1 Create `scripts/_tools/youtube-downloader/` directory structure
- [ ] 1.2 Add `__init__.py` to make it a Python package
- [ ] 1.3 Create `youtube_downloader.py` main script
- [ ] 1.4 Create `requirements.txt` listing `yt-dlp` as the sole dependency

## 2. Configuration

- [ ] 2.1 Add `youtube_download_resolution` configuration option (default: "360p")
- [ ] 2.2 Add `youtube_download_directory` configuration option (default: user's Videos folder)
- [ ] 2.3 Add `youtube_download_mode` configuration option (default: "video+subtitles") — controls what is fetched: "video+subtitles", "video", or "subtitles"
- [ ] 2.4 Add `youtube_download_duplicate_mode` configuration option (default: "zid-dir") — controls existing file handling: "zid-dir", "skip", or "overwrite"
- [ ] 2.5 Add `youtube_download_subtitle_languages` configuration option (default: "original") — "original" resolves to detected video language; comma-separated BCP-47 codes otherwise
- [ ] 2.6 Add `youtube_download_subtitle_auto_fallback` configuration option (default: true)
- [ ] 2.7 Add `youtube_download_auto_update` configuration option (default: true)
- [ ] 2.8 Add `youtube_download_chapters_mode` configuration option (default: "embedded")
- [ ] 2.9 Update `mpv.conf` with commented examples for YouTube download settings

## 3. YouTube URL Detection

- [ ] 3.1 Implement YouTube URL regex pattern matching
- [ ] 3.2 Support youtube.com URL format
- [ ] 3.3 Support youtu.be short URL format
- [ ] 3.4 Implement file reading and URL extraction
- [ ] 3.5 Add error handling for files with no YouTube URLs
- [ ] 3.6 Implement directory processing (search for files containing URLs)
- [ ] 3.7 Implement queue order processing (file by file, then links within each file)
- [ ] 3.8 Add error handling for directories with no files containing URLs

## 4. yt-dlp Backend Implementation

- [ ] 4.1 Implement yt-dlp backend integration
- [ ] 4.2 Add yt-dlp availability checking
- [ ] 4.3 Add yt-dlp installation instructions in error messages
- [ ] 4.4 Implement yt-dlp initial auto-install via `pip install yt-dlp` when not present and `youtube_download_auto_update` is true
- [ ] 4.5 Implement yt-dlp auto-update check before downloads (when already installed)
- [ ] 4.6 Implement yt-dlp update installation when updates are available
- [ ] 4.7 Add error handling for update/install check failures

## 5. Download Functionality

- [ ] 5.1 Implement video download with resolution selection
- [ ] 5.2 Implement resolution fallback when requested resolution is unavailable
- [ ] 5.3 Implement directory creation if target directory doesn't exist
- [ ] 5.4 Implement directory write permission checking
- [ ] 5.5 Implement `youtube_download_duplicate_mode` handling: "skip" → log and skip; "overwrite" → replace; "zid-dir" → create `{session-ZID}/` subfolder and place file inside
- [ ] 5.6 Add download progress tracking and display
- [ ] 5.7 Implement ZID-based filename generation (same convention as `zid_name.py`)
- [ ] 5.8 Implement unique ZID generation for each download
- [ ] 5.9 Implement ZID collision guard: track used ZIDs in session set; sleep 1s and retry on collision
- [ ] 5.9a Implement session `zid_cache` dict (initialized once per "Send to" invocation, shared across all URLs) for use by `youtube_download_duplicate_mode = "zid-dir"` — mirrors sub-tts pattern
- [ ] 5.10 Implement video title extraction from YouTube metadata
- [ ] 5.11 Implement title sanitization using `zid_name.py` rules
- [ ] 5.12 Format filename as `{ZID}-{sanitized-title}.mp4`
- [ ] 5.13 Enforce MP4 container via `--merge-output-format mp4` (remux without re-encoding)

## 6. Chapter and Subtitle Download

- [ ] 6.1 Implement chapter metadata embedding in downloaded videos (when `youtube_download_chapters_mode` is "embedded" or "both")
- [ ] 6.2 Implement chapter metadata saving to separate file (when `youtube_download_chapters_mode` is "separate" or "both")
- [ ] 6.3 Implement chapter file naming with `.chapters.txt` suffix
- [ ] 6.4 Implement chapter file format with titles and timestamps
- [ ] 6.5 Implement download mode routing: "video" → skip all subtitle logic; "subtitles" → skip video download, subtitles only; "video+subtitles" → both
- [ ] 6.6 Implement subtitle language selection: for "original" fetch `language` field from `yt-dlp --dump-json`; fall back to all manual tracks if absent; for comma-separated list use directly as BCP-47 codes
- [ ] 6.7 Implement SRT format conversion via `--convert-subs srt` (yt-dlp native conversion from vtt/srv3)
- [ ] 6.8 Implement auto-subtitle fallback when no manual subtitles available
- [ ] 6.9 Implement subtitle file naming with same ZID and name as video, with language code postfix
- [ ] 6.10 Add handling for videos without subtitles
- [ ] 6.11 Add error handling for subtitle download failures

## 7. Windows "Send to" Integration

- [ ] 7.1 Create Windows batch script or PowerShell script for "Send to" integration
- [ ] 7.2 Create `install_send_to.ps1` setup script that places the shortcut in `%APPDATA%\Microsoft\Windows\SendTo\`
- [ ] 7.3 Create shortcut in Windows "Send to" folder (done by install script above)
- [ ] 7.4 Test "Send to" integration with single file
- [ ] 7.5 Test "Send to" integration with multiple files
- [ ] 7.6 Test "Send to" integration with directory containing files with URLs
- [ ] 7.7 Test queue order processing (file by file, then links within each file)

## 8. Error Handling and Logging

- [ ] 8.1 Implement error handling for download failures
- [ ] 8.2 Implement error handling for missing yt-dlp
- [ ] 8.3 Implement error handling for network issues
- [ ] 8.4 Add logging for download operations
- [ ] 8.5 Add user-friendly error messages

## 9. Documentation

- [ ] 9.1 Create README for youtube-downloader tool
- [ ] 9.2 Document configuration options
- [ ] 9.3 Document "Send to" integration setup
- [ ] 9.4 Document yt-dlp requirements and installation
- [ ] 9.5 Add usage examples

## 10. Testing

- [ ] 10.1 Add acceptance test for YouTube URL detection
- [ ] 10.2 Add acceptance test for single URL download
- [ ] 10.3 Add acceptance test for multiple URL download
- [ ] 10.4 Add acceptance test for directory processing (multiple files with URLs)
- [ ] 10.5 Add acceptance test for queue order processing
- [ ] 10.6 Add acceptance test for resolution configuration
- [ ] 10.7 Add acceptance test for directory configuration
- [ ] 10.8 Add acceptance test for ZID-based filename generation
- [ ] 10.9 Add acceptance test for unique ZID generation
- [ ] 10.10 Add acceptance test for title sanitization
- [ ] 10.11 Add acceptance test for chapter metadata download (embedded mode)
- [ ] 10.12 Add acceptance test for chapter metadata download (separate mode)
- [ ] 10.13 Add acceptance test for chapter metadata download (both mode)
- [ ] 10.14 Add acceptance test for subtitle download (original language)
- [ ] 10.15 Add acceptance test for subtitle download (specific languages)
- [ ] 10.16 Add acceptance test for subtitle download (auto-subtitle fallback)
- [ ] 10.17 Add acceptance test for `youtube_download_duplicate_mode = "skip"` (file skipped when exists)
- [ ] 10.17a Add acceptance test for `youtube_download_duplicate_mode = "overwrite"` (file replaced when exists)
- [ ] 10.17b Add acceptance test for `youtube_download_duplicate_mode = "zid-dir"` (duplicate placed in session ZID subfolder)
- [ ] 10.17c Add acceptance test for multiple duplicates in one session sharing the same ZID subfolder
- [ ] 10.18 Add acceptance test for error scenarios (no URL, missing yt-dlp, etc.)
- [ ] 10.19 Add acceptance test for yt-dlp auto-update functionality
- [ ] 10.20 Add acceptance test for yt-dlp initial auto-install when not present
- [ ] 10.21 Add acceptance test for ZID collision guard (two downloads within same second)
- [ ] 10.22 Add acceptance test for MP4 container enforcement (output is always .mp4)
- [ ] 10.23 Add acceptance test for `youtube_download_mode = "video"` (no subtitle files created)
- [ ] 10.23a Add acceptance test for `youtube_download_mode = "video+subtitles"` (video and subtitle files created)
- [ ] 10.23b Add acceptance test for `youtube_download_mode = "subtitles"` (only subtitle files created, no video)
- [ ] 10.24 Add acceptance test for "original" language resolution from metadata
- [ ] 10.25 Add acceptance test for "original" language fallback when metadata `language` field absent
- [ ] 10.26 Add acceptance test for SRT format output (subtitle files end with .srt)

## 11. Integration and Polish

- [ ] 11.1 Test integration with existing TSV workflow
- [ ] 11.2 Verify no interference with existing mpv functionality
- [ ] 11.3 Performance testing for large batches of downloads
- [ ] 11.4 Code review and cleanup