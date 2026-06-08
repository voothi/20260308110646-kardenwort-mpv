#!/usr/bin/env python
# ==============================================================================
# Kardenwort Subtitle Translator
# Translates subtitles (.srt or .txt) to declarative target languages.
#
# Usage (CLI):
#   python subtitle_translator.py my_subtitle.srt
#   python subtitle_translator.py 20260608102024-my_subtitle.en.srt
#
# Installation (Windows SendTo):
#   python install.py
# ==============================================================================

import argparse
import configparser
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path
from typing import List, Tuple, Optional

# ==============================================================================
# GLOBAL CONSTANTS
# ==============================================================================
SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_FILE = SCRIPT_DIR / "config.ini"
PAUSE_AUTO_CLOSE_TIMEOUT_SECS = 15
RELATED_MEDIA_EXTENSIONS = ("mp4", "mp3", "m4a", "wav", "flac", "aac", "ogg", "opus", "mkv", "webm", "mov", "avi")
VALID_DUPLICATE_MODES = ("skip", "overwrite", "archive")
MERGE_SPLIT_MARKER_PREFIX = "[[KWSPLIT"
MERGE_SPLIT_MARKER_SUFFIX = "]]"

# Path to the ZID script; overridden from config via load_config()
_ZID_SCRIPT: str = ""

DEFAULT_OLLAMA_JSON_PROMPT = "Translate the JSON array of strings from {source_lang} to {target_lang}. Output ONLY the translated JSON array of strings, without any markdown formatting, code block markers, explanations, or preamble."
DEFAULT_OLLAMA_PROMPT_FEEDBACK_TEMPLATE = "[Feedback from previous attempt: {last_error}]"

# ==============================================================================
# CONSOLE OUTPUT HELPERS (Pip/youtube-downloader style)
# ==============================================================================
_IS_TTY = sys.stdout.isatty()

# ANSI escape sequence remover
ANSI_ESCAPE = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')

def strip_ansi(text: str) -> str:
    """Removes all VT100 / ANSI escape sequences from the given text."""
    return ANSI_ESCAPE.sub('', text)

def _c(code, text):
    """Wraps text in an ANSI escape if stdout is a TTY."""
    return f"\x1b[{code}m{text}\x1b[0m" if _IS_TTY else text

def _tag_info():    return _c("1;36", "[INFO]")    # bold cyan
def _tag_warn():    return _c("1;33", "[WARN]")    # bold yellow
def _tag_error():   return _c("1;31", "[ERROR]")   # bold red
def _tag_ok():      return _c("1;32", "[OK]")      # bold green
def _tag_skip():    return _c("1;35", "[SKIP]")    # bold magenta
def _tag_sync():    return _c("1;36", "[SYNC]")    # bold cyan
def _tag_rescue():  return _c("1;35", "[RESCUE]")  # bold magenta

def _dim(text):     return _c("90", text)          # dim grey
def _bold(text):    return _c("1", text)           # bold white
def _cyan(text):    return _c("36", text)          # cyan
def _green(text):   return _c("32", text)          # green
def _yellow(text):  return _c("33", text)          # yellow

def log_info(msg, indent=""):
    print(f"{indent}{_tag_info()} {msg}", flush=True)

def log_warn(msg, indent=""):
    print(f"{indent}{_tag_warn()} {msg}", flush=True)

def log_error(msg, indent=""):
    print(f"{indent}{_tag_error()} {msg}", file=sys.stderr, flush=True)

def log_ok(msg, indent=""):
    print(f"{indent}{_tag_ok()} {msg}", flush=True)

def log_skip(msg, indent=""):
    print(f"{indent}{_tag_skip()} {msg}", flush=True)

def log_rescue(msg, indent=""):
    print(f"{indent}{_tag_rescue()} {msg}", flush=True)

def log_detail(msg, indent="  "):
    print(f"{indent}{_dim('·')} {msg}", flush=True)

def log_section(title):
    print(f"\n{_bold(title)}", flush=True)

def compact_log_text(text: str, max_chars: int = 220) -> str:
    """Returns a single-line preview suitable for noisy model responses."""
    text = text.replace("\r\n", "\\n").replace("\r", "\\n").replace("\n", "\\n")
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) <= max_chars:
        return text
    return text[: max_chars - 3].rstrip() + "..."

def format_validation_error_for_log(error: Exception) -> Tuple[str, Optional[str]]:
    """Splits validation errors into a short cause and optional model response preview."""
    message = str(error)
    marker = "Response was:"
    if marker not in message:
        return compact_log_text(message), None

    cause, response = message.split(marker, 1)
    cause = compact_log_text(cause.strip().rstrip("."))
    response_preview = compact_log_text(response, max_chars=260)
    return cause, response_preview

def clear_line(width=65):
    sys.stdout.write("\r\x1b[K" + " " * width + "\r")
    sys.stdout.flush()

def pause_console(success: bool = True, timeout_secs: Optional[int] = PAUSE_AUTO_CLOSE_TIMEOUT_SECS):
    """Pauses the console window for inspection."""
    if not success or timeout_secs is None:
        try:
            input("\nPress Enter to exit...")
        except Exception:
            pass
        return

    print(f"\nPress Enter to exit (or wait {timeout_secs}s for auto-close)...", end="", flush=True)
    is_windows = sys.platform.startswith("win")
    if is_windows and _IS_TTY:
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
        clear_line()
    else:
        try:
            input("\nPress Enter to exit...")
        except Exception:
            pass

def make_translation_progress_bar(translated_count: int, total_count: int, indent: str = "    ") -> str:
    """Generates a premium CLI progress bar."""
    bar_width = 30
    percent_val = (translated_count / total_count) * 100 if total_count > 0 else 100
    filled_width = int(round(bar_width * percent_val / 100.0))
    bar = _green("━" * filled_width) + _dim("━" * (bar_width - filled_width))
    progress_text = f"{translated_count}/{total_count} lines ({percent_val:.1f}%)"
    return f"\r{indent}{bar} {_cyan(progress_text)}"


# ==============================================================================
# CONFIGURATION LOADING
# ==============================================================================
def load_config():
    """Loads configuration settings, falling back to defaults."""
    config = configparser.ConfigParser()
    defaults = {
        "subtitle_translator_zid_script": "",
        "subtitle_translator_target_languages": "ru,de",
        "subtitle_translator_source_language": "en",
        "subtitle_translator_provider": "google",
        "subtitle_translator_duplicate_mode": "skip",
        "subtitle_translator_rename_source_with_zid": "false",
        "subtitle_translator_rename_related_media_with_zid": "false",
        "google_api_url": "https://translate.googleapis.com/translate_a/single",
        "deepl_api_key": "",
        "deepl_api_url": "https://api-free.deepl.com/v2/translate",
        "deepl_formality": "default",
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "llama3",
        "ollama_prompt": "Translate the following text from {source_lang} to {target_lang}. Output ONLY the raw translation, without any explanations, preamble, introductory remarks, or formatting. Preserve the line breaks.",
        "ollama_prompt_salt": "false",
        "ollama_prompt_feedback": "false",
        "ollama_json_format": "false",
        "ollama_json_schema": "dict_of_strings",
        "ollama_json_prompt": DEFAULT_OLLAMA_JSON_PROMPT,
        "ollama_prompt_feedback_template": DEFAULT_OLLAMA_PROMPT_FEEDBACK_TEMPLATE,
        "subtitle_translator_chunk_size": "5",
        "subtitle_translator_max_retries": "3",
        "subtitle_translator_verbose_validation_errors": "false",
        "subtitle_translator_word_count_check": "false",
        "subtitle_translator_word_count_min_ratio": "0.25",
        "subtitle_translator_word_count_max_ratio": "3.5",
        "subtitle_translator_save_partial_on_failure": "false",
        "subtitle_translator_clean_markdown": "true",
        "subtitle_translator_merge_lines": "false",
        "subtitle_translator_merge_split_mode": "marker",
        "subtitle_translator_merge_max_gap_ms": "1000",
        "youtube_download_auto_close_timeout_secs": "15",
    }

    if CONFIG_FILE.exists():
        try:
            config.read(CONFIG_FILE, encoding="utf-8")
        except Exception as e:
            print(f"Warning: Error reading config.ini: {e}. Using default settings.", file=sys.stderr)
            
    settings = {}
    for key, def_val in defaults.items():
        settings[key] = config.get("Settings", key, fallback=def_val).strip()

    # Propagate ZID script
    global _ZID_SCRIPT
    _ZID_SCRIPT = os.path.expandvars(settings["subtitle_translator_zid_script"])

    return settings

# ==============================================================================
# ZID GENERATION
# ==============================================================================
def get_current_zid() -> str:
    """Invokes system ZID script to retrieve timestamp or falls back to system time."""
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

def get_prompt_salt(phrase: str, attempt: int) -> str:
    """Generates a unique salt phrase based on the configured template and retry attempt."""
    if attempt <= 1 or not phrase or phrase.strip().lower() in ("false", "none", "no", "0"):
        return ""
    phrase = phrase.strip()
    match = re.match(r"^(.*?)\[(.*?)\](.*)$", phrase)
    if match:
        prefix = match.group(1)
        repeat_part = match.group(2)
        suffix = match.group(3)
        return prefix + ", ".join([repeat_part] * (attempt - 1)) + suffix
    return ", ".join([phrase] * (attempt - 1))

# ==============================================================================
# FILENAME PARSING
# ==============================================================================
def parse_filename(file_path: Path) -> Tuple[Optional[str], str, Optional[str], str]:
    """Parses a filename to extract ZID, title, source language, and extension."""
    name = file_path.name
    ext = file_path.suffix.lstrip('.')
    stem = file_path.stem

    # 1. Match ZID (14 digits)
    zid_match = re.match(r'^(\d{14})-(.*)$', name)
    if zid_match:
        zid = zid_match.group(1)
        remaining = zid_match.group(2)
        if remaining.endswith('.' + ext):
            remaining_stem = remaining[:-len('.' + ext)]
        else:
            remaining_stem = remaining
    else:
        zid = None
        remaining_stem = stem

    # 2. Match language code suffix (.en, .ru, etc. before the extension)
    lang_match = re.search(r'\.([a-zA-Z]{2,3}(?:-[a-zA-Z]{2,4})?)$', remaining_stem)
    if lang_match:
        lang = lang_match.group(1)
        clean_title = remaining_stem[:-len('.' + lang)]
    else:
        lang = None
        clean_title = remaining_stem

    return zid, clean_title, lang, ext

def normalize_media_title(title: str) -> str:
    """Normalizes a media title for related-file matching."""
    return re.sub(r'[^a-z0-9]+', '', title.lower())

def find_related_media_files(folder: Path, clean_title: str) -> List[Path]:
    """Finds related media files in the same folder with the same or equivalent clean title."""
    matches: List[Path] = []
    seen = set()

    def add_match(candidate: Path):
        candidate_key = str(candidate).lower()
        if candidate_key not in seen:
            seen.add(candidate_key)
            matches.append(candidate)

    try:
        candidates = [
            candidate
            for ext in RELATED_MEDIA_EXTENSIONS
            for candidate in folder.glob(f"*.{ext}")
        ]
        normalized_clean_title = normalize_media_title(clean_title)

        for candidate in candidates:
            _zid, candidate_title, _lang, _ext = parse_filename(candidate)
            if candidate_title == clean_title:
                add_match(candidate)

        for candidate in candidates:
            _zid, candidate_title, _lang, _ext = parse_filename(candidate)
            if normalize_media_title(candidate_title) == normalized_clean_title:
                add_match(candidate)

        if not matches and len(candidates) == 1:
            log_detail(f"Using the only media file in folder as related file: {candidates[0].name}")
            add_match(candidates[0])
    except Exception:
        pass

    return matches

def rollback_renamed_paths(renamed_paths: List[Tuple[Path, Path]]):
    """Restores renamed paths in reverse order."""
    for current_path, original_path in reversed(renamed_paths):
        if not current_path.exists():
            continue
        if original_path.exists():
            log_warn(f"Rollback skipped because original path already exists: {original_path.name}")
            continue
        try:
            current_path.rename(original_path)
            log_info(f"Rolled back renamed file: {original_path.name}")
        except Exception as rollback_err:
            log_warn(f"Failed to rollback renamed file '{current_path.name}': {rollback_err}")

def rename_related_media_with_zid(folder: Path, clean_title: str, zid: str) -> Tuple[bool, List[Tuple[Path, Path]]]:
    """Adds the given ZID to matching media files, unless they already have a ZID."""
    related_paths = find_related_media_files(folder, clean_title)
    if not related_paths:
        log_detail(f"No related media file found for: {clean_title}")
        return True, []

    renamed_paths: List[Tuple[Path, Path]] = []

    for related_path in related_paths:
        related_zid, related_title, related_lang, related_ext = parse_filename(related_path)
        if related_zid:
            log_info(f"Related media file already has ZID; leaving unchanged: {related_path.name}")
            continue

        related_stem = related_title
        if related_lang:
            related_stem = f"{related_stem}.{related_lang}"
        new_name = f"{zid}-{related_stem}.{related_ext}"
        new_path = related_path.parent / new_name
        if new_path.exists():
            log_error(f"Cannot rename related media file; target already exists: {new_name}")
            rollback_renamed_paths(renamed_paths)
            return False, []

        try:
            related_path.rename(new_path)
            log_info(f"Renamed related media file to include ZID: {new_name}")
            renamed_paths.append((new_path, related_path))
        except Exception as e:
            log_error(f"Failed to rename related media file to include ZID: {e}")
            rollback_renamed_paths(renamed_paths)
            return False, []

    return True, renamed_paths

def get_duplicate_mode(settings: dict) -> str:
    """Returns a validated duplicate mode from settings."""
    duplicate_mode = settings.get("subtitle_translator_duplicate_mode", "skip").strip().lower()
    if duplicate_mode not in VALID_DUPLICATE_MODES:
        raise ValueError(
            f"Invalid subtitle_translator_duplicate_mode: {duplicate_mode}. "
            f"Expected one of: {', '.join(VALID_DUPLICATE_MODES)}"
        )
    return duplicate_mode

def archive_existing_target(target_path: Path, session_zid: str) -> Path:
    """Moves an existing target file into the session archive directory."""
    archive_dir = target_path.parent / session_zid
    archive_dir.mkdir(parents=True, exist_ok=True)
    archive_target_path = archive_dir / target_path.name

    if archive_target_path.exists():
        archive_target_path.unlink()

    target_path.rename(archive_target_path)
    return archive_target_path

def write_output_file(target_path: Path, content: str, duplicate_mode: str, session_zid: str, log_label: str) -> None:
    """Writes output content while preserving overwrite/archive semantics."""
    archived_target_path: Optional[Path] = None

    if target_path.exists():
        if duplicate_mode == "skip":
            raise RuntimeError(f"{log_label} skipped because target already exists: {target_path.name}")
        if duplicate_mode == "overwrite":
            log_info(f"{log_label} already exists. Overwriting...")
        elif duplicate_mode == "archive":
            log_warn(f"{log_label} already exists. Archiving old file to: {session_zid}/{target_path.name}")
            archived_target_path = archive_existing_target(target_path, session_zid)

    try:
        target_path.write_text(content, encoding="utf-8", newline="\n")
    except Exception:
        if archived_target_path and archived_target_path.exists() and not target_path.exists():
            try:
                archived_target_path.rename(target_path)
                log_info(f"Restored archived file after write failure: {target_path.name}")
            except Exception as restore_err:
                log_warn(f"Failed to restore archived file after write failure: {restore_err}")
        raise

# ==============================================================================
# SRT & TXT PARSERS
# ==============================================================================
def parse_srt(content: str) -> List[dict]:
    """Parses SRT content into structured blocks."""
    content = content.replace('\r\n', '\n').replace('\r', '\n')
    lines = content.split('\n')
    
    blocks = []
    current_block_lines = []
    
    for line in lines:
        if line.strip() == "":
            if current_block_lines:
                blocks.append(current_block_lines)
                current_block_lines = []
        else:
            current_block_lines.append(line)
    if current_block_lines:
        blocks.append(current_block_lines)
        
    parsed_blocks = []
    for block_lines in blocks:
        index = ""
        timeline = ""
        text_lines = []
        
        if len(block_lines) > 0:
            first = block_lines[0].strip()
            if first.isdigit():
                index = first
                if len(block_lines) > 1 and '-->' in block_lines[1]:
                    timeline = block_lines[1].strip()
                    text_lines = block_lines[2:]
                else:
                    text_lines = block_lines[1:]
            elif '-->' in first:
                timeline = first
                text_lines = block_lines[1:]
            else:
                text_lines = block_lines
                
        parsed_blocks.append({
            'index': index,
            'timeline': timeline,
            'text_lines': [t.strip() for t in text_lines]
        })
        
    return parsed_blocks

def write_srt(blocks: List[dict]) -> str:
    """Reconstructs SRT format from blocks list."""
    out = []
    for idx, block in enumerate(blocks, 1):
        index = block['index'] if block['index'] else str(idx)
        out.append(index)
        if block['timeline']:
            out.append(block['timeline'])
        for text in block['text_lines']:
            out.append(text)
        out.append("")
    return "\n".join(out)

def clean_subtitle_text(text: str, clean_markdown: bool = True) -> str:
    """Strips all HTML-like tags, ASS formatting tags, markdown styles, and inner line breaks, keeping only pure text."""
    if not text:
        return ""
    # Remove HTML-like tags (e.g. <i>, <b>, <font...>, </font>, etc.)
    text = re.sub(r'<[^>]+>', '', text)
    # Remove ASS formatting tags (e.g. {\an8}, {\pos(100,100)}, etc.)
    text = re.sub(r'\{[^}]+\}', '', text)
    if clean_markdown:
        # Replace paired markdown markers, then remove dangling markers commonly
        # produced by small models (e.g. "translation.**").
        text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)
        text = re.sub(r'\*([^*]+)\*', r'\1', text)
        text = re.sub(r'__([^_]+)__', r'\1', text)
        text = re.sub(r'_([^_]+)_', r'\1', text)
        text = text.replace('**', '').replace('__', '').replace('*', '').replace('_', '')
    # Replace any literal newlines, carriage returns, or tabs with spaces
    text = text.replace('\r\n', ' ').replace('\n', ' ').replace('\r', ' ').replace('\t', ' ')
    # Normalize multiple consecutive spaces to a single space
    text = re.sub(r'\s+', ' ', text)
    return text.strip()

_SENTENCE_ENDINGS = frozenset({'.', '?', '!', ':'})

# ==============================================================================
# SRT TIMECODE HELPERS (for merge-and-split mode)
# ==============================================================================
def parse_timecode(tc: str) -> int:
    """Converts an SRT timestamp string (HH:MM:SS,mmm) to milliseconds."""
    tc = tc.strip().replace(',', '.')
    parts = tc.split(':')
    if len(parts) != 3:
        raise ValueError(f"Invalid timecode: {tc!r}")
    hours = int(parts[0])
    minutes = int(parts[1])
    sec_parts = parts[2].split('.')
    seconds = int(sec_parts[0])
    millis = int(sec_parts[1]) if len(sec_parts) > 1 else 0
    return hours * 3_600_000 + minutes * 60_000 + seconds * 1_000 + millis

def parse_timeline(timeline: str) -> Tuple[int, int]:
    """Extracts start and end milliseconds from an SRT timeline string."""
    parts = timeline.split('-->')
    if len(parts) != 2:
        raise ValueError(f"Invalid timeline: {timeline!r}")
    return parse_timecode(parts[0]), parse_timecode(parts[1])

def build_merge_groups(blocks: List[dict], max_gap_ms: int) -> List[List[int]]:
    """Groups consecutive block indices that should be merged for translation.

    Two adjacent blocks are merged when ALL of the following hold:
      1. Both have non-empty text.
      2. Both have parseable timelines.
      3. The gap between previous block end and current block start < max_gap_ms.
      4. The previous block text does NOT end with sentence-ending punctuation (. ? ! :).
    """
    if not blocks:
        return []
    groups: List[List[int]] = []
    current: List[int] = [0]
    for i in range(1, len(blocks)):
        prev_block = blocks[i - 1]
        curr_block = blocks[i]
        prev_text = (prev_block['text_lines'][0] if prev_block['text_lines'] else '').strip()
        curr_text = (curr_block['text_lines'][0] if curr_block['text_lines'] else '').strip()
        # Don't merge if either block is empty
        if not prev_text or not curr_text:
            groups.append(current)
            current = [i]
            continue
        # Don't merge if timelines are missing or invalid
        if not prev_block.get('timeline') or not curr_block.get('timeline'):
            groups.append(current)
            current = [i]
            continue
        try:
            _, prev_end_ms = parse_timeline(prev_block['timeline'])
            curr_start_ms, _ = parse_timeline(curr_block['timeline'])
        except Exception:
            groups.append(current)
            current = [i]
            continue
        gap_ms = curr_start_ms - prev_end_ms
        # Merge only when gap is small AND previous text doesn't end a sentence
        if gap_ms < max_gap_ms and prev_text[-1] not in _SENTENCE_ENDINGS:
            current.append(i)
        else:
            groups.append(current)
            current = [i]
    if current:
        groups.append(current)
    return groups

def make_merge_split_marker(index: int) -> str:
    return f"{MERGE_SPLIT_MARKER_PREFIX}{index:04d}{MERGE_SPLIT_MARKER_SUFFIX}"

def join_merged_group_texts(group_texts: List[str]) -> Tuple[str, List[str]]:
    """Joins merged subtitle blocks with exact split markers between blocks."""
    if not group_texts:
        return "", []

    parts: List[str] = []
    markers: List[str] = []
    for idx, text in enumerate(group_texts):
        if idx > 0:
            marker = make_merge_split_marker(idx)
            markers.append(marker)
            parts.append(marker)
        if text:
            parts.append(text)
    return " ".join(parts), markers

def split_merged_text_by_markers(text: str, markers: List[str]) -> List[str]:
    """Splits translated merge text by exact markers inserted before translation."""
    if not markers:
        return [text.strip()]

    parts: List[str] = []
    remaining = text
    for marker in markers:
        marker_idx = remaining.find(marker)
        if marker_idx < 0:
            raise ValueError(f"Missing merge split marker in translated text: {marker}")
        parts.append(remaining[:marker_idx].strip())
        remaining = remaining[marker_idx + len(marker):]
    parts.append(remaining.strip())
    return parts

def split_by_proportion(text: str, lengths: List[int]) -> List[str]:
    """Compatibility splitter for merge mode when exact markers are disabled."""
    if not text or not lengths:
        return [text.strip()] if text else []
    if len(lengths) == 1:
        return [text.strip()]
    total = sum(lengths)
    if total == 0:
        n = len(lengths)
        equal = len(text) // n
        return [text[i * equal:(i + 1) * equal].strip() for i in range(n - 1)] + [text[(n - 1) * equal:].strip()]
    parts: List[str] = []
    remaining = text.strip()
    remaining_total = total
    for i, length in enumerate(lengths):
        if i == len(lengths) - 1:
            parts.append(remaining.strip())
            break
        if not remaining:
            parts.extend([''] * (len(lengths) - i))
            break
        target_idx = int(round(len(remaining) * length / remaining_total))
        target_idx = max(1, min(target_idx, len(remaining) - 1))
        search_window = max(target_idx, len(remaining) - target_idx)
        split_idx = None
        for offset in range(search_window + 1):
            for candidate in (target_idx - offset, target_idx + offset):
                if 1 <= candidate < len(remaining) - 1 and remaining[candidate] == ' ':
                    split_idx = candidate
                    break
            if split_idx is not None:
                break
        if split_idx is None:
            split_idx = target_idx
        parts.append(remaining[:split_idx].strip())
        remaining = remaining[split_idx:].strip()
        remaining_total -= length
    return parts

def get_merge_split_mode(settings: dict) -> str:
    mode = settings.get("subtitle_translator_merge_split_mode", "marker").strip().lower()
    if mode not in ("marker", "proportional"):
        raise ValueError(
            f"Invalid subtitle_translator_merge_split_mode: {mode}. "
            "Expected one of: marker, proportional"
        )
    return mode


# ==============================================================================
# LANGUAGE CODE → ENGLISH NAME LOOKUP
# Source: Subtitle Edit ChatGptTranslate.ListLanguages() — used in LLM prompts
# so small models receive "Russian" instead of the BCP-47 code "ru".
# Google/DeepL still use the raw codes for their API parameters.
# ==============================================================================
_LANG_CODE_TO_NAME: dict = {
    "ab": "Abkhaz", "ace": "Acehnese", "ach": "Acholi", "aa": "Afar",
    "af": "Afrikaans", "ahr": "Ahirani", "sq": "Albanian", "alz": "Alur",
    "am": "Amharic", "ar": "Arabic", "hy": "Armenian", "as": "Assamese",
    "aii": "Assyrian Neo-Aramaic", "av": "Avar", "awa": "Awadhi",
    "az": "Azerbaijani", "ay": "Aymara", "bfq": "Badaga", "bfy": "Bagheli",
    "bgq": "Bagri", "ban": "Balinese", "bal": "Baluchi", "bm": "Bambara",
    "bjn": "Banjar", "bjn-Arab": "Banjar (Arabic script)", "bci": "Baoulé",
    "ba": "Bashkir", "eu": "Basque", "btx": "Batak Karo",
    "bts": "Batak Simalungun", "bbc": "Batak Toba", "be": "Belarusian",
    "bem": "Bemba (Zambia)", "bn": "Bengali", "bew": "Betawi",
    "bho": "Bhojpuri", "bik": "Bikol", "brx": "Bodo (India)", "bs": "Bosnian",
    "bra": "Braj", "pt-BR": "Brazilian Portuguese", "br": "Breton",
    "bug": "Buginese", "bg": "Bulgarian", "bns": "Bundeli", "bua": "Buryat",
    "yue": "Cantonese", "ca": "Catalan", "ckb": "Central Kurdish (Sorani)",
    "ccp-Latn": "Chakma (Latin script)", "ch": "Chamorro", "ce": "Chechen",
    "hne": "Chhattisgarhi", "ny": "Chichewa", "zh-CN": "Chinese (Simplified)",
    "zh-Hant": "Chinese (Traditional)", "zh": "Chinese", "ctg": "Chittagonian",
    "chk": "Chuukese", "cv": "Chuvash", "crh": "Crimean Tatar",
    "crh-Latn": "Crimean Tatar (Latin script)", "hr": "Croatian", "cs": "Czech",
    "da": "Danish", "fa-AF": "Dari", "dv": "Dhivehi", "dhd": "Dhundari",
    "din": "Dinka", "doi": "Dogri", "dov": "Dombe", "nl": "Dutch",
    "dyu": "Dyula", "dz": "Dzongkha", "kbd": "East Circassian",
    "nhe": "Eastern Huasteca Nahuatl", "efi": "Efik", "arz": "Egyptian Arabic",
    "en": "English", "et": "Estonian", "ee": "Ewe", "fo": "Faroese",
    "fj": "Fijian", "fi": "Finnish", "fon": "Fon", "fr": "French",
    "fur": "Friulian", "ff": "Fulani", "gaa": "Ga", "gl": "Galician",
    "grt-Latn": "Garo (Latin script)", "ka": "Georgian", "de": "German",
    "gom": "Goan Konkani", "el": "Greek", "gn": "Guarani", "gu": "Gujarati",
    "cnh": "Hakha Chin", "bgc": "Haryanvi", "ha": "Hausa", "he": "Hebrew",
    "hil": "Hiligaynon", "hi": "Hindi", "hoc-Wara": "Ho (Warang Chiti script)",
    "hu": "Hungarian", "hrx": "Hunsrik", "iba": "Iban", "is": "Icelandic",
    "ig": "Igbo", "ilo": "Ilocano", "id": "Indonesian",
    "iu": "Inuktut (Syllabics)", "ga": "Irish", "iso": "Isoko", "it": "Italian",
    "jam": "Jamaican Patois", "ja": "Japanese", "jv": "Javanese",
    "kac": "Jingpo", "quc": "K'iche'", "kl": "Kalaallisut", "kn": "Kannada",
    "xnr": "Kangri", "kr": "Kanuri", "pam": "Kapampangan", "kaa": "Karakalpak",
    "ks": "Kashmiri", "ks-Deva": "Kashmiri (Devanagari script)",
    "kk": "Kazakh", "meo": "Kedah Malay", "kha": "Khasi", "km": "Khmer",
    "cgg": "Kiga", "ki": "Kikuyu", "lu": "Kiluba", "rw": "Kinyarwanda",
    "ktu": "Kituba", "trp": "Kokborok", "kv": "Komi", "kg": "Kongo",
    "ko": "Korean", "kri": "Krio", "kfy": "Kumaoni", "ku": "Kurdish",
    "kru": "Kurukh", "ky": "Kyrgyz", "pa-Arab": "Lahnda Punjabi (Pakistan)",
    "ltg": "Latgalian", "lv": "Latvian", "lep": "Lepcha", "ayl": "Libyan Arabic",
    "lij": "Ligurian", "lif-Limb": "Limbu", "li": "Limburgish",
    "ln": "Lingala", "lt": "Lithuanian", "lmo": "Lombard", "lg": "Luganda",
    "luo": "Luo", "mk": "Macedonian", "mad": "Madurese", "mag": "Magahi",
    "mai": "Maithili", "mak": "Makassar", "mg": "Malagasy", "ms": "Malay",
    "ms-Arab": "Malay (Jawi Script)", "mt": "Maltese", "mam": "Mam",
    "mjl": "Mandeali", "gv": "Manx", "arn": "Mapudungun", "mr": "Marathi",
    "mh": "Marshallese", "mwr": "Marwari", "mfe": "Mauritian Creole",
    "chm": "Meadow Mari", "mni-Mtei": "Meiteilon (Manipuri)", "mtr": "Mewari",
    "nan": "Min Nan", "min": "Minang", "lus": "Mizo", "mn": "Mongolian",
    "cnr": "Montenegrin", "mos": "Moore", "ar-MA": "Moroccan Arabic",
    "unr-Deva": "Mundari (Devanagari script)", "my": "Myanmar (Burmese)",
    "nv": "Navajo", "ndc-ZW": "Ndau", "new": "Nepalbhasa (Newari)",
    "ne": "Nepali", "pcm": "Nigerian Pidgin", "noe": "Nimadi",
    "bm-Nkoo": "NKo", "apc": "North Levantine Arabic", "nd": "North Ndebele",
    "se": "Northern Sami", "no": "Norwegian", "nus": "Nuer", "oc": "Occitan",
    "or": "Oriya", "om": "Oromo", "os": "Ossetian", "pag": "Pangasinan",
    "pap": "Papiamento", "ps": "Pashto", "fa": "Persian", "pl": "Polish",
    "pt": "Portuguese", "pa": "Punjabi", "kek": "Q'eqchi'", "qu": "Quechua",
    "raj": "Rajasthani", "rhg-Latn": "Rohingya (Latin script)", "rom": "Romani",
    "ro": "Romanian", "rn": "Rundi", "ru": "Russian", "spv": "Sambalpuri",
    "sg": "Sango", "sa": "Sanskrit", "sat-Latn": "Santali", "skr": "Saraiki",
    "nso": "Sepedi", "sr": "Serbian", "st": "Sesotho", "crs": "Seychellois Creole",
    "shn": "Shan", "xsr-Tibt": "Sherpa (Tibetan script)", "scl": "Shina",
    "sn": "Shona", "scn": "Sicilian", "szl": "Silesian", "sd": "Sindhi",
    "sd-Deva": "Sindhi (Devanagari script)", "si": "Sinhala", "sk": "Slovak",
    "sl": "Slovenian", "so": "Somali", "nr": "South Ndebele", "es": "Spanish",
    "es-419": "Spanish (Latin America)", "apd": "Sudanese Arabic",
    "sgj": "Surgujia", "sjp": "Surjapuri", "sus": "Susu", "sw": "Swahili",
    "ss": "Swati", "sv": "Swedish", "syl": "Sylheti", "ty": "Tahitian",
    "ber-Latn": "Tamazight (Latin Script)", "ber": "Tamazight (Tifinagh Script)",
    "tt": "Tatar", "tet": "Tetum", "th": "Thai", "bo": "Tibetan",
    "ti": "Tigrinya", "tiv": "Tiv", "tpi": "Tok Pisin", "to": "Tonga",
    "ts": "Tsonga", "tn": "Tswana", "tcy": "Tulu", "tum": "Tumbuka",
    "aeb": "Tunisian Arabic", "tr": "Turkish", "tyv": "Tuvan", "ak": "Twi",
    "udm": "Udmurt", "uk": "Ukrainian", "ur": "Urdu", "ug": "Uyghur",
    "uz": "Uzbek", "ve": "Venda", "vec": "Venetian", "vi": "Vietnamese",
    "wbr": "Wagdi", "war": "Waray", "cy": "Welsh", "ady": "West Circassian",
    "wo": "Wolof", "wuu": "Wu Chinese", "xh": "Xhosa", "sah": "Yakut",
    "yo": "Yoruba", "yua": "Yucatec Maya", "zap": "Zapotec",
}

def lang_code_to_name(code: str) -> str:
    """Returns the English language name for a BCP-47 code (e.g. 'ru' → 'Russian').
    Falls back to the code itself when the code is not in the lookup table.
    Used to build human-readable prompts for LLM providers."""
    return _LANG_CODE_TO_NAME.get(code, code)


# ==============================================================================
# EXCEPTIONS
# ==============================================================================
class ChunkValidationError(RuntimeError):
    """Raised when chunk validation fails after all retries.
    
    Carries the partially translated lines built up to the failing chunk.
    Failed/untranslated positions remain as empty strings, producing blank
    subtitle entries in the output (timecodes are preserved, text is empty).
    """
    def __init__(self, message: str, partial_lines: List[str]):
        super().__init__(message)
        self.partial_lines = partial_lines

# ==============================================================================
# TRANSLATION PROVIDERS
# ==============================================================================
def google_translate_v1(text: str, sl: str, tl: str, api_url: str) -> str:
    """Google Translate free V1 API caller."""
    url = f"{api_url}?client=gtx&sl={sl}&tl={tl}&dt=t&q={urllib.parse.quote(text)}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            body = response.read().decode('utf-8')
            data = json.loads(body)
            
            # Reconstruct segments
            translated_segments = []
            if data and data[0]:
                for segment in data[0]:
                    if segment and len(segment) > 0 and segment[0]:
                        translated_segments.append(segment[0])
            return "".join(translated_segments)
    except Exception as e:
        raise Exception(f"Google Translate request failed: {e}")

def deepl_translate_v2(lines: List[str], sl: str, tl: str, settings: dict) -> List[str]:
    """DeepL Translation API caller."""
    api_key = settings.get("deepl_api_key", "").strip()
    api_url = settings.get("deepl_api_url", "").strip()
    formality = settings.get("deepl_formality", "default").strip()

    if not api_key:
        raise ValueError("DeepL API key (deepl_api_key) is not configured in config.ini")
    if not api_url:
        raise ValueError("DeepL API URL (deepl_api_url) is not configured in config.ini")

    # Clean BCP-47 language codes for DeepL API compatibility
    sl_clean = sl.split('-')[0].upper()
    tl_clean = tl.upper()

    params = [('target_lang', tl_clean), ('source_lang', sl_clean)]
    if formality and formality.lower() != 'default':
        params.append(('formality', formality.lower()))

    for line in lines:
        params.append(('text', line))

    data = urllib.parse.urlencode(params).encode('utf-8')
    req = urllib.request.Request(api_url, data=data)
    req.add_header("Authorization", f"DeepL-Auth-Key {api_key}")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    req.add_header("User-Agent", "Mozilla/5.0")

    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            body = response.read().decode('utf-8')
            resp_data = json.loads(body)
            translations = resp_data.get("translations", [])
            return [t.get("text", "") for t in translations]
    except Exception as e:
        raise Exception(f"DeepL Translate request failed: {e}")

def ollama_translate(text: str, sl: str, tl: str, settings: dict, salt: str = "", feedback: str = "") -> str:
    """Ollama API caller with optional structured JSON mode."""
    api_url = settings.get("ollama_api_url", "").strip()
    model = settings.get("ollama_model", "").strip()
    
    json_enabled = settings.get("ollama_json_format", "false").lower() == "true"
    is_chunk = "\n" in text

    if json_enabled and is_chunk:
        prompt_template = settings.get("ollama_json_prompt", "").strip()
        schema = settings.get("ollama_json_schema", "dict_of_strings").strip().lower()
        
        if not prompt_template or prompt_template == DEFAULT_OLLAMA_JSON_PROMPT:
            if schema == "dict_of_strings":
                prompt_template = (
                    "Translate the JSON array of strings under the 'source' key from {source_lang} to {target_lang}.\n"
                    "Output format must be a JSON object with a single 'translations' key containing the translated JSON array of strings.\n\n"
                    "Example input:\n"
                    "{{\n"
                    "  \"source\": [\n"
                    "    \"Hello\",\n"
                    "    \"World\"\n"
                    "  ]\n"
                    "}}\n\n"
                    "Example output:\n"
                    "{{\n"
                    "  \"translations\": [\n"
                    "    \"Привет\",\n"
                    "    \"Мир\"\n"
                    "  ]\n"
                    "}}\n\n"
                    "Input:"
                )
            elif schema == "array_of_objects":
                prompt_template = (
                    "Translate the 'text' fields in the JSON array of objects from {source_lang} to {target_lang}.\n"
                    "Output format must be a JSON array of objects with the same 'id' and 'text' keys.\n\n"
                    "Example input:\n"
                    "[\n"
                    "  {{\"id\": 1, \"text\": \"Hello\"}},\n"
                    "  {{\"id\": 2, \"text\": \"World\"}}\n"
                    "]\n\n"
                    "Example output:\n"
                    "[\n"
                    "  {{\"id\": 1, \"text\": \"Привет\"}},\n"
                    "  {{\"id\": 2, \"text\": \"Мир\"}}\n"
                    "]\n\n"
                    "Input:"
                )
            else:
                prompt_template = (
                    "Translate the JSON array of strings from {source_lang} to {target_lang}.\n"
                    "Output format must be a JSON array of strings.\n\n"
                    "Example input:\n"
                    "[\n"
                    "  \"Hello\",\n"
                    "  \"World\"\n"
                    "]\n\n"
                    "Example output:\n"
                    "[\n"
                    "  \"Привет\",\n"
                    "  \"Мир\"\n"
                    "]\n\n"
                    "Input:"
                )

        lines = text.split("\n")
        use_objects = (schema == "array_of_objects" or "text" in prompt_template.lower() or "id" in prompt_template.lower())
        if use_objects:
            input_data = [{"id": idx, "text": line} for idx, line in enumerate(lines, 1)]
        elif schema == "dict_of_strings":
            input_data = {"source": lines}
        else:
            input_data = lines
        serialized_input = json.dumps(input_data, ensure_ascii=False)
        full_text_to_send = serialized_input
    else:
        prompt_template = settings.get("ollama_prompt", "").strip()
        full_text_to_send = text

    if not api_url:
        raise ValueError("Ollama API URL (ollama_api_url) is not configured in config.ini")

    # Format prompt — use English language names so small LLMs understand the instruction
    # (e.g. "Russian" instead of "ru"). Raw codes are kept for API parameters elsewhere.
    prompt = prompt_template.format(
        source_lang=lang_code_to_name(sl),
        target_lang=lang_code_to_name(tl),
    )
    if MERGE_SPLIT_MARKER_PREFIX in text:
        prompt = (
            f"{prompt}\n"
            "Preserve every [[KWSPLIT0000]]-style marker exactly as written. "
            "Do not translate, remove, reorder, or modify these markers."
        )
    if salt:
        if not prompt.endswith('.'):
            prompt = prompt.rstrip() + "."
        prompt = f"{prompt} {salt}."
    if feedback:
        if not prompt.endswith('.'):
            prompt = prompt.rstrip() + "."
        prompt = f"{prompt} {feedback}."
    full_prompt = f"{prompt}\n\n{full_text_to_send}"

    is_chat = ("/v1/chat/completions" in api_url or "/chat" in api_url)

    payload = {
        "model": model,
        "stream": False
    }
    
    if is_chat:
        payload["messages"] = [{"role": "user", "content": full_prompt}]
    else:
        payload["prompt"] = full_prompt

    if json_enabled and is_chunk:
        payload["format"] = "json"

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(api_url, data=data)
    req.add_header("Content-Type", "application/json")
    req.add_header("User-Agent", "Mozilla/5.0")

    try:
        with urllib.request.urlopen(req, timeout=120) as response:
            body = response.read().decode('utf-8')
            resp_data = json.loads(body)
            
            if is_chat:
                choices = resp_data.get("choices", [])
                if choices and choices[0].get("message"):
                    response_text = choices[0]["message"].get("content", "").strip()
                else:
                    raise ValueError(f"Unexpected response structure: {body}")
            else:
                response_text = resp_data.get("response", "").strip()
                
            if json_enabled and is_chunk:
                # Extract JSON from potential Markdown formatting or conversational text
                cleaned_response = response_text.strip()
                
                # Find the first and last occurrence of curly braces or brackets
                first_curly = cleaned_response.find('{')
                last_curly = cleaned_response.rfind('}')
                first_bracket = cleaned_response.find('[')
                last_bracket = cleaned_response.rfind(']')
                
                start_idx = -1
                end_idx = -1
                
                if first_curly != -1 and (first_bracket == -1 or first_curly < first_bracket):
                    start_idx = first_curly
                    end_idx = last_curly
                elif first_bracket != -1:
                    start_idx = first_bracket
                    end_idx = last_bracket
                    
                if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
                    cleaned_response = cleaned_response[start_idx:end_idx + 1].strip()

                translated_lines = []
                parse_success = False

                # Strategy 1: Standard JSON parsing
                json_parse_err = None
                try:
                    output_data = json.loads(cleaned_response)
                    if isinstance(output_data, list):
                        for item in output_data:
                            if isinstance(item, dict) and "text" in item:
                                translated_lines.append(item["text"])
                            elif isinstance(item, str):
                                translated_lines.append(item)
                    elif isinstance(output_data, dict):
                        # Check if any value is a list of matching length
                        for val in output_data.values():
                            if isinstance(val, list) and len(val) == len(lines):
                                temp_lines = []
                                for item in val:
                                    if isinstance(item, str):
                                        temp_lines.append(item)
                                    elif isinstance(item, dict) and "text" in item:
                                        temp_lines.append(item["text"])
                                if len(temp_lines) == len(lines):
                                    translated_lines = temp_lines
                                    parse_success = True
                                    break
                        
                        # Strategy 1b: Check if it's a single translation object
                        if not parse_success and "text" in output_data and ("id" in output_data or len(output_data) == 2):
                            if isinstance(output_data["text"], str):
                                translated_lines.append(output_data["text"])
                                
                        # Strategy 1c: Mapping of IDs to objects/strings
                        if not parse_success:
                            for k in sorted(output_data.keys(), key=lambda x: int(x) if x.isdigit() else 0):
                                val = output_data[k]
                                if isinstance(val, dict) and "text" in val:
                                    translated_lines.append(val["text"])
                                else:
                                    translated_lines.append(str(val))

                    if len(translated_lines) == len(lines):
                        parse_success = True
                except Exception as e:
                    json_parse_err = e

                # Strategy 2: Regex extraction fallback (covers duplicate-keyed dicts, NDJSON, malformed lists, etc.)
                if not parse_success:
                    regex_lines = []
                    matches = []
                    if use_objects:
                        # Try double quotes pattern
                        matches = re.findall(r'"text"\s*:\s*"((?:[^"\\]|\\.)*)"', cleaned_response)
                        if len(matches) != len(lines):
                            # Try single quotes pattern
                            matches = re.findall(r"'text'\s*:\s*'((?:[^\'\\]|\\.)*)'", cleaned_response)
                        if len(matches) != len(lines):
                            # Try mixed/unquoted pattern
                            matches = re.findall(r'["\']?text["\']?\s*:\s*["\']((?:[^"\'\\]|\\.)*)["\']', cleaned_response)
                    else:
                        # Try to find the bracketed list portion first to exclude dictionary keys
                        bracket_match = re.search(r'\[\s*(.*)\s*\]', cleaned_response, re.DOTALL)
                        search_target = bracket_match.group(1) if bracket_match else cleaned_response
                        # Simple list of strings - match all double quoted strings
                        matches = re.findall(r'"((?:[^"\\]|\\.)*)"', search_target)
                        if len(matches) != len(lines):
                            # Try single quoted strings
                            matches = re.findall(r"'((?:[^\'\\]|\\.)*)'", search_target)

                    for m in matches:
                        m_clean = m.replace('\\"', '"').replace("\\'", "'").replace('\\\\', '\\')
                        regex_lines.append(m_clean)

                    if len(regex_lines) == len(lines):
                        translated_lines = regex_lines
                        parse_success = True
                    else:
                        got_count = len(translated_lines) if translated_lines else len(regex_lines)
                        if json_parse_err:
                            raise ValueError(f"Ollama returned invalid JSON: {json_parse_err}. Response was: {response_text}")
                        else:
                            raise ValueError(f"Line count mismatch in structured JSON (expected {len(lines)}, got {got_count}). Response was: {response_text}")

                return "\n".join(translated_lines)
            else:
                return response_text
    except Exception as e:
        raise Exception(f"Ollama request failed: {e}")

def translate_lines(lines: List[str], sl: str, tl: str, settings: dict) -> List[str]:
    """Helper to translate a list of lines with chunking and fallback."""
    provider = settings["subtitle_translator_provider"].lower()
    
    if provider not in ("google", "deepl", "ollama"):
        raise ValueError(f"Unknown translation provider: {provider}")
            
    api_url = settings.get("google_api_url", "")
    translated_lines = ["" for _ in lines]
    
    total_non_empty = sum(1 for line in lines if line.strip())
    translated_count = 0

    chunk_size = int(settings.get("subtitle_translator_chunk_size", "0"))
    max_retries = int(settings.get("subtitle_translator_max_retries", "3"))
    verbose_validation_errors = settings.get("subtitle_translator_verbose_validation_errors", "false").lower() == "true"
    word_count_check = settings.get("subtitle_translator_word_count_check", "false").lower() == "true"
    min_ratio = float(settings.get("subtitle_translator_word_count_min_ratio", "0.25"))
    max_ratio = float(settings.get("subtitle_translator_word_count_max_ratio", "3.5"))

    def validate_translated_line(orig_line: str, trans_line: str, line_idx: int) -> None:
        if not trans_line.strip():
            raise ValueError(f"Empty line returned for non-empty source at line index {line_idx}")

        if word_count_check:
            orig_words = len(orig_line.split())
            trans_words = len(trans_line.split())
            if orig_words > 0:
                # Allow an absolute word count difference of up to 5 words,
                # otherwise verify the ratio is within the limits.
                if abs(orig_words - trans_words) > 5:
                    ratio = trans_words / orig_words
                    if ratio < min_ratio or ratio > max_ratio:
                        raise ValueError(
                            f"Word count mismatch at line {line_idx}: original has {orig_words} words, "
                            f"translated has {trans_words} words (ratio {ratio:.2f} outside [{min_ratio}, {max_ratio}])"
                        )

    chunks = []
    if chunk_size > 0:
        chunk = []
        chunk_indices = []
        for idx, line in enumerate(lines):
            if not line.strip():
                translated_lines[idx] = ""
                continue
            chunk.append(line)
            chunk_indices.append(idx)
            if len(chunk) == chunk_size:
                chunks.append((chunk, chunk_indices))
                chunk = []
                chunk_indices = []
        if chunk:
            chunks.append((chunk, chunk_indices))
    else:
        # Standard chunking
        chunk = []
        chunk_indices = []
        chunk_char_count = 0
        for idx, line in enumerate(lines):
            if not line.strip():
                translated_lines[idx] = ""
                continue
                
            line_len = len(line)
            if len(chunk) >= 30 or (chunk_char_count + line_len) > 1000:
                chunks.append((chunk, chunk_indices))
                chunk = []
                chunk_indices = []
                chunk_char_count = 0
                
            chunk.append(line)
            chunk_indices.append(idx)
            chunk_char_count += line_len
            
        if chunk:
            chunks.append((chunk, chunk_indices))
        
    # Translate each chunk
    for chunk_text_list, indices in chunks:
        if chunk_size <= 0:
            # Original translation block (with standard fallback to line-by-line, no crashing)
            try:
                if provider == "google":
                    joined_text = "\n".join(chunk_text_list)
                    translated_joined = google_translate_v1(joined_text, sl, tl, api_url)
                    translated_joined = translated_joined.replace('\r\n', '\n').replace('\r', '\n')
                    translated_chunk_lines = translated_joined.split('\n')
                    
                    if len(translated_chunk_lines) > 1 and translated_chunk_lines[-1] == "":
                        translated_chunk_lines.pop()
                        
                    if len(translated_chunk_lines) == len(chunk_text_list):
                        for list_idx, target_idx in enumerate(indices):
                            translated_lines[target_idx] = translated_chunk_lines[list_idx].strip()
                    else:
                        for list_idx, target_idx in enumerate(indices):
                            original_line = chunk_text_list[list_idx]
                            translated_lines[target_idx] = google_translate_v1(original_line, sl, tl, api_url).strip()
                elif provider == "deepl":
                    translated_chunk_lines = deepl_translate_v2(chunk_text_list, sl, tl, settings)
                    if len(translated_chunk_lines) == len(chunk_text_list):
                        for list_idx, target_idx in enumerate(indices):
                            translated_lines[target_idx] = translated_chunk_lines[list_idx].strip()
                    else:
                        for list_idx, target_idx in enumerate(indices):
                            original_line = chunk_text_list[list_idx]
                            translated_lines[target_idx] = deepl_translate_v2([original_line], sl, tl, settings)[0].strip()
                elif provider == "ollama":
                    joined_text = "\n".join(chunk_text_list)
                    translated_joined = ollama_translate(joined_text, sl, tl, settings)
                    translated_joined = translated_joined.replace('\r\n', '\n').replace('\r', '\n')
                    translated_chunk_lines = translated_joined.split('\n')
                    
                    if len(translated_chunk_lines) > 1 and translated_chunk_lines[-1] == "":
                        translated_chunk_lines.pop()
                        
                    if len(translated_chunk_lines) == len(chunk_text_list):
                        for list_idx, target_idx in enumerate(indices):
                            translated_lines[target_idx] = translated_chunk_lines[list_idx].strip()
                    else:
                        for list_idx, target_idx in enumerate(indices):
                            original_line = chunk_text_list[list_idx]
                            translated_lines[target_idx] = ollama_translate(original_line, sl, tl, settings).strip()
            except Exception as e:
                if _IS_TTY:
                    clear_line()
                log_warn(f"Chunk translation failed ({e}). Falling back to line-by-line...")
                for list_idx, target_idx in enumerate(indices):
                    try:
                        original_line = chunk_text_list[list_idx]
                        if provider == "google":
                            translated_lines[target_idx] = google_translate_v1(original_line, sl, tl, api_url).strip()
                        elif provider == "deepl":
                            translated_lines[target_idx] = deepl_translate_v2([original_line], sl, tl, settings)[0].strip()
                        elif provider == "ollama":
                            translated_lines[target_idx] = ollama_translate(original_line, sl, tl, settings).strip()
                    except Exception as line_error:
                        if _IS_TTY:
                            clear_line()
                        log_error(f"Failed to translate line '{original_line}': {line_error}")
                        translated_lines[target_idx] = original_line
        else:
            # New validation and retry loop
            success = False
            last_error = ""
            for attempt in range(1, max_retries + 1):
                try:
                    translated_chunk_lines = []
                    if provider == "google":
                        joined_text = "\n".join(chunk_text_list)
                        translated_joined = google_translate_v1(joined_text, sl, tl, api_url)
                        translated_joined = translated_joined.replace('\r\n', '\n').replace('\r', '\n')
                        translated_chunk_lines = translated_joined.split('\n')
                        if len(translated_chunk_lines) > 1 and translated_chunk_lines[-1] == "":
                            translated_chunk_lines.pop()
                    elif provider == "deepl":
                        translated_chunk_lines = deepl_translate_v2(chunk_text_list, sl, tl, settings)
                    elif provider == "ollama":
                        joined_text = "\n".join(chunk_text_list)
                        salt = get_prompt_salt(settings.get("ollama_prompt_salt", ""), attempt)
                        feedback = ""
                        if last_error and settings.get("ollama_prompt_feedback", "false").lower() == "true":
                            template = settings.get("ollama_prompt_feedback_template", DEFAULT_OLLAMA_PROMPT_FEEDBACK_TEMPLATE)
                            short_error = last_error.split("Response was:")[0].strip() if "Response was:" in last_error else last_error
                            feedback = template.format(last_error=short_error)
                        translated_joined = ollama_translate(joined_text, sl, tl, settings, salt, feedback)
                        translated_joined = translated_joined.replace('\r\n', '\n').replace('\r', '\n')
                        translated_chunk_lines = translated_joined.split('\n')
                        if len(translated_chunk_lines) > 1 and translated_chunk_lines[-1] == "":
                            translated_chunk_lines.pop()

                    # Validate returned line count
                    if len(translated_chunk_lines) != len(chunk_text_list):
                        raise ValueError(f"Line count mismatch (expected {len(chunk_text_list)}, got {len(translated_chunk_lines)})")

                    # Validate empty holes / line integrity and word counts
                    for i, orig_line in enumerate(chunk_text_list):
                        validate_translated_line(orig_line, translated_chunk_lines[i], i)

                    # Write results
                    for list_idx, target_idx in enumerate(indices):
                        translated_lines[target_idx] = translated_chunk_lines[list_idx].strip()
                    success = True
                    break
                except Exception as e:
                    if _IS_TTY:
                        clear_line()
                    lines_range_str = f"lines {indices[0] + 1} to {indices[-1] + 1}"
                    error_summary, response_preview = format_validation_error_for_log(e)
                    log_warn(f"Chunk validation failed for {lines_range_str} ({attempt}/{max_retries}): {error_summary}")
                    if verbose_validation_errors and response_preview:
                        log_detail(f"Model response: {response_preview}", indent="    ")
                    last_error = str(e)
                    if attempt < max_retries:
                        time.sleep(1)

            if not success:
                if _IS_TTY:
                    clear_line()
                lines_range_str = f"lines {indices[0] + 1} to {indices[-1] + 1}"
                log_rescue(
                    f"Chunk validation failed after {max_retries} attempts for {lines_range_str}; "
                    f"switching to line-by-line rescue..."
                )
                # --- Line-by-line rescue pass ---
                # Build a copy of settings with JSON disabled so that single lines go through
                # the plain text path (small models can usually handle one line at a time).
                rescue_settings = dict(settings)
                rescue_settings["ollama_json_format"] = "false"
                rescue_ok = True
                for list_idx, target_idx in enumerate(indices):
                    original_line = chunk_text_list[list_idx]
                    try:
                        rescued_line = ""
                        if provider == "google":
                            rescued_line = google_translate_v1(original_line, sl, tl, api_url).strip()
                        elif provider == "deepl":
                            rescued_line = deepl_translate_v2([original_line], sl, tl, settings)[0].strip()
                        elif provider == "ollama":
                            rescued_line = ollama_translate(original_line, sl, tl, rescue_settings).strip()
                        validate_translated_line(original_line, rescued_line, list_idx)
                        translated_lines[target_idx] = rescued_line
                        if verbose_validation_errors:
                            log_detail(f"Rescued line {target_idx + 1}: {translated_lines[target_idx][:60]!r}")
                        else:
                            log_detail(f"Line {target_idx + 1} rescued")
                    except Exception as rescue_err:
                        rescue_ok = False
                        log_error(f"Rescue translation failed for line {target_idx + 1}: {rescue_err}")
                        # Leave as empty string — blank subtitle entry

                if not rescue_ok:
                    msg = f"Chunk validation AND rescue pass failed for {lines_range_str}."
                    log_error(f"{_bold(msg)} Stopping translation.")
                    raise ChunkValidationError(msg, list(translated_lines))


        # Update progress bar
        translated_count = min(translated_count + len(chunk_text_list), total_non_empty)
        if _IS_TTY:
            sys.stdout.write(make_translation_progress_bar(translated_count, total_non_empty))
            sys.stdout.flush()
        else:
            log_info(f"Translated {translated_count}/{total_non_empty} lines ({(translated_count/total_non_empty)*100:.1f}%)...")
            
    if _IS_TTY and total_non_empty > 0:
        clear_line()

    return translated_lines

# ==============================================================================
# PIPELINE PROCESSOR
# ==============================================================================
def process_file(file_path: Path, settings: dict, session_zid: str) -> bool:
    """Translates the given file to target languages."""
    if not file_path.exists():
        log_error(f"File not found: {file_path}")
        return False

    orig_file_path = file_path
    renamed_paths: List[Tuple[Path, Path]] = []

    try:
        duplicate_mode = get_duplicate_mode(settings)
    except ValueError as mode_error:
        log_error(str(mode_error))
        return False

    # 1. Parse filename parameters
    zid, clean_title, lang, ext = parse_filename(file_path)
    
    # 2. Resolve source language
    source_lang = lang if lang else settings["subtitle_translator_source_language"]

    # 3. Source ZID renaming logic
    source_had_zid = bool(zid)
    rename_source_with_zid = settings.get("subtitle_translator_rename_source_with_zid", "false").lower() == "true"
    related_media_setting = settings.get("subtitle_translator_rename_related_media_with_zid", "false").strip().lower()
    rename_related_media_with_zid_enabled = related_media_setting == "true"
    if not zid:
        if rename_source_with_zid:
            zid = get_current_zid()
            new_name = f"{zid}-{clean_title}.{source_lang}.{ext}"
            new_path = file_path.parent / new_name
            if new_path.exists():
                log_error(f"Cannot rename source file; target already exists: {new_name}")
                return False
            if rename_related_media_with_zid_enabled:
                related_media_ok, related_media_renames = rename_related_media_with_zid(file_path.parent, clean_title, zid)
                if not related_media_ok:
                    return False
                renamed_paths.extend(related_media_renames)
            try:
                file_path.rename(new_path)
                log_info(f"Renamed source file to include ZID: {new_name}")
                renamed_paths.append((new_path, file_path))
                file_path = new_path
            except Exception as e:
                log_error(f"Failed to rename source file to include ZID: {e}")
                rollback_renamed_paths(renamed_paths)
                return False
        else:
            log_info("Source file has no ZID; keeping original filename.")
            if rename_related_media_with_zid_enabled:
                log_warn("Related media ZID rename skipped because source ZID generation is disabled.")
    else:
        source_language_target_path: Optional[Path] = None
        source_language_target_name = ""
        if not lang:
            source_language_target_name = f"{zid}-{clean_title}.{source_lang}.{ext}"
            source_language_target_path = file_path.parent / source_language_target_name
            if source_language_target_path.exists():
                log_error(f"Cannot rename source file; target already exists: {source_language_target_name}")
                return False
        if rename_related_media_with_zid_enabled:
            related_media_ok, related_media_renames = rename_related_media_with_zid(file_path.parent, clean_title, zid)
            if not related_media_ok:
                return False
            renamed_paths.extend(related_media_renames)
        if not lang:
            try:
                file_path.rename(source_language_target_path)
                log_info(f"Renamed source file to include language: {source_language_target_name}")
                renamed_paths.append((source_language_target_path, file_path))
                file_path = source_language_target_path
            except Exception as e:
                log_error(f"Failed to rename source file to include language: {e}")
                rollback_renamed_paths(renamed_paths)
                return False

    # 4. Read file content
    try:
        content = file_path.read_text(encoding="utf-8-sig")
    except Exception:
        try:
            content = file_path.read_text(encoding="utf-8", errors="ignore")
        except Exception as e:
            log_error(f"Failed to read file: {e}")
            return False

    # 5. Extract translatable lines
    is_srt = (ext.lower() == 'srt')
    merge_lines_enabled = is_srt and settings.get('subtitle_translator_merge_lines', 'false').lower() == 'true'
    merge_split_mode = get_merge_split_mode(settings)
    clean_markdown = settings.get('subtitle_translator_clean_markdown', 'true').lower() == 'true'
    max_gap_ms = int(settings.get('subtitle_translator_merge_max_gap_ms', '1000'))

    def clean_text(text: str) -> str:
        return clean_subtitle_text(text, clean_markdown=clean_markdown)

    # group_info is populated only in merge mode:
    # list of (group_block_indices, per_block_char_lengths, exact_split_markers)
    group_info: Optional[List[Tuple[List[int], List[int], List[str]]]] = None

    if is_srt:
        blocks = parse_srt(content)
        # Pre-process: merge any internal multi-line block into one clean line
        for block in blocks:
            cleaned = [clean_text(line) for line in block['text_lines'] if line.strip()]
            block['text_lines'] = [clean_text(' '.join(cleaned))] if cleaned else []

        if merge_lines_enabled:
            # --- MERGE MODE ---
            # Group consecutive compatible blocks; each group is translated as one text unit
            merge_groups = build_merge_groups(blocks, max_gap_ms)
            group_info = []
            lines_to_translate = []
            for group_indices in merge_groups:
                group_texts = [(blocks[b]['text_lines'][0] if blocks[b]['text_lines'] else '') for b in group_indices]
                lengths = [len(t) for t in group_texts]
                if merge_split_mode == "marker":
                    combined, split_markers = join_merged_group_texts(group_texts)
                else:
                    combined = ' '.join(t for t in group_texts if t)
                    split_markers = []
                lines_to_translate.append(combined)  # one "line" per group
                group_info.append((group_indices, lengths, split_markers))
            mapping = None
            log_detail(f"Merge mode: {len(blocks)} blocks grouped into {len(merge_groups)} translation units.")
        else:
            # --- LINE-BY-LINE MODE ---
            lines_to_translate = []
            mapping = []  # list of (block_idx, line_idx)
            for b_idx, block in enumerate(blocks):
                for l_idx, text_line in enumerate(block['text_lines']):
                    lines_to_translate.append(text_line)
                    mapping.append((b_idx, l_idx))
    else:
        # Txt file line-by-line
        content = content.replace('\r\n', '\n').replace('\r', '\n')
        raw_lines = content.split('\n')
        lines_to_translate = [clean_text(line) for line in raw_lines]
        mapping = None

    # Count non-empty source lines (always reflects original subtitle blocks, not groups)
    source_non_empty_count = (
        sum(1 for b in blocks if b['text_lines'] and b['text_lines'][0].strip())
        if is_srt else sum(1 for line in lines_to_translate if line.strip())
    )
    log_info(f"Source file contains {source_non_empty_count} non-empty lines.")

    # 6. Loop over declarative target languages
    target_langs = [l.strip().lower() for l in settings["subtitle_translator_target_languages"].split(",") if l.strip()]
    
    success_status = True
    for tl in target_langs:
        if tl == source_lang.lower():
            log_skip(f"Target language '{tl}' is the same as source language. Skipping.")
            continue
            
        target_prefix = f"{zid}-" if source_had_zid or rename_source_with_zid else ""
        target_name = f"{target_prefix}{clean_title}.{tl}.{ext}"
        target_path = file_path.parent / target_name
        
        # Idempotency / duplicate check
        if target_path.exists():
            if duplicate_mode == "skip":
                log_skip(f"Subtitle for '{tl}' already exists: {target_name}")
                continue
            if duplicate_mode == "overwrite":
                log_info(f"Subtitle for '{tl}' already exists. Overwriting...")
            
        log_info(f"Translating {source_lang} → {tl}...")
        
        try:
            translated_lines = translate_lines(lines_to_translate, source_lang, tl, settings)

            # Reconstruct content
            if is_srt:
                new_blocks = json.loads(json.dumps(blocks))  # Deep copy
                if merge_lines_enabled and group_info is not None:
                    # --- MERGE MODE reconstruction: split translated group text back to blocks ---
                    for group_idx, (group_indices, lengths, split_markers) in enumerate(group_info):
                        trans_text = translated_lines[group_idx]
                        if len(group_indices) == 1:
                            b_idx = group_indices[0]
                            trans_text = clean_text(trans_text)
                            if new_blocks[b_idx]['text_lines']:
                                new_blocks[b_idx]['text_lines'][0] = trans_text
                            elif trans_text:
                                new_blocks[b_idx]['text_lines'] = [trans_text]
                        else:
                            if merge_split_mode == "marker":
                                split_parts = split_merged_text_by_markers(trans_text, split_markers)
                            else:
                                non_zero_lengths = [max(l, 1) for l in lengths]
                                split_parts = split_by_proportion(clean_text(trans_text), non_zero_lengths)
                            for i, b_idx in enumerate(group_indices):
                                part = clean_text(split_parts[i]) if i < len(split_parts) else ''
                                if new_blocks[b_idx]['text_lines']:
                                    new_blocks[b_idx]['text_lines'][0] = part
                                elif part:
                                    new_blocks[b_idx]['text_lines'] = [part]
                else:
                    # --- LINE-BY-LINE MODE reconstruction ---
                    for trans_idx, trans_text in enumerate(translated_lines):
                        b_idx, l_idx = mapping[trans_idx]
                        new_blocks[b_idx]['text_lines'][l_idx] = clean_text(trans_text)
                    for block in new_blocks:
                        cleaned = [clean_text(l) for l in block['text_lines'] if l.strip()]
                        block['text_lines'] = [clean_text(' '.join(cleaned))] if cleaned else []
                result_content = write_srt(new_blocks)
            else:
                result_content = '\n'.join(clean_text(l) for l in translated_lines)

            # Write translated file
            write_output_file(target_path, result_content, duplicate_mode, session_zid, f"Subtitle for '{tl}'")
            log_ok(f"Saved translated subtitle: {target_name}")

            # Check line consistency (count filled blocks in merge mode)
            if is_srt and merge_lines_enabled:
                translated_non_empty_count = sum(1 for b in new_blocks if b['text_lines'] and b['text_lines'][0].strip())
            else:
                translated_non_empty_count = sum(1 for line in translated_lines if line.strip())
            if translated_non_empty_count != source_non_empty_count:
                log_warn(f"Line count mismatch for '{tl}'! Source: {source_non_empty_count}, Result: {translated_non_empty_count}")
            else:
                log_detail(f"Line count verified: {translated_non_empty_count} lines.")

        except ChunkValidationError as cve:
            log_error(f"Failed to translate to '{tl}': {cve}")
            save_partial = settings.get("subtitle_translator_save_partial_on_failure", "false").lower() == "true"
            if save_partial and cve.partial_lines:
                log_warn(f"Saving partial translation for '{tl}' (completed chunks only, failed chunks are blank)...")
                partial_translated_lines = cve.partial_lines
                if is_srt:
                    partial_blocks = json.loads(json.dumps(blocks))
                    if merge_lines_enabled and group_info is not None:
                        for group_idx, (group_indices, lengths, split_markers) in enumerate(group_info):
                            trans_text = partial_translated_lines[group_idx] if group_idx < len(partial_translated_lines) else ''
                            if len(group_indices) == 1:
                                b_idx = group_indices[0]
                                trans_text = clean_text(trans_text)
                                if partial_blocks[b_idx]['text_lines']:
                                    partial_blocks[b_idx]['text_lines'][0] = trans_text
                            else:
                                if merge_split_mode == "marker":
                                    split_parts = split_merged_text_by_markers(trans_text, split_markers) if trans_text.strip() else [''] * len(group_indices)
                                else:
                                    non_zero_lengths = [max(l, 1) for l in lengths]
                                    split_parts = split_by_proportion(clean_text(trans_text), non_zero_lengths)
                                for i, b_idx in enumerate(group_indices):
                                    part = clean_text(split_parts[i]) if i < len(split_parts) else ''
                                    if partial_blocks[b_idx]['text_lines']:
                                        partial_blocks[b_idx]['text_lines'][0] = part
                    else:
                        for trans_idx, trans_text in enumerate(partial_translated_lines):
                            b_idx, l_idx = mapping[trans_idx]
                            partial_blocks[b_idx]['text_lines'][l_idx] = clean_text(trans_text)
                        for block in partial_blocks:
                            cleaned = [clean_text(l) for l in block['text_lines'] if l.strip()]
                            block['text_lines'] = [clean_text(' '.join(cleaned))] if cleaned else []
                    partial_content = write_srt(partial_blocks)
                else:
                    partial_content = '\n'.join(clean_text(l) for l in partial_translated_lines)
                try:
                    write_output_file(target_path, partial_content, duplicate_mode, session_zid, f"Partial subtitle for '{tl}'")
                    log_ok(f"Saved partial translation: {target_name}")
                except RuntimeError as partial_write_error:
                    if duplicate_mode == "skip" and target_path.exists():
                        log_skip(str(partial_write_error))
                    else:
                        log_error(f"Failed to save partial translation for '{tl}': {partial_write_error}")
                except Exception as partial_write_error:
                    log_error(f"Failed to save partial translation for '{tl}': {partial_write_error}")
            success_status = False
        except NotImplementedError as nie:
            log_error(str(nie))
            success_status = False
        except Exception as e:
            log_error(f"Failed to translate to '{tl}': {e}")
            success_status = False

    if not success_status and renamed_paths:
        rollback_renamed_paths(renamed_paths)

    return success_status

# ==============================================================================
# MAIN ENTRYPOINT
# ==============================================================================
def main():
    parser = argparse.ArgumentParser(description="Declarative Subtitle Translator")
    parser.add_argument("inputs", nargs="*", help="Subtitle files (.srt or .txt)")
    parser.add_argument("--sendto", action="store_true", help="Invoked from Windows Explorer SendTo menu")
    parser.add_argument("--pause", action="store_true", help="Pause console window before exiting")
    
    args = parser.parse_args()
    
    # Load settings
    settings = load_config()
    session_zid = get_current_zid()
    print(f"\n{_bold('Kardenwort Subtitle Translator Engine')} {_dim(f'(ZID: {session_zid})')}\n", flush=True)

    # Print settings summary
    provider = settings.get("subtitle_translator_provider", "google").lower()
    log_info(f"Active Provider: {_bold(provider)}")
    if provider == "ollama":
        print(f"  {_dim('·')} Model:          {_cyan(settings.get('ollama_model', ''))}")
        print(f"  {_dim('·')} API URL:        {_cyan(settings.get('ollama_api_url', ''))}")
        print(f"  {_dim('·')} Prompt Salt:    {_cyan(settings.get('ollama_prompt_salt', 'false'))}")
        print(f"  {_dim('·')} Prompt Feedback:{_cyan(settings.get('ollama_prompt_feedback', 'false'))}")
        print(f"  {_dim('·')} JSON Format:    {_cyan(settings.get('ollama_json_format', 'false'))}")
    elif provider == "deepl":
        print(f"  {_dim('·')} API URL:        {_cyan(settings.get('deepl_api_url', ''))}")
        print(f"  {_dim('·')} Formality:      {_cyan(settings.get('deepl_formality', 'default'))}")
    print(f"  {_dim('·')} Duplicate Mode: {_cyan(settings.get('subtitle_translator_duplicate_mode', 'skip'))}")
    print(f"  {_dim('·')} Target Langs:   {_cyan(settings.get('subtitle_translator_target_languages', ''))}\n")
    
    if not args.inputs:
        log_error("No subtitle files provided.")
        if args.pause:
            pause_console(success=False)
        sys.exit(1)
        
    success_count = 0
    total_files = len(args.inputs)
    
    for idx, item in enumerate(args.inputs, 1):
        print(f"\n{_dim(f'[{idx}/{total_files}]')} {_bold(os.path.basename(item))}", flush=True)
        file_path = Path(item)
        if process_file(file_path, settings, session_zid):
            success_count += 1
            
    if success_count == total_files:
        log_ok(f"All {success_count}/{total_files} file(s) processed successfully.")
    else:
        log_warn(f"Processed {success_count}/{total_files} file(s). {total_files - success_count} failed.")
        
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
        pause_console(success=(success_count == total_files), timeout_secs=timeout)

if __name__ == "__main__":
    main()
