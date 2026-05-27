## 1. Project Setup

- [x] 1.1 Create `scripts/_tools/youtube-downloader/` directory structure
- [x] 1.2 Add `__init__.py` to make it a Python package
- [x] 1.3 Create `youtube_downloader.py` main script
- [x] 1.4 Create `requirements.txt` listing `yt-dlp` as the sole dependency

## 2. Configuration

- [x] 2.1 Add `youtube_download_resolution` configuration option (default: "360p")
- [x] 2.2 Add `youtube_download_directory` configuration option (default: user's Videos folder)
- [x] 2.3 Add `youtube_download_mode` configuration option (default: "video+subtitles") — controls what is fetched: "video+subtitles", "video", or "subtitles"
- [x] 2.4 Add `youtube_download_duplicate_mode` configuration option (default: "zid-dir") — controls existing file handling: "zid-dir", "skip", or "overwrite"
- [x] 2.5 Add `youtube_download_subtitle_languages` configuration option (default: "original") — "original" resolves to detected video language; comma-separated BCP-47 codes otherwise
- [x] 2.6 Add `youtube_download_subtitle_auto_fallback` configuration option (default: true)
- [x] 2.7 Add `youtube_download_auto_update` configuration option (default: true)
- [x] 2.8 Add `youtube_download_chapters_mode` configuration option (default: "embedded")
- [x] 2.9 Update `mpv.conf` with commented examples for YouTube download settings

## 3. YouTube URL Detection

- [x] 3.1 Implement YouTube URL regex pattern matching
- [x] 3.2 Support youtube.com URL format
- [x] 3.3 Support youtu.be short URL format
- [x] 3.4 Implement file reading and URL extraction
- [x] 3.5 Add error handling for files with no YouTube URLs
- [x] 3.6 Implement directory processing (search for files containing URLs)
- [x] 3.7 Implement queue order processing (file by file, then links within each file)
- [x] 3.8 Add error handling for directories with no files containing URLs

## 4. yt-dlp Backend Implementation

- [x] 4.1 Implement yt-dlp backend integration
- [x] 4.2 Add yt-dlp availability checking
- [x] 4.3 Add yt-dlp installation instructions in error messages
- [x] 4.4 Implement yt-dlp initial auto-install via `pip install yt-dlp` when not present and `youtube_download_auto_update` is true
- [x] 4.5 Implement yt-dlp auto-update check before downloads (when already installed)
- [x] 4.6 Implement yt-dlp update installation when updates are available
- [x] 4.7 Add error handling for update/install check failures

## 5. Download Functionality

- [x] 5.1 Implement video download with resolution selection
- [x] 5.2 Implement resolution fallback when requested resolution is unavailable
- [x] 5.3 Implement directory creation if target directory doesn't exist
- [x] 5.4 Implement directory write permission checking
- [x] 5.5 Implement `youtube_download_duplicate_mode` handling: "skip" → log and skip; "overwrite" → replace; "zid-dir" → create `{session-ZID}/` subfolder and place file inside
- [x] 5.6 Add download progress tracking and display
- [x] 5.7 Implement ZID-based filename generation (same convention as `zid_name.py`)
- [x] 5.8 Implement unique ZID generation for each download
- [x] 5.9 Implement ZID collision guard: track used ZIDs in session set; sleep 1s and retry on collision
- [x] 5.9a Implement session `zid_cache` dict (initialized once per "Send to" invocation, shared across all URLs) for use by `youtube_download_duplicate_mode = "zid-dir"` — mirrors sub-tts pattern
- [x] 5.10 Implement video title extraction from YouTube metadata
- [x] 5.11 Implement title sanitization using `zid_name.py` rules
- [x] 5.12 Format filename as `{ZID}-{sanitized-title}.mp4`
- [x] 5.13 Enforce MP4 container via `--merge-output-format mp4` (remux without re-encoding)

## 6. Chapter and Subtitle Download

- [x] 6.1 Implement chapter metadata embedding in downloaded videos (when `youtube_download_chapters_mode` is "embedded" or "both")
- [x] 6.2 Implement chapter metadata saving to separate file (when `youtube_download_chapters_mode` is "separate" or "both")
- [x] 6.3 Implement chapter file naming with `.chapters.txt` suffix
- [x] 6.4 Implement chapter file format with titles and timestamps
- [x] 6.5 Implement download mode routing: "video" → skip all subtitle logic; "subtitles" → skip video download, subtitles only; "video+subtitles" → both
- [x] 6.6 Implement subtitle language selection: for "original" fetch `language` field from `yt-dlp --dump-json`; fall back to all manual tracks if absent; for comma-separated list use directly as BCP-47 codes
- [x] 6.7 Implement SRT format conversion via `--convert-subs srt` (yt-dlp native conversion from vtt/srv3)
- [x] 6.8 Implement auto-subtitle fallback when no manual subtitles available
- [x] 6.9 Implement subtitle file naming with same ZID and name as video, with language code postfix
- [x] 6.10 Add handling for videos without subtitles
- [x] 6.11 Add error handling for subtitle download failures

## 7. Windows "Send to" Integration

- [x] 7.1 Create Windows batch script or PowerShell script for "Send to" integration
- [x] 7.2 Create `install.py` setup script that places the shortcut in `%APPDATA%\Microsoft\Windows\SendTo\`
- [x] 7.3 Create shortcut in Windows "Send to" folder (done by install script above)
- [x] 7.4 Test "Send to" integration with single file
- [x] 7.5 Test "Send to" integration with multiple files
- [x] 7.6 Test "Send to" integration with directory containing files with URLs
- [x] 7.7 Test queue order processing (file by file, then links within each file)

## 8. Error Handling and Logging

- [x] 8.1 Implement error handling for download failures
- [x] 8.2 Implement error handling for missing yt-dlp
- [x] 8.3 Implement error handling for network issues
- [x] 8.4 Add logging for download operations
- [x] 8.5 Add user-friendly error messages

## 9. Documentation

- [x] 9.1 Create README for youtube-downloader tool
- [x] 9.2 Document configuration options
- [x] 9.3 Document "Send to" integration setup
- [x] 9.4 Document yt-dlp requirements and installation
- [x] 9.5 Add usage examples

## 10. Testing

- [x] 10.1 Add acceptance test for YouTube URL detection
- [x] 10.2 Add acceptance test for single URL download
- [x] 10.3 Add acceptance test for multiple URL download
- [x] 10.4 Add acceptance test for directory processing (multiple files with URLs)
- [x] 10.5 Add acceptance test for queue order processing
- [x] 10.6 Add acceptance test for resolution configuration
- [x] 10.7 Add acceptance test for directory configuration
- [x] 10.8 Add acceptance test for ZID-based filename generation
- [x] 10.9 Add acceptance test for unique ZID generation
- [x] 10.10 Add acceptance test for title sanitization
- [x] 10.11 Add acceptance test for chapter metadata download (embedded mode)
- [x] 10.12 Add acceptance test for chapter metadata download (separate mode)
- [x] 10.13 Add acceptance test for chapter metadata download (both mode)
- [x] 10.14 Add acceptance test for subtitle download (original language)
- [x] 10.15 Add acceptance test for subtitle download (specific languages)
- [x] 10.16 Add acceptance test for subtitle download (auto-subtitle fallback)
- [x] 10.17 Add acceptance test for `youtube_download_duplicate_mode = "skip"` (file skipped when exists)
- [x] 10.17a Add acceptance test for `youtube_download_duplicate_mode = "overwrite"` (file replaced when exists)
- [x] 10.17b Add acceptance test for `youtube_download_duplicate_mode = "zid-dir"` (duplicate placed in session ZID subfolder)
- [x] 10.17c Add acceptance test for multiple duplicates in one session sharing the same ZID subfolder
- [x] 10.18 Add acceptance test for error scenarios (no URL, missing yt-dlp, etc.)
- [x] 10.19 Add acceptance test for yt-dlp auto-update functionality
- [x] 10.20 Add acceptance test for yt-dlp initial auto-install when not present
- [x] 10.21 Add acceptance test for ZID collision guard (two downloads within same second)
- [x] 10.22 Add acceptance test for MP4 container enforcement (output is always .mp4)
- [x] 10.23 Add acceptance test for `youtube_download_mode = "video"` (no subtitle files created)
- [x] 10.23a Add acceptance test for `youtube_download_mode = "video+subtitles"` (video and subtitle files created)
- [x] 10.23b Add acceptance test for `youtube_download_mode = "subtitles"` (only subtitle files created, no video)
- [x] 10.24 Add acceptance test for "original" language resolution from metadata
- [x] 10.25 Add acceptance test for "original" language fallback when metadata `language` field absent
- [x] 10.26 Add acceptance test for SRT format output (subtitle files end with .srt)

## 11. Integration and Polish

- [x] 11.1 Test integration with existing TSV workflow
- [x] 11.2 Verify no interference with existing mpv functionality
- [x] 11.3 Performance testing for large batches of downloads
- [x] 11.4 Code review and cleanup

## 12. SRT Subtitle Post-Processing (ZID: 20260527182908)

- [x] 12.1 Add `youtube_download_clean_hyphens` configuration option (default: false) — strips leading dashes from subtitle lines
- [x] 12.2 Add `youtube_download_unbreak_lines` configuration option (default: false) — joins multi-line subtitle blocks into a single line
- [x] 12.3 Add `youtube_download_hyphenation_marks` configuration option — characters treated as word-hyphenation marks (default: `-¬`)
- [x] 12.4 Add `youtube_download_compositional_conjunctions` configuration option — conjunctions that preserve trailing hyphens when unbreaking (default: `und,oder,sowie,bzw,bis`)
- [x] 12.5 Implement `clean_hyphens` pass in `clean_srt_file`: strip leading `-`, `–`, `—` and following spaces from each text line
- [x] 12.6 Implement `unbreak_lines` pass in `clean_srt_file`: join multiple lines per block; handle word-hyphenation breaks; preserve compositional hyphens before conjunctions
- [x] 12.7 Add `youtube_download_fix_sentence_splits` configuration option (default: false) — merges punctuation-only and leading-punctuation blocks back onto the previous block
- [x] 12.8 Implement `fix_sentence_splits` post-deduplication pass in `clean_srt_file`
- [x] 12.9 Add unit tests: `test_clean_srt_file_clean_hyphens`, `test_clean_srt_file_unbreak_lines`, `test_clean_srt_file_both`, `test_clean_srt_file_fix_sentence_splits`, `test_clean_srt_file_fix_sentence_splits_disabled`, `test_clean_srt_file_fix_sentence_splits_with_unbreak`
- [x] 12.10 Update README and config.ini.template with new settings

## 13. Secondary Subtitle Timestamp Synchronization (ZID: 20260527182908)

- [x] 13.1 Add `youtube_download_sync_secondary_timestamps` configuration option (default: false)
- [x] 13.2 Implement `sync_secondary_srt_timestamps(primary_path, secondary_path)` function: time-based nearest-neighbour matching using binary search; monotonic forward progress; preserves secondary text unchanged
- [x] 13.3 Integrate sync into the download pipeline: after all tracks are cleaned, if enabled and ≥2 subtitle files were written, apply sync with first track as primary
- [x] 13.4 Add unit tests: `test_sync_secondary_srt_timestamps`, `test_sync_secondary_srt_timestamps_different_counts`, `test_sync_secondary_srt_timestamps_missing_file`, `test_sync_secondary_srt_timestamps_missing_primary`
- [x] 13.5 Update README and config.ini.template with the new setting

## 14. Companion Audio Track Download (ZID: 20260527184334)

Companion audio files are language-dubbed audio-only `.mp4` files sitting alongside the main video, named `{ZID}-{title}.{lang}.mp4`. mpv's `ensure_companion_audio_tracks` auto-loads them as switchable audio tracks (hotkey `1`). The feature mirrors the subtitle language logic: a comma-separated list of BCP-47 codes to download, empty string disables.

- [ ] 14.1 Add `youtube_download_companion_audio_languages` configuration option — comma-separated BCP-47 codes (e.g., `ru,de`); empty string disables companion audio download (default: `""`)
- [ ] 14.2 Update `load_config()` defaults dict to include `youtube_download_companion_audio_languages = ""` with no bool coercion (string passthrough, same as `youtube_download_subtitle_languages`)
- [ ] 14.3 Implement `download_companion_audio(url, zid, sanitized_title, target_dir, lang, info, settings)` function:
  - Use `-f "bestaudio[language={lang}]"` (no `/bestaudio` fallback) and `--merge-output-format mp4`; write to `{target_dir}/{zid}-{sanitized_title}.{lang}.mp4`
  - Before downloading, check `info` metadata: inspect `formats` list for an entry with `acodec != "none"`, `vcodec == "none"` (audio-only), and `language == lang`; if none found, log "No dubbed audio track for language '{lang}' — skipping companion audio" and return True (graceful skip, not an error)
  - This guard prevents downloading the default audio stream as a companion (which would waste disk space and produce a duplicate, not an alternate track)
  - Apply cookies options same as video/subtitle commands
  - The output is an MP4 container with one audio stream only (no video) — ~10× smaller than a full video file; mpv loads it via `audio-add` as an external audio track without affecting the video renderer
- [ ] 14.4 Integrate companion audio download into `download_video_and_metadata` pipeline: after subtitle download and before the summary block — for each language in `youtube_download_companion_audio_languages`, skip (log) if `{target_dir}/{zid}-{sanitized_title}.{lang}.mp4` already exists; otherwise call `download_companion_audio`; collect written companion paths for the summary
- [ ] 14.5 Extend `duplicate_mode = skip` missing-file check to include companion audio files: for each language in `youtube_download_companion_audio_languages`, check if `{old_zid}-{sanitized_title}.{lang}.mp4` is absent in `out_dir`; add missing entries to `missing_files`; the existing recovery path (override ZID + force `youtube_download_mode = subtitles`) already skips video re-download — extend it to also run the companion audio download step for missing tracks
- [ ] 14.6 Update `config.ini` and `config.ini.template` with `youtube_download_companion_audio_languages` option, a comment explaining the naming convention and mpv integration, and an example value
- [ ] 14.7 Update README with companion audio section: feature description, config option, naming convention, how mpv picks them up, and example workflow
- [ ] 14.8 Add acceptance tests: `test_companion_audio_download_single_lang`, `test_companion_audio_download_multi_lang`, `test_companion_audio_skip_existing`, `test_companion_audio_missing_recovery_in_skip_mode`, `test_companion_audio_disabled_when_empty`