#!/usr/bin/env python
# ==============================================================================
# YouTube Video Downloader
# Downloads YouTube videos at configurable resolution, with chapters and subtitles.
#
# Usage (CLI):
#   python youtube_downloader.py https://www.youtube.com/watch?v=XXXXXX
#   python youtube_downloader.py urls.txt
#   python youtube_downloader.py u:\my-videos-dir
#
# Installation (Windows SendTo):
#   powershell -ExecutionPolicy Bypass -File install_send_to.ps1
# ==============================================================================

import argparse
import configparser
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

# ==============================================================================
# GLOBAL CONSTANTS & REGEX
# ==============================================================================
SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_FILE = SCRIPT_DIR / "config.ini"

# Match standard and short YouTube URLs
YOUTUBE_URL_REGEX = re.compile(
    r'(https?://(?:[a-zA-Z0-9_-]+\.)?youtube\.com/(?:watch\?v=|shorts/|embed/|v/)[a-zA-Z0-9_-]{11}|https?://youtu\.be/[a-zA-Z0-9_-]{11})'
)

# ==============================================================================
# CONFIGURATION LOADING (Tasks 2.1 – 2.8)
# ==============================================================================
def load_config():
    """Loads settings from config.ini, falling back to default values."""
    config = configparser.ConfigParser()
    defaults = {
        "youtube_download_resolution": "360p",
        "youtube_download_directory": "",
        "youtube_download_mode": "video+subtitles",
        "youtube_download_duplicate_mode": "zid-dir",
        "youtube_download_subtitle_languages": "original",
        "youtube_download_subtitle_auto_fallback": "true",
        "youtube_download_auto_update": "true",
        "youtube_download_chapters_mode": "embedded",
        "youtube_download_cookies_browser": "",
        "youtube_download_cookies_file": "",
    }

    if CONFIG_FILE.exists():
        try:
            config.read(CONFIG_FILE, encoding="utf-8")
        except Exception as e:
            print(f"Warning: Error reading config.ini: {e}. Using default settings.", file=sys.stderr)
    
    settings = {}
    for key, def_val in defaults.items():
        val = config.get("Settings", key, fallback=def_val).strip()
        # Handle booleans
        if def_val in ["true", "false"]:
            settings[key] = val.lower() in ["true", "yes", "1"]
        else:
            settings[key] = val

    # Resolve download directory
    if not settings["youtube_download_directory"]:
        settings["youtube_download_directory"] = os.path.join(os.environ.get("USERPROFILE", "C:\\"), "Videos")
    else:
        settings["youtube_download_directory"] = os.path.expandvars(settings["youtube_download_directory"])
        
    return settings

# ==============================================================================
# ZID GENERATION & SANITIZATION (Tasks 5.7 – 5.12)
# ==============================================================================
def get_current_zid():
    """Calls the system ZID script to retrieve the current anchor ZID, falling back to local time."""
    try:
        res = subprocess.run(
            ["python", "U:\\voothi\\20241116203211-zid\\zid.py", "--no-clipboard"],
            capture_output=True,
            text=True,
            check=True
        )
        return res.stdout.strip()
    except Exception:
        return time.strftime("%Y%m%d%H%M%S")

def get_unique_zid(used_zids):
    """Generates a unique ZID YYYYMMDDHHMMSS, sleeping 1s on collision."""
    while True:
        zid = time.strftime("%Y%m%d%H%M%S")
        if zid not in used_zids:
            used_zids.add(zid)
            return zid
        time.sleep(1)

def sanitize_title(title):
    """Sanitizes a video title according to zid_name.py rules."""
    replacements = {
        'ä': 'ae', 'ö': 'oe', 'ü': 'ue', 'ß': 'ss', 'ẞ': 'ss',
        'Ä': 'ae', 'Ö': 'oe', 'Ü': 'ue', '_': '-', ':': '-', '. ': '-', '.': '-'
    }
    processed = title
    for char, replacement in replacements.items():
        processed = processed.replace(char, replacement)
    
    # Filter allowed characters (letters, numbers, spaces, hyphens)
    processed = re.sub(r'[^a-zA-Zа-яА-ЯёЁ0-9\s-]', '', processed)
    
    # Split and limit to 4 words
    words = processed.split()
    first_words = words[:4]
    
    # Join with hyphen separator
    final_name = '-'.join(first_words)
    
    # Collapse multiple hyphens
    final_name = re.sub(r'-+', '-', final_name)
    
    # Remove trailing hyphen and lowercase
    return final_name.rstrip('-').lower()

# ==============================================================================
# YT-DLP SETUP & AUTO-UPDATE (Tasks 4.1 – 4.7)
# ==============================================================================
def check_ytdlp_installed():
    """Checks if yt-dlp is available in PATH."""
    return shutil.which("yt-dlp") is not None

def install_ytdlp():
    """Attempts to install yt-dlp via pip."""
    print("yt-dlp not found. Attempting to install via pip...", flush=True)
    try:
        subprocess.run(
            [sys.executable, "-m", "pip", "install", "yt-dlp"],
            check=True,
            capture_output=True,
            text=True
        )
        print("yt-dlp successfully installed!", flush=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Failed to install yt-dlp automatically:\n{e.stderr}", file=sys.stderr)
        return False

def update_ytdlp():
    """Attempts to update yt-dlp to the latest version."""
    print("Checking for yt-dlp updates...", flush=True)
    # Try updating via pip first, then fallback to yt-dlp -U
    updated = False
    try:
        res = subprocess.run(
            [sys.executable, "-m", "pip", "install", "-U", "yt-dlp"],
            capture_output=True,
            text=True,
            check=True
        )
        if "Successfully installed" in res.stdout or "Requirement already satisfied" in res.stdout:
            updated = True
    except Exception:
        pass

    if not updated:
        try:
            subprocess.run(["yt-dlp", "-U"], capture_output=True, text=True, check=True)
        except Exception as e:
            print(f"Warning: Failed to update yt-dlp: {e}. Proceeding with current version.", file=sys.stderr)

def setup_backend(auto_update):
    """Ensures yt-dlp is available and updated if configured."""
    if not check_ytdlp_installed():
        if auto_update:
            if not install_ytdlp():
                print("\nError: yt-dlp is required but could not be installed automatically.", file=sys.stderr)
                print("Please install yt-dlp manually: pip install yt-dlp", file=sys.stderr)
                return False
        else:
            print("\nError: yt-dlp is required but not found in PATH.", file=sys.stderr)
            print("Please install yt-dlp manually or enable 'youtube_download_auto_update' in config.ini.", file=sys.stderr)
            return False

    if auto_update:
        update_ytdlp()

    return True

# ==============================================================================
# RESOLUTION FORMAT MAPPING (Task 5.1 – 5.2)
# ==============================================================================
def get_ytdlp_format(resolution):
    """Maps configured resolution string to yt-dlp format selection string."""
    if not resolution or resolution.lower() == "best":
        return "bestvideo+bestaudio/best"
    
    match = re.match(r"(\d+)", resolution)
    if match:
        height = int(match.group(1))
        # Select best format <= height, with fallback to best overall if none <= height exists
        return f"bestvideo[height<={height}]+bestaudio/best[height<={height}]/bestvideo+bestaudio/best"
    
    return "bestvideo+bestaudio/best"

# ==============================================================================
# CHAPTERS EXPORT (Tasks 6.1 – 6.4)
# ==============================================================================
def format_seconds(seconds):
    """Formats float seconds into HH:MM:SS."""
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    return f"{h:02d}:{m:02d}:{s:02d}"

def save_separate_chapters(chapters, output_path):
    """Saves chapter metadata to a separate .chapters.txt file."""
    if not chapters:
        return
    try:
        with open(output_path, "w", encoding="utf-8") as f:
            for ch in chapters:
                start = ch.get("start_time", 0)
                title = ch.get("title", f"Chapter at {start}s")
                f.write(f"{format_seconds(start)} - {title}\n")
        print(f"Saved separate chapters to: {output_path}", flush=True)
    except Exception as e:
        print(f"Warning: Failed to save separate chapters: {e}", file=sys.stderr)

# ==============================================================================
# URL EXTRACTION (Tasks 3.1 – 3.8)
# ==============================================================================
def extract_urls_from_file(file_path):
    """Extracts all YouTube URLs from a text file."""
    urls = []
    try:
        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
            urls.extend(YOUTUBE_URL_REGEX.findall(content))
    except Exception as e:
        print(f"Warning: Could not read file {file_path}: {e}", file=sys.stderr)
    return urls

def process_input_paths(paths):
    """Processes file and directory input paths into ordered YouTube URLs in queue order."""
    queue = []  # List of tuples: (source_label, url, source_dir)
    
    for path in sorted(paths):
        p = Path(path)
        if not p.exists():
            print(f"Warning: Input path does not exist: {path}", file=sys.stderr)
            continue
            
        if p.is_file():
            # Extract URLs from single file
            file_urls = extract_urls_from_file(p)
            for url in file_urls:
                queue.append((p.name, url, p.parent))
        elif p.is_dir():
            # Extract URLs from all files in directory in alphabetical order
            file_found = False
            for child in sorted(p.rglob("*")):
                # Skip directories and non-text files or hidden files
                if child.is_dir() or child.name.startswith(".") or "node_modules" in child.parts or ".git" in child.parts:
                    continue
                # Try to extract URLs
                file_urls = extract_urls_from_file(child)
                if file_urls:
                    file_found = True
                    for url in file_urls:
                        queue.append((f"{p.name}/{child.relative_to(p)}", url, p))
            if not file_found:
                print(f"Warning: No files with YouTube URLs found in directory: {path}", file=sys.stderr)
                
    return queue

# ==============================================================================
# MAIN DOWNLOAD PIPELINE
# ==============================================================================
def run_ytdlp_info(url, cookies_browser=None, cookies_file=None):
    """Runs yt-dlp --dump-json to fetch metadata."""
    cmd = ["yt-dlp", "--dump-json", "--no-warnings"]
    if cookies_file:
        cmd.extend(["--cookies", cookies_file])
    elif cookies_browser:
        cmd.extend(["--cookies-from-browser", cookies_browser])
    cmd.append(url)
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=True, encoding="utf-8")
        import json
        return json.loads(res.stdout)
    except Exception as e:
        if cookies_file or cookies_browser:
            source_desc = f"file {cookies_file}" if cookies_file else f"browser {cookies_browser}"
            print(f"   [!] Warning: Failed to load cookies from {source_desc} (might be open, locked, or DPAPI error).", flush=True)
            print("       Retrying metadata fetch without cookies...", flush=True)
            fallback_cmd = ["yt-dlp", "--dump-json", "--no-warnings", url]
            try:
                res = subprocess.run(fallback_cmd, capture_output=True, text=True, check=True, encoding="utf-8")
                import json
                return json.loads(res.stdout)
            except Exception as e2:
                print(f"Error: Failed to fetch metadata for {url}: {e2}", file=sys.stderr)
                return None
        else:
            print(f"Error: Failed to fetch metadata for {url}: {e}", file=sys.stderr)
            return None

def download_video_and_metadata(url, settings, used_zids, zid_cache, source_dir=None):
    """Downloads video, chapters, and subtitles according to settings."""
    # 1. Fetch metadata
    print(f" ➔ Fetching video metadata...", flush=True)
    cookies_browser = settings.get("youtube_download_cookies_browser", "").strip()
    cookies_file = settings.get("youtube_download_cookies_file", "").strip()
    try:
        info = run_ytdlp_info(
            url,
            cookies_browser=cookies_browser if cookies_browser else None,
            cookies_file=cookies_file if cookies_file else None
        )
    except TypeError:
        # Fallback for mocked single-argument lambdas in unit/integration tests
        info = run_ytdlp_info(url)
    if not info:
        print("   [!] Error: Failed to fetch metadata.", file=sys.stderr)
        return False

    title = info.get("title", "Unknown Video")
    sanitized_title = sanitize_title(title)
    
    # Generate unique ZID
    zid = get_unique_zid(used_zids)
    print(f"   • Title: {title}")
    print(f"   • ZID:   {zid}")
    print(f"   • Slug:  {sanitized_title}")

    # Check write permission and create download directory
    target_dir_setting = settings["youtube_download_directory"]
    if target_dir_setting.lower() == "source":
        if source_dir:
            out_dir = Path(source_dir)
        else:
            # Fallback to Videos if no source_dir (e.g. raw CLI URL)
            out_dir = Path(os.path.join(os.environ.get("USERPROFILE", "C:\\"), "Videos"))
    else:
        out_dir = Path(target_dir_setting)

    try:
        out_dir.mkdir(parents=True, exist_ok=True)
        # Test write permission by writing a tiny temp file
        test_file = out_dir / f".write_test_{zid}"
        test_file.touch()
        test_file.unlink()
    except Exception as e:
        print(f"   [!] Error: Download directory '{out_dir}' is not writable: {e}", file=sys.stderr)
        return False

    # 2. Resolve target directories based on duplicate_mode
    dup_mode = settings["youtube_download_duplicate_mode"]
    video_filename = f"{zid}-{sanitized_title}.mp4"
    primary_path = out_dir / video_filename

    target_dir = out_dir
    target_path = primary_path
    
    # Robust ZID-agnostic duplicate detection: check if any file in the target directory
    # ends with f"-{sanitized_title}.mp4"
    existing_file = None
    if out_dir.exists():
        for f in out_dir.iterdir():
            if f.is_file() and f.name.endswith(f"-{sanitized_title}.mp4"):
                existing_file = f
                break

    if existing_file:
        old_zid = existing_file.name.split("-")[0]
        if dup_mode == "skip":
            # Determine what files are required and check if they are missing
            ch_mode = settings["youtube_download_chapters_mode"]
            save_chapters_file = ch_mode in ["separate", "both"]
            has_chapters = len(info.get("chapters", []) or []) > 0
            
            missing_files = []
            
            # Check chapter file
            if save_chapters_file and has_chapters:
                chapters_path = out_dir / f"{old_zid}-{sanitized_title}.chapters.txt"
                if not chapters_path.exists():
                    missing_files.append("chapters.txt")
                    
            # Check subtitle files
            mode = settings["youtube_download_mode"]
            download_subs = mode in ["video+subtitles", "subtitles"]
            sub_langs_list = []
            if download_subs:
                pref_langs = settings["youtube_download_subtitle_languages"]
                raw_list = [l.strip() for l in pref_langs.split(",") if l.strip()]
                for l in raw_list:
                    if l == "original":
                        detected_lang = info.get("language")
                        if detected_lang:
                            sub_langs_list.append(detected_lang)
                        else:
                            meta_subs = info.get("subtitles", {})
                            if meta_subs:
                                sub_langs_list.extend(meta_subs.keys())
                            else:
                                meta_auto = info.get("automatic_captions", {})
                                if meta_auto:
                                    sub_langs_list.extend(meta_auto.keys())
                    else:
                        sub_langs_list.append(l)
                sub_langs_list = list(dict.fromkeys(sub_langs_list))
                
                for lang in sub_langs_list:
                    sub_file = out_dir / f"{old_zid}-{sanitized_title}.{lang}.srt"
                    if not sub_file.exists():
                        missing_files.append(f"{lang}.srt")
                        
            if not missing_files:
                print(f"   [!] File already exists (as {existing_file.name}). Skipping download (skip mode).", flush=True)
                return True
            else:
                print(f"   [!] Video already exists (as {existing_file.name}), but some files are missing: {', '.join(missing_files)}.", flush=True)
                print(f"       Initiating missing file recovery using existing ZID: {old_zid}...", flush=True)
                # Override ZID to match the existing video's ZID
                zid = old_zid
                # Force subtitle-only download mode to skip video download
                settings = settings.copy()
                settings["youtube_download_mode"] = "subtitles"
        elif dup_mode == "overwrite":
            print(f"   [!] File already exists (as {existing_file.name}). Overwriting (overwrite mode).", flush=True)
            # To cleanly overwrite, delete the old ZID-prefixed video and any associated subtitle/chapter files
            try:
                for f in out_dir.iterdir():
                    if f.is_file() and f.name.startswith(old_zid) and sanitized_title in f.name:
                        f.unlink()
                        print(f"   • Removed old file: {f.name}", flush=True)
            except Exception as e:
                print(f"   [!] Warning: Failed to fully delete old duplicate files: {e}", file=sys.stderr)
        else:
            # default: zid-dir
            if not zid_cache.get("value"):
                # Use current download's ZID as session ZID
                zid_cache["value"] = zid
            session_zid = zid_cache["value"]
            target_dir = out_dir / session_zid
            target_dir.mkdir(parents=True, exist_ok=True)
            target_path = target_dir / video_filename
            print(f"   [!] File already exists (as {existing_file.name}). Saving to subfolder: {target_path.name} (zid-dir mode).", flush=True)

    # 3. Handle Chapter configuration
    ch_mode = settings["youtube_download_chapters_mode"]
    embed_chapters = ch_mode in ["embedded", "both"]
    save_chapters_file = ch_mode in ["separate", "both"]
    has_chapters = len(info.get("chapters", []) or []) > 0

    # 4. Handle Subtitle configuration
    mode = settings["youtube_download_mode"]
    sub_langs_list = []
    use_auto_subs = settings["youtube_download_subtitle_auto_fallback"]
    download_subs = mode in ["video+subtitles", "subtitles"]

    if download_subs:
        pref_langs = settings["youtube_download_subtitle_languages"]
        raw_list = [l.strip() for l in pref_langs.split(",") if l.strip()]
        
        # Resolve 'original' if present in the list
        sub_langs_list = []
        for l in raw_list:
            if l == "original":
                detected_lang = info.get("language")
                if detected_lang:
                    sub_langs_list.append(detected_lang)
                else:
                    # Fallback to all manual subtitle languages in metadata
                    meta_subs = info.get("subtitles", {})
                    if meta_subs:
                        sub_langs_list.extend(meta_subs.keys())
                        print("Language auto-detection fell back to all available subtitles.", flush=True)
                    else:
                        # Try to fall back to auto-generated subtitles if available
                        meta_auto = info.get("automatic_captions", {})
                        if meta_auto:
                            sub_langs_list.extend(meta_auto.keys())
                            print("Language auto-detection fell back to all available auto-subtitles.", flush=True)
            else:
                sub_langs_list.append(l)
                
        # Remove duplicates while preserving order
        sub_langs_list = list(dict.fromkeys(sub_langs_list))

    output_tmpl = str(target_dir / f"{zid}-{sanitized_title}.%(ext)s")

    subtitle_download_failed = False

    # 5. Build and run subtitle download command (if needed)
    if download_subs and sub_langs_list:
        sub_cmd = ["yt-dlp", "--skip-download", "--no-warnings", "-o", output_tmpl]
        if cookies_file:
            sub_cmd.extend(["--cookies", cookies_file])
        elif cookies_browser:
            sub_cmd.extend(["--cookies-from-browser", cookies_browser])
        sub_cmd.extend(["--convert-subs", "srt"])
        sub_cmd.extend(["--sub-langs", ",".join(sub_langs_list)])
        
        # Determine whether to download manual, auto, or both
        has_manual = False
        has_auto = False
        meta_subs = info.get("subtitles", {}) or {}
        meta_auto = info.get("automatic_captions", {}) or {}
        
        for lang in sub_langs_list:
            if lang in meta_subs:
                has_manual = True
            elif lang in meta_auto:
                has_auto = True
                
        if has_manual:
            sub_cmd.append("--write-subs")
        if has_auto and use_auto_subs:
            sub_cmd.append("--write-auto-subs")
            print("   • Auto-subtitles will be downloaded.", flush=True)
            
        sub_cmd.append(url)
        
        if has_manual or (has_auto and use_auto_subs):
            print("┌── [SUBTITLES DOWNLOAD PIPELINE] ───────────────────────────────────────────┐", flush=True)
            print(f" ➔ Downloading subtitles ({','.join(sub_langs_list)})...", flush=True)
            try:
                subprocess.run(sub_cmd, check=True)
            except subprocess.CalledProcessError:
                if cookies_file or cookies_browser:
                    source_desc = f"file {cookies_file}" if cookies_file else f"browser {cookies_browser}"
                    print(f"   [!] Warning: Subtitle download failed with cookies ({source_desc} might be open/locked).", flush=True)
                    print("       Retrying subtitle download without cookies...", flush=True)
                    fallback_sub_cmd = []
                    skip_next = False
                    for arg in sub_cmd:
                        if skip_next:
                            skip_next = False
                            continue
                        if arg in ["--cookies-from-browser", "--cookies"]:
                            skip_next = True
                            continue
                        fallback_sub_cmd.append(arg)
                    try:
                        subprocess.run(fallback_sub_cmd, check=True)
                    except subprocess.CalledProcessError:
                        print(f"   [!] Warning: Subtitle download skipped (network issue or 429 Too Many Requests)", file=sys.stderr)
                        subtitle_download_failed = True
                else:
                    # Decoupled error handling: log warning and continue with video download
                    print(f"   [!] Warning: Subtitle download skipped (network issue or 429 Too Many Requests)", file=sys.stderr)
                    subtitle_download_failed = True
            print("└────────────────────────────────────────────────────────────────────────────┘\n", flush=True)
        else:
            print("   • No subtitles were available.", flush=True)

    # 6. Build and run video download command (if needed)
    if mode != "subtitles":
        video_cmd = ["yt-dlp", "--no-warnings"]
        if cookies_file:
            video_cmd.extend(["--cookies", cookies_file])
        elif cookies_browser:
            video_cmd.extend(["--cookies-from-browser", cookies_browser])
        
        # Resolution format selection
        fmt = get_ytdlp_format(settings["youtube_download_resolution"])
        video_cmd.extend(["-f", fmt])
        
        # Merge output container format to MP4
        video_cmd.extend(["--merge-output-format", "mp4"])
        video_cmd.extend(["-o", output_tmpl])
        
        # Chapter embedding
        if embed_chapters and has_chapters:
            video_cmd.append("--embed-chapters")
        else:
            video_cmd.append("--no-embed-chapters")
            
        video_cmd.append(url)
        
        print("┌── [VIDEO DOWNLOAD PIPELINE] ───────────────────────────────────────────────┐", flush=True)
        print(f" ➔ Downloading video ({settings['youtube_download_resolution']})...", flush=True)
        try:
            subprocess.run(video_cmd, check=True)
        except subprocess.CalledProcessError:
            if cookies_file or cookies_browser:
                source_desc = f"file {cookies_file}" if cookies_file else f"browser {cookies_browser}"
                print(f"   [!] Warning: Video download failed with cookies ({source_desc} might be open/locked).", flush=True)
                print("       Retrying video download without cookies...", flush=True)
                fallback_video_cmd = []
                skip_next = False
                for arg in video_cmd:
                    if skip_next:
                        skip_next = False
                        continue
                    if arg in ["--cookies-from-browser", "--cookies"]:
                        skip_next = True
                        continue
                    fallback_video_cmd.append(arg)
                try:
                    subprocess.run(fallback_video_cmd, check=True)
                except subprocess.CalledProcessError:
                    print("   [!] Error: yt-dlp video download failed.", file=sys.stderr)
                    print("└────────────────────────────────────────────────────────────────────────────┘\n", flush=True)
                    return False
            else:
                print("   [!] Error: yt-dlp video download failed.", file=sys.stderr)
                print("└────────────────────────────────────────────────────────────────────────────┘\n", flush=True)
                return False
        print("└────────────────────────────────────────────────────────────────────────────┘\n", flush=True)

    # 6. Save separate chapters if configured and present
    if save_chapters_file and has_chapters:
        chapters_path = target_dir / f"{zid}-{sanitized_title}.chapters.txt"
        save_separate_chapters(info.get("chapters", []), chapters_path)

    # 7. Print download results summary and verify actual file creation
    subtitles_written = []
    if download_subs:
        for lang in sub_langs_list:
            sub_file = target_dir / f"{zid}-{sanitized_title}.{lang}.srt"
            if sub_file.exists():
                subtitles_written.append(sub_file)

    if mode == "subtitles":
        if subtitles_written or not subtitle_download_failed:
            print("\n ➔ Success! (Subtitles only)", flush=True)
            for sub_file in subtitles_written:
                print(f"   • Subtitle saved: {sub_file.name}", flush=True)
        else:
            print("\n ➔ Failure: No subtitles were downloaded.", flush=True)
            return False
    else:
        print(f"\n ➔ Success! Video saved to: {target_path.name}", flush=True)
        for sub_file in subtitles_written:
            print(f"   • Subtitle saved: {sub_file.name}", flush=True)

    return True

# ==============================================================================
# MAIN ENTRYPOINT
# ==============================================================================
def main():
    print("================================================================================", flush=True)
    print("                    KARDENWORT YOUTUBE DOWNLOAD ENGINE                          ", flush=True)
    print("================================================================================", flush=True)
    print(f"ZID: {get_current_zid()}\n", flush=True)
    
    parser = argparse.ArgumentParser(description="YouTube Downloader Integration")
    parser.add_argument("inputs", nargs="*", help="Files, directories or raw URLs containing YouTube links")
    parser.add_argument("--sendto", action="store_true", help="Invoked from Windows Explorer SendTo menu")
    parser.add_argument("--pause", action="store_true", help="Pause console window before exiting")
    
    args = parser.parse_args()
    
    # 1. Load settings
    settings = load_config()

    # 2. Extract inputs (URLs and paths)
    raw_urls = []
    paths = []
    
    for item in args.inputs:
        # Check if item is a direct YouTube URL
        if YOUTUBE_URL_REGEX.match(item):
            raw_urls.append(item)
        else:
            paths.append(item)
            
    # Process files/directories
    file_urls = process_input_paths(paths)
    
    # Assemble final queue
    # Format: list of (source_label, url, source_dir)
    queue = [( "Direct URL", url, None ) for url in raw_urls] + file_urls

    if not queue:
        print(" [!] Error: No YouTube URLs detected in the input.", file=sys.stderr)
        if args.pause:
            input("\nPress Enter to exit...")
        sys.exit(1)

    print(f" [queue] Detected {len(queue)} YouTube URL(s) to process.", flush=True)
    print("┌" + "─" * 76 + "┐", flush=True)
    for idx, (source, url, source_dir) in enumerate(queue):
        # Truncate source label if it is too long to keep it beautiful
        display_source = source
        if len(display_source) > 60:
            display_source = display_source[:27] + "..." + display_source[-30:]
        
        # Safely truncate URL to prevent box break
        display_url = url
        if len(display_url) > 61:
            display_url = display_url[:58] + "..."
            
        line1 = f" • Source: {display_source}"
        line2 = f"   URL:    {display_url}"
        print(f"│{line1.ljust(76)}│", flush=True)
        print(f"│{line2.ljust(76)}│", flush=True)
        if idx < len(queue) - 1:
            print(f"│{' '.ljust(76)}│", flush=True)
    print("└" + "─" * 76 + "┘\n", flush=True)

    # 3. Setup backend (check & update yt-dlp)
    print(" [backend] Checking and updating yt-dlp...", flush=True)
    if not setup_backend(settings["youtube_download_auto_update"]):
        if args.pause:
            input("\nPress Enter to exit...")
        sys.exit(1)
    print(" [backend] yt-dlp is ready.\n", flush=True)

    # 4. Process queue
    used_zids = set()
    zid_cache = {}  # Shared session ZID cache for duplicate handling
    success_count = 0
    
    for idx, (source, url, source_dir) in enumerate(queue, 1):
        display_source = source
        if len(display_source) > 40:
            display_source = display_source[:18] + "..." + display_source[-20:]
        print(f"================================================================================", flush=True)
        print(f" [{idx}/{len(queue)}] Processing URL (Source: {display_source})", flush=True)
        print(f"================================================================================", flush=True)
        try:
            if download_video_and_metadata(url, settings, used_zids, zid_cache, source_dir=source_dir):
                success_count += 1
        except Exception as e:
            print(f"   [!] Error occurred while processing: {e}", file=sys.stderr)

    print(f"\n================================================================================", flush=True)
    print(f" [Summary] Successfully processed {success_count}/{len(queue)} URL(s).", flush=True)
    print(f"================================================================================", flush=True)
    
    if args.pause:
        input("\nPress Enter to exit...")

if __name__ == "__main__":
    main()
