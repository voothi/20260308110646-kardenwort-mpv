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
import threading
import time
from pathlib import Path
from typing import Optional

# ==============================================================================
# GLOBAL CONSTANTS & REGEX
# ==============================================================================
SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_FILE = SCRIPT_DIR / "config.ini"

# Console auto-close timeout in seconds (on successful runs in SendTo/pause mode)
PAUSE_AUTO_CLOSE_TIMEOUT_SECS = 15

# Path to the ZID script; overridden from config via load_config()
_ZID_SCRIPT: str = ""

# Match standard and short YouTube URLs
YOUTUBE_URL_REGEX = re.compile(
    r'(https?://(?:[a-zA-Z0-9_-]+\.)?youtube\.com/(?:watch\?v=|shorts/|embed/|v/)[a-zA-Z0-9_-]{11}|https?://youtu\.be/[a-zA-Z0-9_-]{11})'
)

# Lock to prevent mixed character/line writes from parallel stdout/stderr threads
PRINT_LOCK = threading.Lock()

# ANSI escape sequence remover
ANSI_ESCAPE = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')

def strip_ansi(text):
    """Removes all VT100 / ANSI escape sequences from the given text."""
    return ANSI_ESCAPE.sub('', text)

# ==============================================================================
# PIP-STYLE CONSOLE OUTPUT HELPERS
# ==============================================================================
# Colors: bold cyan [INFO], bold yellow [WARN], bold red [ERROR], bold green [OK]
# All tags are left-aligned and square-bracketed, matching pip's output style.
_IS_TTY = sys.stdout.isatty()

def _c(code, text):
    """Wraps text in an ANSI escape if stdout is a TTY."""
    return f"\x1b[{code}m{text}\x1b[0m" if _IS_TTY else text

def _tag_info():    return _c("1;36", "[INFO]")    # bold cyan
def _tag_warn():    return _c("1;33", "[WARN]")    # bold yellow
def _tag_error():   return _c("1;31", "[ERROR]")   # bold red
def _tag_ok():      return _c("1;32", "[OK]")      # bold green
def _tag_skip():    return _c("1;35", "[SKIP]")    # bold magenta
def _tag_sync():    return _c("1;36", "[SYNC]")    # bold cyan

def _dim(text):     return _c("90", text)          # dim grey
def _bold(text):    return _c("1", text)            # bold white
def _cyan(text):    return _c("36", text)           # cyan
def _green(text):   return _c("32", text)           # green
def _yellow(text):  return _c("33", text)           # yellow

def log_info(msg, indent=""):
    """Prints an [INFO] tagged line."""
    print(f"{indent}{_tag_info()} {msg}", flush=True)

def log_warn(msg, indent=""):
    """Prints a [WARN] tagged line to stdout."""
    print(f"{indent}{_tag_warn()} {msg}", flush=True)

def log_error(msg, indent=""):
    """Prints an [ERROR] tagged line to stderr."""
    print(f"{indent}{_tag_error()} {msg}", file=sys.stderr, flush=True)

def log_ok(msg, indent=""):
    """Prints an [OK] tagged line."""
    print(f"{indent}{_tag_ok()} {msg}", flush=True)

def log_skip(msg, indent=""):
    """Prints a [SKIP] tagged line."""
    print(f"{indent}{_tag_skip()} {msg}", flush=True)

def log_detail(msg, indent="  "):
    """Prints a dim bullet detail line (indented)."""
    print(f"{indent}{_dim('·')} {msg}", flush=True)

def log_section(title):
    """Prints a section separator line in bold, preceded by a blank line."""
    print(f"\n{_bold(title)}", flush=True)

# Progress matching: [download]  33.6% of   11.90MiB at    2.48MiB/s ETA 00:03
PROGRESS_REGEX = re.compile(
    r'\[download\]\s+(\d+(?:\.\d+)?)%\s+of\s+(~?\s*\d+(?:\.\d+)?[a-zA-Z]+)\s+at\s+([^\s]+)\s+ETA\s+([^\s]+)(?:\s+\(frag\s+(\d+)/(\d+)\))?'
)

# Subtitle progress: [download]   15.00KiB at    1.66MiB/s (00:00:00)
SUB_PROGRESS_REGEX = re.compile(
    r'\[download\]\s+(\d+(?:\.\d+)?[a-zA-Z]+)\s+at\s+(.+?)\s+\(([^)]+)\)'
)

# Completion matching: [download] 100% of   11.90MiB in 00:00:04 at 2.52MiB/s
PROGRESS_COMPLETE_REGEX = re.compile(
    r'\[download\]\s+(?:100%|100\.0%)\s+of\s+(~?\s*\d+(?:\.\d+)?[a-zA-Z]+)(?:\s+in\s+([^\s]+))?\s+at\s+([^\s]+)'
)

# Connection resolution/socket error retries: Got error: ... Failed to resolve '...' Retrying (1/10)...
ERROR_RETRY_REGEX = re.compile(
    r'Got error:.*Failed to resolve.*Retrying\s+\((\d+)/(\d+)\)'
)

# Generic retries: Got error: ... Retrying (1/10)...
ERROR_GENERIC_RETRY_REGEX = re.compile(
    r'Got error:.*Retrying\s+\((\d+)/(\d+)\)'
)

# Fragment missing/skip: fragment not found; Skipping fragment 159 ...
FRAGMENT_SKIP_REGEX = re.compile(
    r'fragment not found;\s*Skipping fragment\s+(\d+)'
)

def make_premium_progress_bar(percent_val, size_str, speed_str, eta_str, frag_current=None, frag_total=None, indent="     "):
    """Generates a Python pip-style, elegant carriage-returned progress bar with modern colors."""
    bar_width = 40
    filled_width = int(round(bar_width * percent_val / 100.0))
    bar = _green("━" * filled_width) + _dim("━" * (bar_width - filled_width))
    
    size_clean = size_str.strip()
    speed_clean = speed_str.strip()
    eta_clean = eta_str.strip()
    
    frag_info = f" {_dim(f'(frag {frag_current}/{frag_total})')}" if frag_current and frag_total else ""
    
    # Try to format as current/total size like pip (e.g. 3.5/10.5 MiB)
    match = re.search(r"([\d\.]+)\s*([a-zA-Z]+)", size_clean)
    if match:
        try:
            num = float(match.group(1))
            unit = match.group(2)
            current_num = num * percent_val / 100.0
            progress_size = f"{current_num:.1f}/{num:.1f} {unit}"
        except Exception:
            progress_size = f"{percent_val:.1f}% of {size_clean}"
    else:
        progress_size = f"{percent_val:.1f}% of {size_clean}"
        
    return f"\r{indent}{bar} {_cyan(progress_size)} {_yellow(speed_clean)} {_dim('eta')} {_cyan(eta_clean)}{frag_info}"

def clear_line():
    """Clears the current console line completely to prevent character leftovers."""
    sys.stdout.write("\r\x1b[K" + " " * 120 + "\r")
    sys.stdout.flush()

def pause_console(success: bool = True, timeout_secs: Optional[int] = PAUSE_AUTO_CLOSE_TIMEOUT_SECS):
    """Pauses the console window.
    If success is True and timeout_secs is provided, shows a premium countdown to auto-close.
    If success is False or timeout_secs is None, pauses indefinitely so the user can inspect errors.
    """
    if not success or timeout_secs is None:
        try:
            input("\nPress Enter to exit...")
        except Exception:
            pass
        return

    print(f"\nPress Enter to exit (or wait {timeout_secs}s for auto-close)...", end="", flush=True)
    
    is_windows = sys.platform.startswith("win")
    if is_windows and sys.stdout.isatty():
        import msvcrt
        start_time = time.time()
        last_remaining = timeout_secs
        while True:
            if msvcrt.kbhit():
                try:
                    msvcrt.getch()
                except Exception:
                    pass
                break
            
            elapsed = time.time() - start_time
            remaining = int(round(timeout_secs - elapsed))
            if remaining <= 0:
                break
                
            if remaining != last_remaining:
                sys.stdout.write(f"\rPress Enter to exit (or wait {remaining}s for auto-close)...")
                sys.stdout.flush()
                last_remaining = remaining
            
            time.sleep(0.05)
        # Clear the countdown text line cleanly
        sys.stdout.write("\r" + " " * 65 + "\r")
        sys.stdout.flush()
    else:
        try:
            input("\nPress Enter to exit...")
        except Exception:
            pass

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
        "youtube_download_clean_hyphens": "false",
        "youtube_download_unbreak_lines": "false",
        "youtube_download_hyphenation_marks": "-¬",
        "youtube_download_compositional_conjunctions": "und,oder,sowie,bzw,bis",
        "youtube_download_fix_sentence_splits": "false",
        "youtube_download_sync_secondary_timestamps": "false",
        "youtube_download_companion_audio_languages": "",
        "youtube_download_js_runtime": "node",
        "youtube_download_zid_script": "",
        "youtube_download_auto_close_timeout_secs": "15",
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

    # Propagate ZID script path to module-level variable so get_current_zid() can use it
    global _ZID_SCRIPT
    _ZID_SCRIPT = os.path.expandvars(settings["youtube_download_zid_script"])

    return settings

# ==============================================================================
# ZID GENERATION & SANITIZATION (Tasks 5.7 – 5.12)
# ==============================================================================
def get_current_zid():
    """Calls the system ZID script to retrieve the current anchor ZID, falling back to local time.
    The path to the ZID script is read from the config setting 'youtube_download_zid_script'.
    Falls back to the local system time if the script is not configured or fails.
    """
    if _ZID_SCRIPT:
        try:
            res = subprocess.run(
                ["python", _ZID_SCRIPT, "--no-clipboard"],
                capture_output=True,
                text=True,
                check=True
            )
            return res.stdout.strip()
        except Exception:
            pass
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
        log_detail(f"Saved separate chapters to: {output_path}")
    except Exception as e:
        log_warn(f"Failed to save separate chapters: {e}")

def clean_srt_file(srt_path, clean_hyphens=False, unbreak_lines=False, hyphenation_marks="-¬", compositional_conjunctions="und,oder,sowie,bzw,bis", fix_sentence_splits=False):
    """Cleans up duplicate/repeating lines from rolling subtitles in a .srt file.
    Merges consecutive blocks with identical text and eliminates roll-up line overlap.
    Optional cleaning parameters:
      clean_hyphens: strips leading dashes/hyphens from subtitle lines.
      unbreak_lines: joins multi-line blocks into single lines, handling word hyphenation breaks.
      hyphenation_marks: characters considered hyphens (e.g. "-¬").
      compositional_conjunctions: comma-separated list of conjunctions that preserve hyphens when unbreaking.
      fix_sentence_splits: merges blocks that begin with punctuation (e.g. ". " or ",") or whose
                           entire content is punctuation-only (e.g. ".") back onto the previous block.
                           This corrects a common artifact in YouTube auto-translated tracks.
    """
    try:
        path = Path(srt_path)
        if not path.exists():
            return
        
        # Read file contents using utf-8-sig to handle optional BOM safely
        try:
            content = path.read_text(encoding="utf-8-sig")
        except Exception:
            content = path.read_text(encoding="utf-8", errors="ignore")
            
        # Standardize line endings to \n
        content = content.replace("\r\n", "\n")
        
        lines = content.split("\n")
        parsed_blocks = []
        current_block = None
        
        for i, line in enumerate(lines):
            trimmed = line.strip()
            if "-->" in trimmed:
                if current_block is not None:
                    parsed_blocks.append(current_block)
                
                index = ""
                for j in range(i - 1, -1, -1):
                    prev_line = lines[j].strip()
                    if prev_line:
                        if prev_line.isdigit():
                            index = prev_line
                        break
                
                times = trimmed.split("-->")
                start_time = times[0].strip()
                end_time = times[1].strip()
                
                current_block = {
                    "index": index,
                    "start_time": start_time,
                    "end_time": end_time,
                    "lines": []
                }
            else:
                if current_block is not None:
                    if trimmed:
                        is_next_index = False
                        if trimmed.isdigit():
                            for k in range(i + 1, min(i + 5, len(lines))):
                                next_trimmed = lines[k].strip()
                                if not next_trimmed:
                                    continue
                                if "-->" in next_trimmed:
                                    is_next_index = True
                                    break
                                else:
                                    break
                        if not is_next_index:
                            if clean_hyphens:
                                # Remove leading '-' or '–' or '—' followed by optional spaces
                                trimmed = re.sub(r'^[-\u2013\u2014]\s*', '', trimmed)
                            
                            # Apply robust text cleaning rules from remove-newline-util
                            trimmed = re.sub(r'<[^<]+?>', '', trimmed)  # Remove HTML tags if any
                            trimmed = re.sub(r'\s{2,}', ' ', trimmed)   # Collapse multiple spaces
                            trimmed = re.sub(r'\s+([:;,.!?])', r'\1', trimmed)  # Remove spaces before punctuation
                            trimmed = trimmed.strip()
                            
                            if trimmed:
                                current_block["lines"].append(trimmed)
                            
        if current_block is not None:
            parsed_blocks.append(current_block)
            
        if not parsed_blocks:
            return
            
        cleaned_blocks = []
        
        for i, b in enumerate(parsed_blocks):
            prev_block = parsed_blocks[i-1] if i > 0 else None
            
            filtered_lines = []
            for line in b["lines"]:
                if prev_block and line in prev_block["lines"]:
                    continue
                filtered_lines.append(line)
                
            if not filtered_lines:
                if cleaned_blocks:
                    cleaned_blocks[-1]["end_time"] = b["end_time"]
                continue
                
            if cleaned_blocks and cleaned_blocks[-1]["lines"] == filtered_lines:
                cleaned_blocks[-1]["end_time"] = b["end_time"]
            else:
                cleaned_blocks.append({
                    "start_time": b["start_time"],
                    "end_time": b["end_time"],
                    "lines": filtered_lines
                })
                
        # Re-write the cleaned blocks to SRT file
        # Optional pass: fix sentence splits from auto-translated tracks.
        # A block whose text starts with punctuation (e.g. ". word", ", word") or whose
        # entire text IS punctuation (e.g. ".") is a sentence-split artifact.
        # Fix: strip the leading punctuation from the block and append it to the
        # previous block's last line, then extend the previous block's end_time to cover
        # this block's duration.
        if fix_sentence_splits and len(cleaned_blocks) > 1:
            _LEADING_PUNCT_RE = re.compile(r'^([.,!?;:\s]+)\s*')
            _PUNCT_ONLY_RE = re.compile(r'^[.,!?;:\s]+$')
            merged = [cleaned_blocks[0]]
            for cb in cleaned_blocks[1:]:
                combined = " ".join(cb["lines"]).strip()
                m = _LEADING_PUNCT_RE.match(combined)
                if m and merged:
                    # Append the leading punctuation to the previous block's last line
                    punct = m.group(1).rstrip()
                    remainder = combined[m.end():].strip()
                    if merged[-1]["lines"]:
                        merged[-1]["lines"][-1] = merged[-1]["lines"][-1] + punct
                    # Extend the previous block's end_time to cover this block
                    merged[-1]["end_time"] = cb["end_time"]
                    # If there is remaining text after the punctuation, keep it as a new block
                    if remainder:
                        merged.append({
                            "start_time": cb["start_time"],
                            "end_time": cb["end_time"],
                            "lines": [remainder]
                        })
                else:
                    merged.append(cb)
            cleaned_blocks = merged

        new_content = []
        for idx, cb in enumerate(cleaned_blocks, 1):
            new_content.append(str(idx))
            new_content.append(f"{cb['start_time']} --> {cb['end_time']}")
            
            lines_to_write = cb["lines"]
            if unbreak_lines:
                text = "\n".join(lines_to_write)
                
                # Robust word hyphenation joining ported from remove-newline-util using config values
                escaped_marks = re.escape(hyphenation_marks)
                conj_list = [c.strip() for c in compositional_conjunctions.split(",") if c.strip()]
                conj_regex = f"(?:{'|'.join(map(re.escape, conj_list))})" if conj_list else "(?:)"
                
                # 1. German compositional hyphens: keep hyphen at newline (e.g. Zweit-\nund -> Zweit- und)
                text = re.sub(fr'((?<!\s)[{escaped_marks}])\s*\n\s*(?={conj_regex}\b)', r'\1 ', text)
                # 2. Standard word hyphenation break: join words (e.g. hyphen-\nation -> hyphenation)
                text = re.sub(fr'[{escaped_marks}]\s*\n\s*', '', text)
                # 3. Replace remaining linebreaks with space
                text = re.sub(r'\n', ' ', text)
                
                # Final pass collapses and trims
                text = re.sub(r"\s+", " ", text).strip()
                lines_to_write = [text] if text else []
                
            for line in lines_to_write:
                new_content.append(line)
            new_content.append("")  # Empty line between blocks
            
        with path.open("w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(new_content))

    except Exception as e:
        log_warn(f"Failed to clean subtitle file: {e}")

# ==============================================================================
# SECONDARY SUBTITLE TIMESTAMP SYNC (Option A)
# ==============================================================================
def sync_secondary_srt_timestamps(primary_path, secondary_path):
    """Re-timestamps the secondary SRT to match the primary using time-based
    nearest-neighbor matching.

    For each secondary block, its original start_time is matched to the closest
    primary block's start_time via binary search.  Monotonic forward progress is
    enforced so that timestamps never go backwards.

    This avoids the cumulative positional drift that arises when the two tracks
    have different block counts (e.g. EN=356 vs RU=350).
    """
    import bisect

    try:
        primary_path = Path(primary_path)
        secondary_path = Path(secondary_path)
        if not primary_path.exists() or not secondary_path.exists():
            return

        def read_blocks(p):
            """Returns a list of dicts: {start_time, end_time, lines}."""
            content = p.read_text(encoding="utf-8-sig", errors="ignore")
            content = content.replace("\r\n", "\n")
            raw_lines = content.split("\n")
            blocks = []
            current = None
            for i, raw in enumerate(raw_lines):
                trimmed = raw.strip()
                if "-->" in trimmed:
                    if current is not None:
                        blocks.append(current)
                    times = trimmed.split("-->")
                    current = {
                        "start_time": times[0].strip(),
                        "end_time": times[1].strip(),
                        "lines": []
                    }
                else:
                    if current is not None and trimmed:
                        # Skip pure-digit index lines that precede the next timestamp
                        is_next_index = False
                        if trimmed.isdigit():
                            for k in range(i + 1, min(i + 5, len(raw_lines))):
                                nxt = raw_lines[k].strip()
                                if not nxt:
                                    continue
                                if "-->" in nxt:
                                    is_next_index = True
                                break
                        if not is_next_index:
                            current["lines"].append(trimmed)
            if current is not None:
                blocks.append(current)
            return blocks

        def srt_time_to_ms(t):
            """Converts '00:02:15,840' -> 135840 (milliseconds)."""
            parts = t.split(":")
            h = int(parts[0])
            m = int(parts[1])
            s_ms = parts[2].split(",")
            s = int(s_ms[0])
            ms = int(s_ms[1]) if len(s_ms) > 1 else 0
            return h * 3600000 + m * 60000 + s * 1000 + ms

        primary_blocks = read_blocks(primary_path)
        secondary_blocks = read_blocks(secondary_path)

        if not primary_blocks or not secondary_blocks:
            return

        # Build a sorted list of primary start times in ms for binary search
        primary_starts_ms = [srt_time_to_ms(b["start_time"]) for b in primary_blocks]

        # Match each secondary block to the nearest primary block by start time
        min_idx = 0  # enforce monotonic non-decreasing progress
        matched_pairs = []  # list of (primary_block, secondary_block)

        for sb in secondary_blocks:
            sb_start_ms = srt_time_to_ms(sb["start_time"])

            # Binary search for the insertion point in the primary timeline
            pos = bisect.bisect_left(primary_starts_ms, sb_start_ms, lo=min_idx)

            # Find the closest primary block between pos-1 and pos
            best = pos
            if pos >= len(primary_starts_ms):
                best = len(primary_starts_ms) - 1
            elif pos > min_idx:
                diff_left = abs(primary_starts_ms[pos - 1] - sb_start_ms)
                diff_right = abs(primary_starts_ms[pos] - sb_start_ms)
                if diff_left <= diff_right:
                    best = pos - 1

            # Clamp to valid range and enforce monotonic progress
            best = max(best, min_idx)
            best = min(best, len(primary_blocks) - 1)

            matched_pairs.append((primary_blocks[best], sb))
            min_idx = best  # allow same primary block for adjacent secondary blocks

        new_content = []
        for idx, (pb, sb) in enumerate(matched_pairs, 1):
            new_content.append(str(idx))
            new_content.append(f"{pb['start_time']} --> {pb['end_time']}")
            for line in sb["lines"]:
                new_content.append(line)
            new_content.append("")  # blank separator

        with secondary_path.open("w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(new_content))
        print(f"  {_tag_sync()} Re-timestamped {secondary_path.name} to match {primary_path.name} "
              f"({len(matched_pairs)} blocks, time-aligned).", flush=True)

    except Exception as e:
        log_warn(f"Failed to sync secondary subtitle timestamps: {e}")

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
        log_warn(f"Could not read file {file_path}: {e}")
    return urls

def process_input_paths(paths):
    """Processes file and directory input paths into ordered YouTube URLs in queue order."""
    queue = []  # List of tuples: (source_label, url, source_dir)
    
    for path in sorted(paths):
        p = Path(path)
        if not p.exists():
            log_warn(f"Input path does not exist: {path}")
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
                log_warn(f"No files with YouTube URLs found in directory: {path}")
                
    return queue

_original_run = subprocess.run

def run_subprocess_streaming(cmd, *args, indent="", **kwargs):
    """Runs a subprocess and streams stdout and stderr in real-time, preventing mixed lines."""
    if subprocess.run is not _original_run:
        return subprocess.run(cmd, *args, **kwargs)
        
    def indent_line(line, indent):
        if not indent:
            return line
        if line.startswith("\r"):
            return "\r" + indent + line[1:]
        return indent + line

    def process_line(raw_line, is_stderr, is_tty, state):
        line_content = raw_line.rstrip("\r\n")
        line_clean = strip_ansi(line_content)
        
        if is_stderr:
            with PRINT_LOCK:
                if state.get("last_pipe") != "stderr" and state.get("last_char") not in ("\n", "\r"):
                    sys.stdout.write("\n")
                    sys.stdout.flush()
                
                retry_match = ERROR_RETRY_REGEX.search(line_clean)
                generic_retry_match = ERROR_GENERIC_RETRY_REGEX.search(line_clean)
                frag_skip_match = FRAGMENT_SKIP_REGEX.search(line_clean)
                
                if retry_match:
                    attempt, total = retry_match.groups()
                    clear_line()
                    sys.stdout.write(f"\r{indent}  {_tag_warn()} connection issue detected, retrying ({attempt}/{total})...\n")
                    sys.stdout.flush()
                    state["last_char"] = "\n"
                elif generic_retry_match:
                    attempt, total = generic_retry_match.groups()
                    clear_line()
                    sys.stdout.write(f"\r{indent}  {_tag_warn()} retry attempt ({attempt}/{total})...\n")
                    sys.stdout.flush()
                    state["last_char"] = "\n"
                elif frag_skip_match:
                    frag_num = frag_skip_match.group(1)
                    clear_line()
                    sys.stdout.write(f"\r{indent}  {_tag_warn()} Skipping missing fragment {frag_num}...\n")
                    sys.stdout.flush()
                    state["last_char"] = "\n"
                else:
                    sys.stderr.write(indent_line(raw_line, indent))
                    sys.stderr.flush()
                    if raw_line:
                        state["last_char"] = raw_line[-1]
                state["last_pipe"] = "stderr"
        else:
            progress_match = PROGRESS_REGEX.search(line_clean)
            sub_progress_match = SUB_PROGRESS_REGEX.search(line_clean)
            complete_match = PROGRESS_COMPLETE_REGEX.search(line_clean)
            retry_match = ERROR_RETRY_REGEX.search(line_clean)
            generic_retry_match = ERROR_GENERIC_RETRY_REGEX.search(line_clean)
            frag_skip_match = FRAGMENT_SKIP_REGEX.search(line_clean)
            
            with PRINT_LOCK:
                if progress_match:
                    percent_str, size_str, speed_str, eta_str, frag_curr, frag_tot = progress_match.groups()
                    percent_val = float(percent_str)
                    
                    if is_tty:
                        bar_line = make_premium_progress_bar(percent_val, size_str, speed_str, eta_str, frag_curr, frag_tot, indent=indent)
                        clear_line()
                        sys.stdout.write(bar_line)
                        sys.stdout.flush()
                        state["last_char"] = "\r"
                    else:
                        last_pct = state.get("last_percent", -10)
                        if percent_val - last_pct >= 10 or percent_val == 100:
                            bar_line = make_premium_progress_bar(percent_val, size_str, speed_str, eta_str, frag_curr, frag_tot, indent=indent).strip("\r")
                            sys.stdout.write(f"{bar_line}\n")
                            sys.stdout.flush()
                            state["last_percent"] = percent_val
                            state["last_char"] = "\n"
                elif sub_progress_match:
                    size_str, speed_str, time_str = sub_progress_match.groups()
                    if is_tty:
                        clear_line()
                        sys.stdout.write(f"\r{indent}Downloading subtitles: {size_str.strip()} at {speed_str.strip()} ({time_str.strip()})")
                        sys.stdout.flush()
                        state["last_char"] = "\r"
                elif complete_match:
                    size_str, time_str, speed_str = complete_match.groups()
                    if is_tty:
                        clear_line()
                    
                    time_info = f" in {time_str}" if time_str else ""
                    sys.stdout.write(f"{indent}  Completed download of {size_str.strip()}{time_info} at {speed_str.strip()}\n")
                    sys.stdout.flush()
                    state["last_char"] = "\n"
                    state["last_percent"] = -10
                elif retry_match:
                    attempt, total = retry_match.groups()
                    clear_line()
                    sys.stdout.write(f"\r{indent}  {_tag_warn()} connection issue detected, retrying ({attempt}/{total})...\n")
                    sys.stdout.flush()
                    state["last_char"] = "\n"
                elif generic_retry_match:
                    attempt, total = generic_retry_match.groups()
                    clear_line()
                    sys.stdout.write(f"\r{indent}  {_tag_warn()} retry attempt ({attempt}/{total})...\n")
                    sys.stdout.flush()
                    state["last_char"] = "\n"
                elif frag_skip_match:
                    frag_num = frag_skip_match.group(1)
                    clear_line()
                    sys.stdout.write(f"\r{indent}  {_tag_warn()} Skipping missing fragment {frag_num}...\n")
                    sys.stdout.flush()
                    state["last_char"] = "\n"
                else:
                    if line_clean.startswith("[download]") and ("%" in line_clean or "100%" in line_clean):
                        pass
                    else:
                        sys.stdout.write(indent_line(raw_line, indent))
                        sys.stdout.flush()
                        if raw_line:
                            state["last_char"] = raw_line[-1]
                state["last_pipe"] = "stdout"

    def stream_pipe(pipe, is_stderr, state):
        buffer = []
        is_tty = sys.stdout.isatty()
        
        while True:
            try:
                char = pipe.read(1)
            except Exception:
                break
                
            if not char:
                if buffer:
                    line = "".join(buffer)
                    process_line(line, is_stderr, is_tty, state)
                break
            
            if char in ("\n", "\r"):
                line = "".join(buffer)
                buffer.clear()
                process_line(line + char, is_stderr, is_tty, state)
            else:
                buffer.append(char)

    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=0,
        encoding="utf-8",
        errors="replace"
    )
    
    state = {"last_char": "\n", "last_percent": -10}
    
    t_out = threading.Thread(target=stream_pipe, args=(process.stdout, False, state))
    t_err = threading.Thread(target=stream_pipe, args=(process.stderr, True, state))
    
    t_out.start()
    t_err.start()
    
    t_out.join()
    t_err.join()
    
    process.wait()
    if process.returncode != 0:
        raise subprocess.CalledProcessError(process.returncode, cmd)

# ==============================================================================
# COMPANION AUDIO DOWNLOAD (Task 14.3)
# ==============================================================================
def get_base_language_code(lang):
    """Returns the base language code for regional tags (e.g. ru-RU -> ru, de_DE -> de)."""
    if not lang:
        return ""
    normalized = str(lang).strip()
    for sep in ("-", "_"):
        if sep in normalized:
            return normalized.split(sep)[0]
    return normalized

def download_companion_audio(url, zid, sanitized_title, target_dir, lang, info, settings):
    """Downloads an audio-only companion track for a specific dubbed language.

    Output: {target_dir}/{zid}-{sanitized_title}.{lang}.mp4
    The MP4 container holds one audio stream only (no video), ~10x smaller than a full video.
    mpv loads it via audio-add as an external track for the companion_audio hotkey cycle.

    Returns True on success or graceful skip (no track for that language).
    Returns False only on an actual download failure.
    """
    # Guard: check that a genuine dubbed track exists for this language in metadata.
    # Without this check, yt-dlp would fall back to the default audio stream, producing a
    # duplicate of the main video's audio rather than an alternate language track.
    # Since AI-dubbed tracks are often only served in combined video+audio formats (e.g. HLS/m3u8),
    # we allow formats that contain video but filter to ensure they have audio (acodec != "none").
    formats = info.get("formats", []) or []
    requested_lang = str(lang).strip()
    requested_base = get_base_language_code(requested_lang).lower()

    # Guard: do not duplicate the video's original/default audio language as a companion track.
    # If the requested companion language equals the primary language of the source video,
    # companion audio would usually be the same content as the main track in the MP4.
    primary_lang = resolve_original_language(info) or str(info.get("language") or "").strip()
    primary_base = get_base_language_code(primary_lang).lower() if primary_lang else ""
    if primary_base and requested_base == primary_base:
        log_skip(
            f"Companion audio '{lang}' matches the video's primary language "
            f"('{primary_lang}') — skipping duplicate track."
        )
        return True

    matched_lang_tag = None
    for f in formats:
        acodec = f.get("acodec", "none")
        format_lang = str(f.get("language") or "").strip()
        if acodec in ("none", "") or not format_lang:
            continue
        if (
            format_lang.lower() == requested_lang.lower()
            or get_base_language_code(format_lang).lower() == requested_base
        ):
            matched_lang_tag = format_lang
            break
    if not matched_lang_tag:
        print(f"    • No dubbed audio track for language '{lang}' in metadata — skipping companion audio.", flush=True)
        return True

    output_path = Path(target_dir) / f"{zid}-{sanitized_title}.{lang}.mp4"
    output_tmpl = str(output_path)

    cookies_browser = settings.get("youtube_download_cookies_browser", "").strip()
    cookies_file = settings.get("youtube_download_cookies_file", "").strip()

    # Pass --js-runtimes and --remote-components if a JS runtime is configured.
    # Try bestaudio first, then fall back to worst/best (which matches combined formats at lowest resolution to save bandwidth).
    cmd = ["yt-dlp"]
    js_runtime = str(settings.get("youtube_download_js_runtime", "node")).strip()
    if js_runtime and js_runtime.lower() != "none":
        cmd.extend(["--js-runtimes", js_runtime, "--remote-components", "ejs:github"])
    cmd.extend([
           "--color", "always", "--no-warnings",
           "-f", f"bestaudio[language={matched_lang_tag}]/worst[language={matched_lang_tag}]/best[language={matched_lang_tag}]",
           "--merge-output-format", "mp4",
           "-o", output_tmpl])
    if cookies_file:
        cmd.extend(["--cookies", cookies_file])
    elif cookies_browser:
        cmd.extend(["--cookies-from-browser", cookies_browser])
    cmd.append(url)

    print(f"  Downloading companion audio ({lang})...", flush=True)
    try:
        run_subprocess_streaming(cmd, check=True)
        # Strip video stream if the final file contains video, to save disk space
        if output_path.exists():
            try:
                temp_path = output_path.with_suffix(".tmp.mp4")
                ffmpeg_cmd = ["ffmpeg", "-y", "-i", str(output_path), "-vn", "-c:a", "copy", str(temp_path)]
                res = subprocess.run(ffmpeg_cmd, capture_output=True, text=True)
                if res.returncode == 0 and temp_path.exists():
                    os.replace(temp_path, output_path)
                    print(f"    Extracted audio-only stream from companion to save disk space.", flush=True)
                else:
                    if temp_path.exists():
                        temp_path.unlink()
            except Exception:
                pass
        return True
    except subprocess.CalledProcessError:
        if cookies_file or cookies_browser:
            source_desc = f"file {cookies_file}" if cookies_file else f"browser {cookies_browser}"
            print(f"    WARNING: Companion audio download failed with cookies ({source_desc} might be open/locked).", flush=True)
            print("    Retrying without cookies...", flush=True)
            fallback_cmd = []
            skip_next = False
            for arg in cmd:
                if skip_next:
                    skip_next = False
                    continue
                if arg in ["--cookies-from-browser", "--cookies"]:
                    skip_next = True
                    continue
                fallback_cmd.append(arg)
            try:
                run_subprocess_streaming(fallback_cmd, check=True)
                return True
            except subprocess.CalledProcessError:
                pass
        print(f"    WARNING: Companion audio download failed for language '{lang}'.", file=sys.stderr)
        return False

# ==============================================================================
# MAIN DOWNLOAD PIPELINE
# ==============================================================================
def run_ytdlp_info(url, cookies_browser=None, cookies_file=None, js_runtime="node"):
    """Runs yt-dlp --dump-json to fetch metadata."""
    cmd = ["yt-dlp"]
    js_runtime = str(js_runtime or "").strip()
    if js_runtime and js_runtime.lower() != "none":
        cmd.extend(["--js-runtimes", js_runtime, "--remote-components", "ejs:github"])
    cmd.extend(["--dump-json", "--no-warnings"])
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
            print(f"    [!] Warning: Failed to load cookies from {source_desc} (might be open, locked, or DPAPI error).", flush=True)
            print("        Retrying metadata fetch without cookies...", flush=True)
            fallback_cmd = ["yt-dlp"]
            if js_runtime and js_runtime.lower() != "none":
                fallback_cmd.extend(["--js-runtimes", js_runtime, "--remote-components", "ejs:github"])
            fallback_cmd.extend(["--dump-json", "--no-warnings", url])
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

def resolve_original_language(info):
    """Resolves the video's main language, with intelligent base-code fallback for regional dialects."""
    detected_lang = info.get("language")
    if not detected_lang:
        return None
        
    meta_subs = info.get("subtitles", {}) or {}
    meta_auto = info.get("automatic_captions", {}) or {}
    
    # If the detected language exists exactly in subtitles/auto captions, use it
    if detected_lang in meta_subs or detected_lang in meta_auto:
        return detected_lang
        
    # If not, but it is a regional dialect (e.g. en-US, zh-CN, de_DE), try the base language code (e.g. en, zh, de)
    base_lang = get_base_language_code(detected_lang)
    if base_lang != detected_lang and (base_lang in meta_subs or base_lang in meta_auto):
        return base_lang
            
    # Fallback to the detected language anyway so yt-dlp can try its own matching
    return detected_lang

def _is_equivalent_subtitle_language(lang_a, lang_b):
    """Returns True when two subtitle language tags refer to the same base track.

    We treat exact matches as duplicates and also treat base-vs-regional variants as duplicates
    (e.g. `ru` and `ru-RU`). Two different regional variants without an explicit base code
    (e.g. `zh-CN` vs `zh-TW`) are not treated as duplicates.
    """
    a = str(lang_a or "").strip()
    b = str(lang_b or "").strip()
    if not a or not b:
        return False
    a_l = a.lower()
    b_l = b.lower()
    if a_l == b_l:
        return True
    a_base = get_base_language_code(a).lower()
    b_base = get_base_language_code(b).lower()
    if a_base != b_base:
        return False
    return a_l == a_base or b_l == b_base

def resolve_subtitle_languages(pref_langs, info, emit_fallback_logs=True):
    """Resolves configured subtitle languages into a deduplicated, ordered language list."""
    raw_list = [l.strip() for l in str(pref_langs or "").split(",") if l.strip()]
    resolved = []

    def append_if_new(lang):
        lang = str(lang or "").strip()
        if not lang:
            return
        for existing in resolved:
            if _is_equivalent_subtitle_language(existing, lang):
                return
        resolved.append(lang)

    for l in raw_list:
        if l == "original":
            detected_lang = resolve_original_language(info)
            if detected_lang:
                append_if_new(detected_lang)
            else:
                # Fallback to all manual subtitle languages in metadata
                meta_subs = info.get("subtitles", {})
                if meta_subs:
                    for meta_lang in meta_subs.keys():
                        append_if_new(meta_lang)
                    if emit_fallback_logs:
                        log_info("Language auto-detection fell back to all available subtitles.")
                else:
                    # Try to fall back to auto-generated subtitles if available
                    meta_auto = info.get("automatic_captions", {})
                    if meta_auto:
                        for meta_lang in meta_auto.keys():
                            append_if_new(meta_lang)
                        if emit_fallback_logs:
                            log_info("Language auto-detection fell back to all available auto-subtitles.")
        else:
            append_if_new(l)

    return resolved

def download_video_and_metadata(url, settings, used_zids, zid_cache, source_dir=None):
    """Downloads video, chapters, and subtitles according to settings."""
    # 1. Fetch metadata
    log_section("Fetching video metadata...")
    cookies_browser = settings.get("youtube_download_cookies_browser", "").strip()
    cookies_file = settings.get("youtube_download_cookies_file", "").strip()
    try:
        info = run_ytdlp_info(
            url,
            cookies_browser=cookies_browser if cookies_browser else None,
            cookies_file=cookies_file if cookies_file else None,
            js_runtime=settings.get("youtube_download_js_runtime", "node")
        )
    except TypeError:
        # Fallback for mocked single-argument lambdas in unit/integration tests
        info = run_ytdlp_info(url)
    if not info:
        log_error("Failed to fetch metadata.")
        return False

    title = info.get("title", "Unknown Video")
    sanitized_title = sanitize_title(title)
    
    # Generate unique ZID
    zid = get_unique_zid(used_zids)
    log_detail(f"Title: {_bold(title)}")
    log_detail(f"ZID:   {_cyan(zid)}")
    log_detail(f"Slug:  {sanitized_title}")

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
        log_error(f"Download directory '{out_dir}' is not writable: {e}")
        return False

    # 2. Resolve target directories based on duplicate_mode
    dup_mode = settings["youtube_download_duplicate_mode"]
    video_filename = f"{zid}-{sanitized_title}.mp4"
    primary_path = out_dir / video_filename

    target_dir = out_dir
    target_path = primary_path
    is_skip_recovery = False
    any_subs_missing = False
    
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
                sub_langs_list = resolve_subtitle_languages(pref_langs, info, emit_fallback_logs=False)
                
                for lang in sub_langs_list:
                    sub_file = out_dir / f"{old_zid}-{sanitized_title}.{lang}.srt"
                    if not sub_file.exists():
                        missing_files.append(f"{lang}.srt")
                        any_subs_missing = True

            # Check companion audio files
            comp_langs_str = settings.get("youtube_download_companion_audio_languages", "").strip()
            if comp_langs_str:
                comp_langs = [l.strip() for l in comp_langs_str.split(",") if l.strip()]
                for comp_lang in comp_langs:
                    comp_file = out_dir / f"{old_zid}-{sanitized_title}.{comp_lang}.mp4"
                    if not comp_file.exists():
                        missing_files.append(f"{comp_lang}.mp4 (companion audio)")

            if not missing_files:
                log_skip(
                    f"All required artifacts already exist for {existing_file.name} "
                    f"(video, subtitles, chapters, companion audio). Skipping (skip mode)."
                )
                return True
            else:
                log_warn(f"Video already exists ({existing_file.name}), but some files are missing: {', '.join(missing_files)}.")
                log_info(f"Initiating missing file recovery using existing ZID: {old_zid}...")
                # Override ZID to match the existing video's ZID, and re-point target_path
                # at the actual on-disk video so the success summary names a real file.
                zid = old_zid
                target_path = existing_file
                is_skip_recovery = True
        elif dup_mode == "overwrite":
            log_warn(f"File already exists ({existing_file.name}). Overwriting (overwrite mode).")
            # To cleanly overwrite, delete the old ZID-prefixed video and any associated subtitle/chapter files
            try:
                for f in out_dir.iterdir():
                    if f.is_file() and f.name.startswith(old_zid) and sanitized_title in f.name:
                        f.unlink()
                        log_detail(f"Removed old file: {f.name}")
            except Exception as e:
                log_warn(f"Failed to fully delete old duplicate files: {e}")
        else:
            # default: zid-dir
            if not zid_cache.get("value"):
                # Use current download's ZID as session ZID
                zid_cache["value"] = zid
            session_zid = zid_cache["value"]
            target_dir = out_dir / session_zid
            target_dir.mkdir(parents=True, exist_ok=True)
            target_path = target_dir / video_filename
            log_warn(f"File already exists ({existing_file.name}). Saving to subfolder: {target_path.name} (zid-dir mode).")

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
        sub_langs_list = resolve_subtitle_languages(pref_langs, info, emit_fallback_logs=True)

    output_tmpl = str(target_dir / f"{zid}-{sanitized_title}.%(ext)s")

    subtitle_download_failed = False
    pre_existing_subs = set()
    if download_subs:
        for lang in sub_langs_list:
            sub_file = target_dir / f"{zid}-{sanitized_title}.{lang}.srt"
            if sub_file.exists():
                pre_existing_subs.add(sub_file)

    # 5. Build and run subtitle download command (if needed)
    should_download_subs = (
        download_subs
        and bool(sub_langs_list)
        and (not is_skip_recovery or any_subs_missing)
    )
    if should_download_subs:
        sub_cmd = ["yt-dlp"]
        js_runtime = str(settings.get("youtube_download_js_runtime", "node")).strip()
        if js_runtime and js_runtime.lower() != "none":
            sub_cmd.extend(["--js-runtimes", js_runtime, "--remote-components", "ejs:github"])
        sub_cmd.extend(["--color", "always", "--skip-download", "--no-warnings", "-o", output_tmpl])
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
            log_info("Auto-subtitles will be downloaded.")
        sub_cmd.append(url)
        
        if has_manual or (has_auto and use_auto_subs):
            log_section(f"SUBTITLES DOWNLOAD ({','.join(sub_langs_list)})")
            try:
                run_subprocess_streaming(sub_cmd, check=True)
            except subprocess.CalledProcessError:
                if cookies_file or cookies_browser:
                    source_desc = f"file {cookies_file}" if cookies_file else f"browser {cookies_browser}"
                    log_warn(f"Subtitle download failed with cookies ({source_desc} might be open/locked).")
                    log_info("Retrying subtitle download without cookies...")
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
                        run_subprocess_streaming(fallback_sub_cmd, check=True)
                    except subprocess.CalledProcessError:
                        log_warn("Subtitle download skipped (network issue or 429 Too Many Requests).")
                        subtitle_download_failed = True
                else:
                    # Decoupled error handling: log warning and continue with video download
                    log_warn("Subtitle download skipped (network issue or 429 Too Many Requests).")
                    subtitle_download_failed = True
        else:
            log_info("No subtitles were available.")

    # 6. Build and run video download command (if needed)
    skip_video = is_skip_recovery
    if mode != "subtitles" and not skip_video:
        video_cmd = ["yt-dlp"]
        js_runtime = str(settings.get("youtube_download_js_runtime", "node")).strip()
        if js_runtime and js_runtime.lower() != "none":
            video_cmd.extend(["--js-runtimes", js_runtime, "--remote-components", "ejs:github"])
        video_cmd.extend(["--color", "always", "--no-warnings"])
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
        
        log_section(f"VIDEO DOWNLOAD ({settings['youtube_download_resolution']})")
        try:
            run_subprocess_streaming(video_cmd, check=True)
        except subprocess.CalledProcessError:
            if cookies_file or cookies_browser:
                source_desc = f"file {cookies_file}" if cookies_file else f"browser {cookies_browser}"
                log_warn(f"Video download failed with cookies ({source_desc} might be open/locked).")
                log_info("Retrying video download without cookies...")
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
                    run_subprocess_streaming(fallback_video_cmd, check=True)
                except subprocess.CalledProcessError:
                    log_error("yt-dlp video download failed.")
                    return False
            else:
                log_error("yt-dlp video download failed.")
                return False

    # 6. Save separate chapters if configured and present
    if save_chapters_file and has_chapters:
        chapters_path = target_dir / f"{zid}-{sanitized_title}.chapters.txt"
        save_separate_chapters(info.get("chapters", []), chapters_path)

    # 7. Print download results summary and verify actual file creation
    subtitles_newly_written = []
    subtitles_all_present = []
    if download_subs:
        for lang in sub_langs_list:
            sub_file = target_dir / f"{zid}-{sanitized_title}.{lang}.srt"
            if sub_file.exists():
                subtitles_all_present.append(sub_file)
                if sub_file not in pre_existing_subs:
                    clean_srt_file(
                        sub_file,
                        clean_hyphens=settings.get("youtube_download_clean_hyphens", False),
                        unbreak_lines=settings.get("youtube_download_unbreak_lines", False),
                        hyphenation_marks=settings.get("youtube_download_hyphenation_marks", "-¬"),
                        compositional_conjunctions=settings.get("youtube_download_compositional_conjunctions", "und,oder,sowie,bzw,bis"),
                        fix_sentence_splits=settings.get("youtube_download_fix_sentence_splits", False)
                    )
                    subtitles_newly_written.append(sub_file)

        # Re-timestamp secondary tracks to match the configured primary language's track.
        # subtitles_all_present is built in sub_langs_list order, but if the configured
        # primary language failed to download we must NOT silently promote a secondary
        # to primary — that would re-time everything against the wrong reference.
        if (
            settings.get("youtube_download_sync_secondary_timestamps", False)
            and len(subtitles_all_present) >= 2
            and subtitles_newly_written
        ):
            expected_primary = target_dir / f"{zid}-{sanitized_title}.{sub_langs_list[0]}.srt"
            if subtitles_all_present[0] == expected_primary:
                primary_sub = subtitles_all_present[0]
                for secondary_sub in subtitles_all_present[1:]:
                    sync_secondary_srt_timestamps(primary_sub, secondary_sub)
            else:
                log_warn(
                    f"Skipping subtitle sync: primary language '{sub_langs_list[0]}' "
                    f"is missing on disk; refusing to retime against a secondary track."
                )

    # 7a. Download companion audio tracks (audio-only MP4 per language for mpv audio-add)
    companion_audio_written = []
    comp_langs_str = settings.get("youtube_download_companion_audio_languages", "").strip()
    if comp_langs_str:
        comp_langs = [l.strip() for l in comp_langs_str.split(",") if l.strip()]
        for comp_lang in comp_langs:
            comp_file = target_dir / f"{zid}-{sanitized_title}.{comp_lang}.mp4"
            if comp_file.exists():
                log_skip(f"Companion audio '{comp_lang}' already exists — skipping.")
                continue
            if download_companion_audio(url, zid, sanitized_title, target_dir, comp_lang, info, settings):
                if comp_file.exists():
                    companion_audio_written.append(comp_file)

    if mode == "subtitles":
        if subtitles_all_present or not subtitle_download_failed:
            log_ok("Subtitles downloaded successfully.")
            for sub_file in subtitles_all_present:
                log_detail(f"Subtitle: {sub_file.name}")
            for comp_file in companion_audio_written:
                log_detail(f"Companion audio: {comp_file.name}")
        else:
            log_error("No subtitles were downloaded.")
            return False
    else:
        log_ok(f"Video downloaded: {_cyan(target_path.name)}")
        for sub_file in subtitles_all_present:
            log_detail(f"Subtitle: {sub_file.name}")
        for comp_file in companion_audio_written:
            log_detail(f"Companion audio: {comp_file.name}")

    return True

# ==============================================================================
# MAIN ENTRYPOINT
# ==============================================================================
def main():
    print(f"\n{_bold('Kardenwort YouTube Download Engine')} {_dim(f'(ZID: {get_current_zid()})')}\n", flush=True)
    
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
        log_error("No YouTube URLs detected in the input.")
        if args.pause:
            pause_console(success=False)
        sys.exit(1)

    log_info(f"Collected {_bold(str(len(queue)))} YouTube URL(s) to process:")
    for idx, (source, url, source_dir) in enumerate(queue):
        log_detail(f"{source} → {_dim(url)}")
    print(flush=True)

    # 3. Setup backend (check & update yt-dlp)
    log_info("Checking backend yt-dlp...", indent="")
    if not setup_backend(settings["youtube_download_auto_update"]):
        if args.pause:
            pause_console(success=False)
        sys.exit(1)
    log_ok("yt-dlp ready.")
    print(flush=True)

    # 4. Process queue
    used_zids = set()
    zid_cache = {}  # Shared session ZID cache for duplicate handling
    success_count = 0
    
    for idx, (source, url, source_dir) in enumerate(queue, 1):
        display_source = source
        if len(display_source) > 40:
            display_source = display_source[:18] + "..." + display_source[-20:]
        log_section(f"[{idx}/{len(queue)}] {display_source}")
        try:
            if download_video_and_metadata(url, settings, used_zids, zid_cache, source_dir=source_dir):
                success_count += 1
        except Exception as e:
            log_error(f"Unhandled error while processing: {e}")

    if success_count == len(queue):
        log_ok(f"All {success_count}/{len(queue)} URL(s) processed successfully.")
    else:
        log_warn(f"Processed {success_count}/{len(queue)} URL(s). {len(queue) - success_count} failed.")
    
    if args.pause:
        timeout_val = settings.get("youtube_download_auto_close_timeout_secs", "").strip()
        timeout: Optional[int]
        if not timeout_val:
            timeout = None
        else:
            try:
                timeout = int(timeout_val)
            except Exception:
                timeout = PAUSE_AUTO_CLOSE_TIMEOUT_SECS
        pause_console(success=(success_count == len(queue)), timeout_secs=timeout)

if __name__ == "__main__":
    main()
