# YouTube Downloader Integration

A premium Windows "Send to" integration for downloading YouTube videos at configurable resolution, with chapters and subtitle files. It is designed to integrate seamlessly into your language acquisition workflow.

## Features

- **Windows "Send to" Integration:** Right-click files/directories containing YouTube URLs and download them automatically.
- **ZID-Based Filename Generation:** Unique, traceable Zettelkasten filenames (`{ZID}-{sanitized-title}.mp4`) based on the `zid_name.py` naming convention.
- **Queue Order Processing:** Process files and directories in strict order (file by file, and links in each file).
- **Flexible Chapters Support:**
  - `embedded`: Chapters embedded directly in the MP4 (default).
  - `separate`: Chapters saved as a separate `{ZID}-{title}.chapters.txt` file.
  - `both`: Both embedded and saved to a separate file.
- **Automatic Subtitles Fetching:**
  - `original`: Automatically detects the video's language and downloads SRT subtitle files.
  - Specific BCP-47 languages support (e.g., `en,de,ru`).
  - Auto-generated subtitles fallback if manual ones are unavailable.
- **Enforced MP4 Container:** Seamless remuxing to MP4 container via yt-dlp without re-encoding.
- **Companion Audio Track Download:**
  Download dubbed audio tracks as audio-only MP4 files alongside the main video. mpv auto-loads them as switchable audio tracks (hotkey `1`). Only genuine dubbed tracks are downloaded — default audio is never duplicated.
- **Duplicate File Handling:**
  - `zid-dir`: Places all duplicate files in a subfolder named after the session ZID.
  - `skip`: Skips duplicate downloads. When a video already exists, missing companion audio or subtitle files are recovered automatically.
  - `overwrite`: Replaces existing files.

## Installation

1. Make sure you have python in your Windows `PATH`.
2. Open a terminal (PowerShell or Command Prompt) in this directory and run:
   ```bash
   python install.py
   ```
   This will install a shortcut named `Kardenwort YouTube Downloader` in your Windows `Send to` menu.

## Configuration

You can customize downloader settings by editing `config.ini` in this directory.

Available configuration options:
- `youtube_download_resolution`: E.g., `360p`, `720p`, `1080p`, or `best` (default: `360p`).
- `youtube_download_directory`: Custom output folder path (defaults to `%USERPROFILE%\Videos` if empty).
- `youtube_download_mode`: `video+subtitles` (default), `video`, or `subtitles`.
- `youtube_download_duplicate_mode`: `zid-dir` (default), `skip`, or `overwrite`.
- `youtube_download_subtitle_languages`: `original` (default) or a comma-separated list of BCP-47 codes (e.g. `original,ru`).
- `youtube_download_subtitle_auto_fallback`: `true` (default) or `false`.
- `youtube_download_auto_update`: `true` (default) or `false` (automatically updates yt-dlp before downloads).
- `youtube_download_chapters_mode`: `embedded` (default), `separate`, or `both`.
- `youtube_download_cookies_browser`: Extracted browser cookies (e.g. `chrome`, `firefox`, `edge`, `brave`, `safari`) to bypass YouTube's strict rate-limiting and HTTP 429 errors (default: empty/disabled). Note: Chrome on Windows 11 uses DPAPI App-Bound encryption which may block direct extraction.
- `youtube_download_cookies_file`: The path to a Netscape/Mozilla formatted cookies text file (e.g., exported via a browser extension) to provide cookie credentials without locks or DPAPI errors (default: empty/disabled).

**SRT Subtitle Post-Processing** (applied after deduplication, in this order):

- `youtube_download_clean_hyphens`: `true` or `false` (default). When enabled, strips leading `-`, `–`, `—` characters and any following spaces from each subtitle text line. Useful for dialogue-formatted subtitles.
- `youtube_download_unbreak_lines`: `true` or `false` (default). When enabled, joins multi-line subtitle blocks into a single line per block. Word-hyphenation breaks (e.g. `hyphen-\nnation`) are rejoined into one word. Use together with `youtube_download_hyphenation_marks` and `youtube_download_compositional_conjunctions`.
- `youtube_download_hyphenation_marks`: Characters treated as word-hyphenation marks (default: `-¬`). Used by `unbreak_lines`.
- `youtube_download_compositional_conjunctions`: Comma-separated list of conjunctions that preserve compositional hyphens when unbreaking (default: `und,oder,sowie,bzw,bis` for German). Used by `unbreak_lines`.
- `youtube_download_fix_sentence_splits`: `true` or `false` (default). When enabled, fixes a common YouTube auto-translation artifact where a sentence's closing punctuation appears as the first character of the next subtitle block (e.g. `. Next sentence`) or as a standalone punctuation-only block (e.g. `.`). These are merged back onto the previous block.

**Secondary Subtitle Timestamp Synchronization:**

- `youtube_download_sync_secondary_timestamps`: `true` or `false` (default). When enabled and multiple subtitle tracks are downloaded (e.g. `original,ru`), re-timestamps all secondary tracks to match the primary track's timing using time-based nearest-neighbour matching. This corrects the inherent timestamp drift between independently auto-generated YouTube subtitle tracks so that A/D navigation in mpv stays in sync across languages.

**Companion Audio Tracks:**

- `youtube_download_companion_audio_languages`: Comma-separated BCP-47 language codes (e.g. `en,ru`), or leave empty to disable (default: empty). When a YouTube video has dubbed audio tracks in the specified languages, each is downloaded as `{ZID}-{title}.{lang}.mp4` (e.g. `20260527181921-google-bans-coding-with.ru.mp4`) next to the main video. mpv auto-loads them as external audio tracks, and hotkey `1` cycles between them while the video view is preserved. Track detection is metadata-driven and region-aware (`ru` matches `ru-RU`), and the yt-dlp selector uses the matched metadata tag. If YouTube provides only combined video+audio streams for a dubbed language, those are allowed as a deliberate fallback; after download, the script attempts `ffmpeg -vn -c:a copy` to strip video and keep an audio-only companion when possible. If no dubbed track exists, the language is skipped without wasting bandwidth. In `duplicate_mode = skip`, if a video already exists but a companion audio file is missing, it is downloaded automatically on re-run.

## CLI Usage

You can also run the downloader directly from the command line:
```bash
# Download a single URL
python youtube_downloader.py https://www.youtube.com/watch?v=dQw4w9WgXcQ

# Batch download URLs from a file
python youtube_downloader.py my_links.tsv

# Scan and download from all files in a directory
python youtube_downloader.py C:\my-sources-folder
```
