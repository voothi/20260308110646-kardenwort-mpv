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
- **Duplicate File Handling:**
  - `zid-dir`: Places all duplicate files in a subfolder named after the session ZID.
  - `skip`: Skips duplicate downloads.
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
- `youtube_download_subtitle_languages`: `original` (default) or a comma-separated list of BCP-47 codes.
- `youtube_download_subtitle_auto_fallback`: `true` (default) or `false`.
- `youtube_download_auto_update`: `true` (default) or `false` (automatically updates yt-dlp before downloads).
- `youtube_download_chapters_mode`: `embedded` (default), `separate`, or `both`.
- `youtube_download_cookies_browser`: Extracted browser cookies (e.g. `chrome`, `firefox`, `edge`, `brave`, `safari`) to bypass YouTube's strict rate-limiting and HTTP 429 errors (default: empty/disabled).

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
