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

# Path to the ZID script; overridden from config via load_config()
_ZID_SCRIPT: str = ""

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

def log_detail(msg, indent="  "):
    print(f"{indent}{_dim('·')} {msg}", flush=True)

def log_section(title):
    print(f"\n{_bold(title)}", flush=True)

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
        "google_api_url": "https://translate.googleapis.com/translate_a/single",
        "deepl_api_key": "",
        "deepl_api_url": "https://api-free.deepl.com/v2/translate",
        "deepl_formality": "default",
        "ollama_api_url": "http://localhost:11434/api/generate",
        "ollama_model": "llama3",
        "ollama_prompt": "Translate the following text from {source_lang} to {target_lang}. Output ONLY the raw translation, without any explanations, preamble, introductory remarks, or formatting. Preserve the line breaks.",
        "subtitle_translator_chunk_size": "5",
        "subtitle_translator_max_retries": "3",
        "subtitle_translator_word_count_check": "true",
        "subtitle_translator_word_count_min_ratio": "0.25",
        "subtitle_translator_word_count_max_ratio": "3.5",
        "subtitle_translator_save_partial_on_failure": "false",
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

# ==============================================================================
# EXCEPTIONS
# ==============================================================================
class ChunkValidationError(RuntimeError):
    """Raised when chunk validation fails after all retries.
    
    Carries the partially translated lines built up to the failing chunk.
    Positions for untranslated lines hold the original source text as fallback.
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

def ollama_translate(text: str, sl: str, tl: str, settings: dict) -> str:
    """Ollama API caller."""
    api_url = settings.get("ollama_api_url", "").strip()
    model = settings.get("ollama_model", "").strip()
    prompt_template = settings.get("ollama_prompt", "").strip()

    if not api_url:
        raise ValueError("Ollama API URL (ollama_api_url) is not configured in config.ini")

    # Format prompt
    prompt = prompt_template.format(source_lang=sl, target_lang=tl)
    full_prompt = f"{prompt}\n\n{text}"

    is_chat = ("/v1/chat/completions" in api_url or "/chat" in api_url)

    if is_chat:
        payload = {
            "model": model,
            "messages": [{"role": "user", "content": full_prompt}],
            "stream": False
        }
    else:
        payload = {
            "model": model,
            "prompt": full_prompt,
            "stream": False
        }

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
                    return choices[0]["message"].get("content", "").strip()
            else:
                return resp_data.get("response", "").strip()
            
            raise ValueError(f"Unexpected response structure: {body}")
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
    word_count_check = settings.get("subtitle_translator_word_count_check", "true").lower() == "true"
    min_ratio = float(settings.get("subtitle_translator_word_count_min_ratio", "0.25"))
    max_ratio = float(settings.get("subtitle_translator_word_count_max_ratio", "3.5"))

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
                        translated_joined = ollama_translate(joined_text, sl, tl, settings)
                        translated_joined = translated_joined.replace('\r\n', '\n').replace('\r', '\n')
                        translated_chunk_lines = translated_joined.split('\n')
                        if len(translated_chunk_lines) > 1 and translated_chunk_lines[-1] == "":
                            translated_chunk_lines.pop()

                    # Validate returned line count
                    if len(translated_chunk_lines) != len(chunk_text_list):
                        raise ValueError(f"Line count mismatch (expected {len(chunk_text_list)}, got {len(translated_chunk_lines)})")

                    # Validate empty holes / line integrity and word counts
                    for i, orig_line in enumerate(chunk_text_list):
                        trans_line = translated_chunk_lines[i]
                        if not trans_line.strip():
                            raise ValueError(f"Empty line returned for non-empty source at line index {i}")
                        
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
                                            f"Word count mismatch at line {i}: original has {orig_words} words, "
                                            f"translated has {trans_words} words (ratio {ratio:.2f} outside [{min_ratio}, {max_ratio}])"
                                        )

                    # Write results
                    for list_idx, target_idx in enumerate(indices):
                        translated_lines[target_idx] = translated_chunk_lines[list_idx].strip()
                    success = True
                    break
                except Exception as e:
                    if _IS_TTY:
                        clear_line()
                    lines_range_str = f"lines {indices[0] + 1} to {indices[-1] + 1}"
                    log_warn(f"Chunk validation failed for {lines_range_str} on attempt {attempt}/{max_retries}: {e}")
                    if attempt < max_retries:
                        time.sleep(1)

            if not success:
                if _IS_TTY:
                    clear_line()
                lines_range_str = f"lines {indices[0] + 1} to {indices[-1] + 1}"
                msg = f"Chunk validation failed after {max_retries} attempts for {lines_range_str}."
                log_error(f"{_bold(msg)} Stopping translation.")
                # Failed chunks stay as empty strings — blank subtitles in the output
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
    renamed_source = False

    # 1. Parse filename parameters
    zid, clean_title, lang, ext = parse_filename(file_path)
    
    # 2. Resolve source language
    source_lang = lang if lang else settings["subtitle_translator_source_language"]

    # 3. ZID archiving renaming logic
    if not zid:
        zid = get_current_zid()
        new_name = f"{zid}-{clean_title}.{source_lang}.{ext}"
        new_path = file_path.parent / new_name
        try:
            file_path.rename(new_path)
            log_info(f"Archived source file to: {new_name}")
            file_path = new_path
            renamed_source = True
        except Exception as e:
            log_error(f"Failed to rename source file to include ZID: {e}")
            return False
    else:
        if not lang:
            new_name = f"{zid}-{clean_title}.{source_lang}.{ext}"
            new_path = file_path.parent / new_name
            try:
                file_path.rename(new_path)
                log_info(f"Renamed source file to include language: {new_name}")
                file_path = new_path
                renamed_source = True
            except Exception as e:
                log_error(f"Failed to rename source file to include language: {e}")
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
    
    if is_srt:
        blocks = parse_srt(content)
        lines_to_translate = []
        mapping = [] # list of (block_idx, line_idx)
        for b_idx, block in enumerate(blocks):
            for l_idx, text_line in enumerate(block['text_lines']):
                lines_to_translate.append(text_line)
                mapping.append((b_idx, l_idx))
    else:
        # Txt file line-by-line
        content = content.replace('\r\n', '\n').replace('\r', '\n')
        lines_to_translate = content.split('\n')
        mapping = None

    # Count non-empty source lines
    source_non_empty_count = sum(1 for line in lines_to_translate if line.strip())
    log_info(f"Source file contains {source_non_empty_count} non-empty lines.")

    # 6. Loop over declarative target languages
    target_langs = [l.strip().lower() for l in settings["subtitle_translator_target_languages"].split(",") if l.strip()]
    
    success_status = True
    for tl in target_langs:
        if tl == source_lang.lower():
            log_skip(f"Target language '{tl}' is the same as source language. Skipping.")
            continue
            
        target_name = f"{zid}-{clean_title}.{tl}.{ext}"
        target_path = file_path.parent / target_name
        
        # Idempotency / duplicate check
        if target_path.exists():
            dup_mode = settings.get("subtitle_translator_duplicate_mode", "skip").lower()
            if dup_mode == "skip":
                log_skip(f"Subtitle for '{tl}' already exists: {target_name}")
                continue
            elif dup_mode == "archive":
                archive_dir = file_path.parent / session_zid
                archive_dir.mkdir(parents=True, exist_ok=True)
                archive_target_path = archive_dir / target_name
                log_warn(f"Subtitle for '{tl}' already exists. Archiving old file to: {session_zid}/{target_name}")
                try:
                    if archive_target_path.exists():
                        archive_target_path.unlink()
                    target_path.rename(archive_target_path)
                except Exception as archive_error:
                    log_warn(f"Failed to archive old subtitle: {archive_error}")
            elif dup_mode == "overwrite":
                log_info(f"Subtitle for '{tl}' already exists. Overwriting...")
            
        log_info(f"Translating {source_lang} → {tl}...")
        
        try:
            translated_lines = translate_lines(lines_to_translate, source_lang, tl, settings)
            
            # Reconstruct content
            if is_srt:
                # Map back to blocks
                new_blocks = json.loads(json.dumps(blocks)) # Deep copy
                for trans_idx, trans_text in enumerate(translated_lines):
                    b_idx, l_idx = mapping[trans_idx]
                    new_blocks[b_idx]['text_lines'][l_idx] = trans_text
                result_content = write_srt(new_blocks)
            else:
                result_content = "\n".join(translated_lines)
                
            # Write translated file
            target_path.write_text(result_content, encoding="utf-8", newline="\n")
            log_ok(f"Saved translated subtitle: {target_name}")
            
            # Check line consistency
            translated_non_empty_count = sum(1 for line in translated_lines if line.strip())
            if translated_non_empty_count != source_non_empty_count:
                log_warn(f"Line count mismatch for '{tl}'! Source: {source_non_empty_count}, Result: {translated_non_empty_count}")
            else:
                log_detail(f"Line count verified: {translated_non_empty_count} lines.")
                
        except ChunkValidationError as cve:
            log_error(f"Failed to translate to '{tl}': {cve}")
            save_partial = settings.get("subtitle_translator_save_partial_on_failure", "false").lower() == "true"
            if save_partial and cve.partial_lines:
                log_warn(f"Saving partial translation for '{tl}' (completed chunks only, untranslated lines kept as original)...")
                partial_translated_lines = cve.partial_lines
                if is_srt:
                    partial_blocks = json.loads(json.dumps(blocks))
                    for trans_idx, trans_text in enumerate(partial_translated_lines):
                        b_idx, l_idx = mapping[trans_idx]
                        partial_blocks[b_idx]['text_lines'][l_idx] = trans_text
                    partial_content = write_srt(partial_blocks)
                else:
                    partial_content = "\n".join(partial_translated_lines)
                # Apply duplicate_mode before writing partial file
                if target_path.exists():
                    dup_mode = settings.get("subtitle_translator_duplicate_mode", "skip").lower()
                    if dup_mode == "skip":
                        log_skip(f"Partial output skipped — existing file for '{tl}' preserved: {target_name}")
                    elif dup_mode == "archive":
                        archive_dir = file_path.parent / session_zid
                        archive_dir.mkdir(parents=True, exist_ok=True)
                        archive_target_path = archive_dir / target_name
                        try:
                            if archive_target_path.exists():
                                archive_target_path.unlink()
                            target_path.rename(archive_target_path)
                            log_info(f"Archived previous file to: {session_zid}/{target_name}")
                        except Exception as archive_error:
                            log_warn(f"Failed to archive old subtitle before partial save: {archive_error}")
                        target_path.write_text(partial_content, encoding="utf-8", newline="\n")
                        log_ok(f"Saved partial translation: {target_name}")
                    elif dup_mode == "overwrite":
                        target_path.write_text(partial_content, encoding="utf-8", newline="\n")
                        log_ok(f"Saved partial translation (overwrite): {target_name}")
                else:
                    target_path.write_text(partial_content, encoding="utf-8", newline="\n")
                    log_ok(f"Saved partial translation: {target_name}")
            success_status = False
        except NotImplementedError as nie:
            log_error(str(nie))
            success_status = False
        except Exception as e:
            log_error(f"Failed to translate to '{tl}': {e}")
            success_status = False

    if not success_status and renamed_source:
        try:
            file_path.rename(orig_file_path)
            log_info(f"Rolled back source file name to: {orig_file_path.name}")
        except Exception as rollback_err:
            log_warn(f"Failed to rollback source file name: {rollback_err}")

    return success_status

# ==============================================================================
# MAIN ENTRYPOINT
# ==============================================================================
def main():
    session_zid = get_current_zid()
    print(f"\n{_bold('Kardenwort Subtitle Translator Engine')} {_dim(f'(ZID: {session_zid})')}\n", flush=True)
    
    parser = argparse.ArgumentParser(description="Declarative Subtitle Translator")
    parser.add_argument("inputs", nargs="*", help="Subtitle files (.srt or .txt)")
    parser.add_argument("--sendto", action="store_true", help="Invoked from Windows Explorer SendTo menu")
    parser.add_argument("--pause", action="store_true", help="Pause console window before exiting")
    
    args = parser.parse_args()
    
    # Load settings
    settings = load_config()

    # Print settings summary
    provider = settings.get("subtitle_translator_provider", "google").lower()
    log_info(f"Active Provider: {_bold(provider)}")
    if provider == "ollama":
        print(f"  {_dim('·')} Model:          {_cyan(settings.get('ollama_model', ''))}")
        print(f"  {_dim('·')} API URL:        {_cyan(settings.get('ollama_api_url', ''))}")
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
        pause_console(success=(success_count == total_files))

if __name__ == "__main__":
    main()
