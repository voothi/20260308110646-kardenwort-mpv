#!/usr/bin/env python
import os
import sys
import subprocess
import re
import shutil
import traceback
import configparser
from datetime import datetime
from typing import List, Tuple

# ==============================================================================
# GLOBAL CONFIGURATION DEFAULTS
# ==============================================================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = os.path.join(SCRIPT_DIR, "config.ini")

# Supported subtitle file extensions to search for primary & secondary tracks
SUPPORTED_EXTENSIONS = ('.srt', '.ass', '.vtt')
SUPPORTED_TEXT_EXTENSIONS = ('.txt', '.md', '.rst', '.log')

# Language code suffixes to strip when determining base name (e.g., file.de.srt -> base file)
LANG_SUFFIXES = ('de', 'ru', 'en', 'eng', 'ger', 'rus', 'uk', 'es', 'fr', 'it')
LANG_SELECTION_PRIORITY = {
    "en": 0,
    "eng": 0,
    "de": 1,
    "ger": 1,
    "ru": 2,
    "rus": 2,
}

# Virtual Video Stream Parameters
VIRTUAL_VIDEO_COLOR = 'black'        # Can be black, grey, white, blue, etc.
VIRTUAL_VIDEO_SIZE = '1280x720'      # Dimensions of the player window
VIRTUAL_VIDEO_DURATION = 36000       # Timeline length in seconds (e.g. 36000 = 10 hours)
END_PADDING_SECONDS = 2.0

# Initial playback state (yes = start paused, no = play immediately)
PAUSE_ON_LAUNCH = 'yes'
FORCE_WINDOW = 'yes'
RESUME_PLAYBACK = 'no'
BLACK_VIDEO_FILE = 'black.mp4'
MPV_EXECUTABLE = ''
MPV_FALLBACK_PATHS = (
    r"C:\mpv\mpv.exe",
    r"C:\mpv\mpv-0.39.0-x86_64\mpv.exe",
    r"C:\Program Files\mpv\mpv.exe",
)
LOG_DIR = 'logs'
MPV_LOG_FILE = 'mpv_sub_viewer.log'
LAUNCH_LOG_FILE = 'sub_viewer_launch.log'
MPV_CONF_READER_OVERRIDES = True
READER_MAX_LINES_PER_BLOCK = 1
READER_MAX_CHARS_PER_LINE = 90
READER_MIN_BLOCKS = 2
READER_OPTIMAL_CHARACTERS_PER_SECOND = 15.0
READER_OPTIMAL_WORDS_PER_MINUTE = 180.0
READER_MIN_CUE_SECONDS = 1.2
READER_MAX_CUE_SECONDS = 7.0
READER_MIN_DATE_SECONDS = 2.5
# ==============================================================================
# All READER_* values above can be overridden in mpv.conf without editing this
# file — see the "Sub-Viewer Reader Settings" section in mpv.conf.
# ==============================================================================

_DATE_RE = re.compile(
    r'\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|'
    r'Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)'
    r'\s+\d{1,2},?\s+\d{4}\b'
    r'|\b\d{1,2}\s+(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|'
    r'Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)'
    r'\s+\d{4}\b'
    r'|\b\d{4}[-./]\d{1,2}[-./]\d{1,2}\b'
    r'|\b\d{1,2}[-./]\d{1,2}[-./]\d{4}\b',
    re.IGNORECASE
)


def _split_csv(value):
    return [item.strip() for item in str(value or "").split(",") if item.strip()]


def _parse_extensions(value, fallback):
    extensions = []
    for item in _split_csv(value):
        ext = item.lower()
        if not ext.startswith("."):
            ext = "." + ext
        extensions.append(ext)
    return tuple(extensions) if extensions else fallback


def _parse_priority_map(value, fallback):
    priority = {}
    for item in _split_csv(value):
        if ":" not in item:
            continue
        lang, rank = item.split(":", 1)
        lang = lang.strip().lower()
        try:
            priority[lang] = int(rank.strip())
        except ValueError:
            continue
    return priority if priority else dict(fallback)


def _parse_path_list(value, fallback):
    if not value:
        return fallback
    paths = []
    for raw in str(value).splitlines():
        raw = raw.strip()
        if not raw:
            continue
        paths.append(os.path.expandvars(raw))
    return tuple(paths) if paths else fallback


def _resolve_config_path(path_value):
    expanded = os.path.expandvars(path_value or "")
    if not expanded:
        return expanded
    if os.path.isabs(expanded):
        return expanded
    return os.path.join(SCRIPT_DIR, expanded)


def _config_get(config, section, option, fallback):
    return config.get(section, option, fallback=str(fallback)).strip()


def _config_get_int(config, section, option, fallback):
    try:
        return config.getint(section, option, fallback=fallback)
    except ValueError:
        return fallback


def _config_get_float(config, section, option, fallback):
    try:
        return config.getfloat(section, option, fallback=fallback)
    except ValueError:
        return fallback


def _config_get_bool(config, section, option, fallback):
    try:
        return config.getboolean(section, option, fallback=fallback)
    except ValueError:
        return fallback


def load_config():
    config = configparser.ConfigParser()
    if os.path.exists(CONFIG_FILE):
        try:
            config.read(CONFIG_FILE, encoding="utf-8")
        except Exception:
            return config
    return config


def apply_config(config):
    global SUPPORTED_EXTENSIONS, SUPPORTED_TEXT_EXTENSIONS
    global LANG_SUFFIXES, LANG_SELECTION_PRIORITY
    global VIRTUAL_VIDEO_COLOR, VIRTUAL_VIDEO_SIZE, VIRTUAL_VIDEO_DURATION, END_PADDING_SECONDS
    global PAUSE_ON_LAUNCH, FORCE_WINDOW, RESUME_PLAYBACK
    global BLACK_VIDEO_FILE, MPV_EXECUTABLE, MPV_FALLBACK_PATHS
    global LOG_DIR, MPV_LOG_FILE, LAUNCH_LOG_FILE, MPV_CONF_READER_OVERRIDES
    global READER_MAX_LINES_PER_BLOCK, READER_MAX_CHARS_PER_LINE, READER_MIN_BLOCKS
    global READER_OPTIMAL_CHARACTERS_PER_SECOND, READER_OPTIMAL_WORDS_PER_MINUTE
    global READER_MIN_CUE_SECONDS, READER_MAX_CUE_SECONDS, READER_MIN_DATE_SECONDS

    SUPPORTED_EXTENSIONS = _parse_extensions(
        _config_get(config, "input", "subtitle_extensions", ",".join(SUPPORTED_EXTENSIONS)),
        SUPPORTED_EXTENSIONS,
    )
    SUPPORTED_TEXT_EXTENSIONS = _parse_extensions(
        _config_get(config, "input", "text_extensions", ",".join(SUPPORTED_TEXT_EXTENSIONS)),
        SUPPORTED_TEXT_EXTENSIONS,
    )

    LANG_SUFFIXES = tuple(lang.lower() for lang in _split_csv(
        _config_get(config, "languages", "language_suffixes", ",".join(LANG_SUFFIXES))
    )) or LANG_SUFFIXES
    LANG_SELECTION_PRIORITY = _parse_priority_map(
        _config_get(
            config,
            "languages",
            "language_selection_priority",
            ",".join(f"{lang}:{rank}" for lang, rank in LANG_SELECTION_PRIORITY.items()),
        ),
        LANG_SELECTION_PRIORITY,
    )

    MPV_EXECUTABLE = os.path.expandvars(_config_get(config, "paths", "mpv_executable", MPV_EXECUTABLE))
    MPV_FALLBACK_PATHS = _parse_path_list(
        config.get("paths", "mpv_fallback_paths", fallback=""),
        MPV_FALLBACK_PATHS,
    )
    BLACK_VIDEO_FILE = _config_get(config, "paths", "black_video_file", BLACK_VIDEO_FILE)
    LOG_DIR = _config_get(config, "paths", "log_dir", LOG_DIR)
    MPV_LOG_FILE = _config_get(config, "paths", "mpv_log_file", MPV_LOG_FILE)
    LAUNCH_LOG_FILE = _config_get(config, "paths", "launch_log_file", LAUNCH_LOG_FILE)

    VIRTUAL_VIDEO_COLOR = _config_get(config, "player", "virtual_video_color", VIRTUAL_VIDEO_COLOR)
    VIRTUAL_VIDEO_SIZE = _config_get(config, "player", "virtual_video_size", VIRTUAL_VIDEO_SIZE)
    VIRTUAL_VIDEO_DURATION = _config_get_int(config, "player", "virtual_video_duration", VIRTUAL_VIDEO_DURATION)
    END_PADDING_SECONDS = _config_get_float(config, "player", "end_padding_seconds", END_PADDING_SECONDS)
    PAUSE_ON_LAUNCH = _config_get(config, "player", "pause_on_launch", PAUSE_ON_LAUNCH)
    FORCE_WINDOW = _config_get(config, "player", "force_window", FORCE_WINDOW)
    RESUME_PLAYBACK = _config_get(config, "player", "resume_playback", RESUME_PLAYBACK)

    READER_MAX_LINES_PER_BLOCK = _config_get_int(config, "reader", "max_lines_per_block", READER_MAX_LINES_PER_BLOCK)
    READER_MAX_CHARS_PER_LINE = _config_get_int(config, "reader", "max_chars_per_line", READER_MAX_CHARS_PER_LINE)
    READER_MIN_BLOCKS = _config_get_int(config, "reader", "min_blocks", READER_MIN_BLOCKS)
    READER_OPTIMAL_CHARACTERS_PER_SECOND = _config_get_float(config, "reader", "cps", READER_OPTIMAL_CHARACTERS_PER_SECOND)
    READER_OPTIMAL_WORDS_PER_MINUTE = _config_get_float(config, "reader", "wpm", READER_OPTIMAL_WORDS_PER_MINUTE)
    READER_MIN_CUE_SECONDS = _config_get_float(config, "reader", "min_cue_seconds", READER_MIN_CUE_SECONDS)
    READER_MAX_CUE_SECONDS = _config_get_float(config, "reader", "max_cue_seconds", READER_MAX_CUE_SECONDS)
    READER_MIN_DATE_SECONDS = _config_get_float(config, "reader", "min_date_seconds", READER_MIN_DATE_SECONDS)
    MPV_CONF_READER_OVERRIDES = _config_get_bool(config, "reader", "mpv_conf_overrides", MPV_CONF_READER_OVERRIDES)


def _find_mpv_conf():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    candidate = script_dir
    for _ in range(5):
        conf = os.path.join(candidate, "mpv.conf")
        if os.path.exists(conf):
            return conf
        parent = os.path.dirname(candidate)
        if parent == candidate:
            break
        candidate = parent
    appdata = os.environ.get("APPDATA", "")
    if appdata:
        fallback = os.path.join(appdata, "mpv", "mpv.conf")
        if os.path.exists(fallback):
            return fallback
    return None


def _parse_kardenwort_reader_opts(mpv_conf_path):
    opts = {}
    if not mpv_conf_path:
        return opts
    try:
        with open(mpv_conf_path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                line = line.strip()
                m = re.match(r'^script-opts-append\s*=\s*kardenwort-reader_(\w+)\s*=\s*(.+)$', line)
                if m:
                    opts[m.group(1)] = m.group(2).strip()
                elif re.match(r'^script-opts\s*=', line):
                    value_part = line.split('=', 1)[1]
                    for segment in value_part.split(','):
                        m2 = re.match(r'^kardenwort-reader_(\w+)=(.+)$', segment.strip())
                        if m2:
                            opts[m2.group(1)] = m2.group(2).strip()
    except Exception:
        pass
    return opts


def _apply_reader_opts(opts):
    global READER_MAX_CUE_SECONDS, READER_MIN_CUE_SECONDS, READER_MIN_DATE_SECONDS
    global READER_OPTIMAL_CHARACTERS_PER_SECOND, READER_OPTIMAL_WORDS_PER_MINUTE
    global READER_MAX_CHARS_PER_LINE
    float_keys = {
        'max_cue_seconds': 'READER_MAX_CUE_SECONDS',
        'min_cue_seconds': 'READER_MIN_CUE_SECONDS',
        'min_date_seconds': 'READER_MIN_DATE_SECONDS',
        'cps': 'READER_OPTIMAL_CHARACTERS_PER_SECOND',
        'wpm': 'READER_OPTIMAL_WORDS_PER_MINUTE',
    }
    int_keys = {
        'max_chars_per_line': 'READER_MAX_CHARS_PER_LINE',
    }
    g = globals()
    for key, var in float_keys.items():
        if key in opts:
            try:
                g[var] = float(opts[key])
            except ValueError:
                pass
    for key, var in int_keys.items():
        if key in opts:
            try:
                g[var] = int(opts[key])
            except ValueError:
                pass


def log_error_and_alert(error_msg):
    """
    Logs the error to a local file and displays a Windows MessageBox popup.
    """
    log_path = _resolve_config_path(LAUNCH_LOG_FILE)
    
    # Write to local log file
    try:
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(f"=== ERROR OCCURRED ===\n{error_msg}\n\n")
    except Exception:
        pass
        
    # Graphical popup for Windows users
    if os.name == 'nt':
        try:
            import ctypes
            ctypes.windll.user32.MessageBoxW(
                0, 
                f"Kardenwort Sub Viewer could not start:\n\n{error_msg}\n\nDetails have been logged to:\n{log_path}", 
                "Kardenwort Sub Viewer Error", 
                0x10  # MB_ICONERROR
            )
        except Exception:
            pass

def get_first_sub_start(filepath, max_duration=36000):
    """
    Parses the subtitle file to find the start time of the very first subtitle entry.
    Returns the time in seconds (float) or None.
    """
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception:
        return None

    time_pat = re.compile(r'(\d{2,})[:](\d{2})[:](\d{2})[.,](\d{3})')
    
    for line in content.splitlines():
        if '-->' in line:
            matches = time_pat.findall(line)
            if len(matches) >= 1:
                parts = matches[0]
                hh = int(parts[0])
                mm = int(parts[1])
                ss = int(parts[2])
                ms = int(parts[3])
                total_secs = hh * 3600 + mm * 60 + ss + ms / 1000.0
                if 0.0 <= total_secs < max_duration:
                    return total_secs

        elif line.startswith('Dialogue:'):
            parts = line.split(',', 9)
            if len(parts) > 2:
                start_str = parts[1].strip()
                match_ass = re.match(r'(\d+):(\d{2}):(\d{2})\.(\d{2})', start_str)
                if match_ass:
                    h, m, s, cs = match_ass.groups()
                    total_secs = int(h) * 3600 + int(m) * 60 + int(s) + int(cs) / 100.0
                    if 0.0 <= total_secs < max_duration:
                        return total_secs
    return None

def get_last_sub_end(filepath, max_duration=36000):
    """
    Parses the subtitle file to find the end time of the very last subtitle entry.
    Returns the time in seconds (float) or None.
    """
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception:
        return None

    time_pat = re.compile(r'(\d{2,})[:](\d{2})[:](\d{2})[.,](\d{3})')
    last_end = 0.0
    
    for line in content.splitlines():
        if '-->' in line:
            matches = time_pat.findall(line)
            if len(matches) >= 2:
                parts = matches[1]
                hh = int(parts[0])
                mm = int(parts[1])
                ss = int(parts[2])
                ms = int(parts[3])
                total_secs = hh * 3600 + mm * 60 + ss + ms / 1000.0
                if total_secs > last_end and total_secs < max_duration:
                    last_end = total_secs

        elif line.startswith('Dialogue:'):
            parts = line.split(',', 9)
            if len(parts) > 2:
                end_str = parts[2].strip()
                match_ass = re.match(r'(\d+):(\d{2}):(\d{2})\.(\d{2})', end_str)
                if match_ass:
                    h, m, s, cs = match_ass.groups()
                    total_secs = int(h) * 3600 + int(m) * 60 + int(s) + int(cs) / 100.0
                    if total_secs > last_end and total_secs < max_duration:
                        last_end = total_secs
                        
    return last_end if last_end > 0.0 else None


def _language_suffix_rank(filename_without_ext):
    parts = filename_without_ext.split('.')
    if len(parts) <= 1:
        return len(LANG_SUFFIXES), ""
    suffix = parts[-1].lower()
    if suffix in LANG_SUFFIXES:
        return LANG_SUFFIXES.index(suffix), suffix
    return len(LANG_SUFFIXES), suffix


def find_secondary_subtitle(sub_dir, main_base, primary_sub_path):
    """
    Deterministically selects a secondary subtitle track.
    Priority:
    1) Same basename + known language suffix rank (LANG_SUFFIXES order)
    2) Lexicographic path order as deterministic fallback
    """
    if not os.path.isdir(sub_dir):
        return None

    candidates = []
    primary_abs = os.path.abspath(primary_sub_path)
    prefix = main_base.lower() + "."

    for entry in os.listdir(sub_dir):
        full_path = os.path.join(sub_dir, entry)
        if not os.path.isfile(full_path):
            continue
        if os.path.abspath(full_path) == primary_abs:
            continue
        if not entry.lower().startswith(prefix):
            continue
        stem, ext = os.path.splitext(entry)
        if ext.lower() not in SUPPORTED_EXTENSIONS:
            continue
        lang_rank, lang_suffix = _language_suffix_rank(stem)
        candidates.append((lang_rank, lang_suffix, entry.lower(), full_path))

    if not candidates:
        return None

    candidates.sort(key=lambda item: (item[0], item[1], item[2]))
    return candidates[0][3]


def _seconds_to_srt_time(total_seconds):
    total_ms = int(round(total_seconds * 1000))
    hh = total_ms // 3600000
    rem = total_ms % 3600000
    mm = rem // 60000
    rem = rem % 60000
    ss = rem // 1000
    ms = rem % 1000
    return f"{hh:02}:{mm:02}:{ss:02},{ms:03}"


def _split_long_line(line, max_chars=90):
    words = line.split()
    if not words:
        return []
    out = []
    cur = words[0]
    for word in words[1:]:
        candidate = f"{cur} {word}"
        if len(candidate) <= max_chars:
            cur = candidate
        else:
            out.append(cur)
            cur = word
    out.append(cur)
    return out


def _line_to_cue_text(line):
    stripped = line.strip()
    if not stripped:
        return ""
    wrapped = _split_long_line(stripped, READER_MAX_CHARS_PER_LINE)
    return "\n".join(wrapped)


def _estimate_cue_duration_seconds(cue_text):
    clean = cue_text.replace("\\N", " ").replace("\n", " ").strip()
    if not clean:
        return READER_MIN_CUE_SECONDS

    char_count = len(clean)
    word_count = len(re.findall(r"\S+", clean))

    cps = READER_OPTIMAL_CHARACTERS_PER_SECOND
    if cps < 2.0 or cps > 100.0:
        cps = 14.7

    char_ms = (char_count / cps) * 1000.0
    if char_ms < 1400.0:
        char_ms *= 1.2
    elif char_ms < 1680.0:
        char_ms = 1680.0
    elif char_ms > 2900.0:
        char_ms = max(2900.0, char_ms * 0.96)

    wpm = READER_OPTIMAL_WORDS_PER_MINUTE
    if wpm < 30.0:
        wpm = 30.0
    words_per_second = wpm / 60.0
    word_ms = (word_count / words_per_second) * 1000.0 if word_count > 0 else 0.0

    duration_ms = max(char_ms, word_ms)
    if _DATE_RE.search(clean):
        duration_ms = max(duration_ms, READER_MIN_DATE_SECONDS * 1000.0)
    min_ms = READER_MIN_CUE_SECONDS * 1000.0
    display_lines = cue_text.count('\n') + 1
    max_ms = READER_MAX_CUE_SECONDS * display_lines * 1000.0
    duration_ms = max(min_ms, min(max_ms, duration_ms))
    return duration_ms / 1000.0


def _build_timed_cues(cues: List[str]) -> List[Tuple[float, float, str]]:
    timed_cues = []
    current_start = 0.0
    for cue_text in cues:
        duration = _estimate_cue_duration_seconds(cue_text)
        start = current_start
        end = start + duration
        timed_cues.append((start, end, cue_text))
        current_start = end
    return timed_cues


def _text_to_blocks(text):
    """
    Convert free text into subtitle blocks suitable for reader navigation.
    Rules:
    - Empty line flushes current block.
    - Long prose lines are wrapped to READER_MAX_CHARS_PER_LINE.
    - Each block is capped at READER_MAX_LINES_PER_BLOCK to guarantee multiple cues.
    """
    blocks = []
    current_lines = []

    for raw in text.splitlines():
        stripped = raw.strip()
        if not stripped:
            if current_lines:
                blocks.append("\n".join(current_lines))
                current_lines = []
            continue

        wrapped = _split_long_line(stripped, READER_MAX_CHARS_PER_LINE)
        for wrapped_line in wrapped:
            current_lines.append(wrapped_line)
            if len(current_lines) >= READER_MAX_LINES_PER_BLOCK:
                blocks.append("\n".join(current_lines))
                current_lines = []

    if current_lines:
        blocks.append("\n".join(current_lines))

    return blocks


def current_zid():
    return datetime.now().strftime("%Y%m%d%H%M%S")


def _build_reader_output_path(text_path, force_zid=None):
    input_dir = os.path.dirname(text_path)
    input_stem = os.path.splitext(os.path.basename(text_path))[0]

    base_candidate = os.path.join(input_dir, f"{input_stem}.srt")
    if force_zid is None and not os.path.exists(base_candidate):
        return base_candidate

    zid = force_zid or current_zid()
    zid_dir = os.path.join(input_dir, zid)
    os.makedirs(zid_dir, exist_ok=True)

    candidate = os.path.join(zid_dir, f"{input_stem}.srt")
    if not os.path.exists(candidate):
        return candidate

    index = 1
    while True:
        collision_candidate = os.path.join(zid_dir, f"{input_stem}.{index}.srt")
        if not os.path.exists(collision_candidate):
            return collision_candidate
        index += 1


def build_reader_srt(text_path):
    with open(text_path, "r", encoding="utf-8", errors="ignore") as f:
        text = f.read()

    blocks = _text_to_blocks(text)
    if not blocks:
        raise ValueError(f"Text file is empty or has no readable lines: {text_path}")

    if len(blocks) < READER_MIN_BLOCKS:
        # Force at least 2 cues for meaningful seek/navigation UX.
        only = blocks[0]
        parts = _split_long_line(only.replace("\\N", " ").replace("\n", " "), READER_MAX_CHARS_PER_LINE // 2)
        if len(parts) >= 2:
            mid = len(parts) // 2
            blocks = [" ".join(parts[:mid]), " ".join(parts[mid:])]

    cue_lines = []
    timed_cues = _build_timed_cues(blocks)
    for idx, (start, end, block) in enumerate(timed_cues, 1):
        cue_lines.append(str(idx))
        cue_lines.append(f"{_seconds_to_srt_time(start)} --> {_seconds_to_srt_time(end)}")
        cue_lines.append(block)
        cue_lines.append("")

    output_path = _build_reader_output_path(text_path)
    with open(output_path, "w", encoding="utf-8", newline="\n") as out:
        out.write("\n".join(cue_lines))
    return output_path


def _write_reader_srt_from_timed_cues(timed_cues, cue_texts, source_text_path, force_zid=None):
    cue_lines = []
    for idx, ((start, end, _), cue_text) in enumerate(zip(timed_cues, cue_texts), 1):
        cue_lines.append(str(idx))
        cue_lines.append(f"{_seconds_to_srt_time(start)} --> {_seconds_to_srt_time(end)}")
        cue_lines.append(cue_text)
        cue_lines.append("")

    output_path = _build_reader_output_path(source_text_path, force_zid=force_zid)
    with open(output_path, "w", encoding="utf-8", newline="\n") as out:
        out.write("\n".join(cue_lines))
    return output_path


def build_parallel_reader_srts(primary_text_path, secondary_text_path):
    with open(primary_text_path, "r", encoding="utf-8", errors="ignore") as f:
        primary_lines = [line.rstrip("\n") for line in f]
    with open(secondary_text_path, "r", encoding="utf-8", errors="ignore") as f:
        secondary_lines = [line.rstrip("\n") for line in f]

    max_len = max(len(primary_lines), len(secondary_lines))
    primary_cues = []
    secondary_cues = []

    for idx in range(max_len):
        p_line = primary_lines[idx] if idx < len(primary_lines) else ""
        s_line = secondary_lines[idx] if idx < len(secondary_lines) else ""
        p_cue = _line_to_cue_text(p_line)
        s_cue = _line_to_cue_text(s_line)
        if not p_cue and not s_cue:
            continue
        primary_cues.append(p_cue or " ")
        secondary_cues.append(s_cue or " ")

    if not primary_cues:
        raise ValueError(
            f"Both text files are empty or have no readable lines: {primary_text_path}, {secondary_text_path}"
        )

    primary_base_srt = os.path.splitext(primary_text_path)[0] + ".srt"
    secondary_base_srt = os.path.splitext(secondary_text_path)[0] + ".srt"
    use_shared_zid = os.path.exists(primary_base_srt) or os.path.exists(secondary_base_srt)
    shared_zid = current_zid() if use_shared_zid else None

    primary_timed_cues = _build_timed_cues(primary_cues)
    primary_srt_path = _write_reader_srt_from_timed_cues(
        primary_timed_cues,
        primary_cues,
        primary_text_path,
        force_zid=shared_zid,
    )
    secondary_srt_path = _write_reader_srt_from_timed_cues(
        primary_timed_cues,
        secondary_cues,
        secondary_text_path,
        force_zid=shared_zid,
    )
    return primary_srt_path, secondary_srt_path


def resolve_subtitle_input(input_path):
    ext = os.path.splitext(input_path)[1].lower()
    if ext in SUPPORTED_EXTENSIONS:
        return input_path, False
    if ext in SUPPORTED_TEXT_EXTENSIONS:
        return build_reader_srt(input_path), True
    raise ValueError(
        f"Unsupported file type '{ext}'. Supported subtitle formats: {', '.join(SUPPORTED_EXTENSIONS)}. "
        f"Supported reader text formats: {', '.join(SUPPORTED_TEXT_EXTENSIONS)}."
    )


def normalize_cli_input_paths(argv):
    raw_args = argv[1:]
    normalized = []
    for raw_arg in raw_args:
        if raw_arg == "%1":
            continue
        normalized.append(os.path.abspath(raw_arg))
    return normalized


def _selection_sort_key(path, original_index):
    stem = os.path.splitext(os.path.basename(path))[0]
    parts = stem.split(".")
    lang_suffix = parts[-1].lower() if len(parts) > 1 else ""
    base_without_lang = ".".join(parts[:-1]) if lang_suffix in LANG_SUFFIXES and len(parts) > 1 else stem

    match_num = re.search(r"(\d+)$", base_without_lang)
    number_rank = int(match_num.group(1)) if match_num else 10**9
    lang_rank = LANG_SELECTION_PRIORITY.get(lang_suffix, 10**6)

    return (number_rank, lang_rank, stem.lower(), original_index)


def order_input_paths_for_roles(input_paths):
    indexed = list(enumerate(input_paths))
    indexed.sort(key=lambda item: _selection_sort_key(item[1], item[0]))
    return [path for _, path in indexed]


def resolve_secondary_subtitle(primary_input_path, primary_sub_path, primary_generated_reader_sub, explicit_secondary_input_path):
    if explicit_secondary_input_path:
        explicit_abs = os.path.abspath(explicit_secondary_input_path)
        if explicit_abs != os.path.abspath(primary_input_path):
            secondary_sub_path, _ = resolve_subtitle_input(explicit_abs)
            return secondary_sub_path
        return None

    if primary_generated_reader_sub:
        return None

    sub_dir, sub_file = os.path.split(primary_input_path)
    sub_base, _ = os.path.splitext(sub_file)
    parts = sub_base.split('.')
    if len(parts) > 1 and parts[-1].lower() in LANG_SUFFIXES:
        main_base = '.'.join(parts[:-1])
    else:
        main_base = sub_base
    return find_secondary_subtitle(sub_dir, main_base, primary_sub_path)


def get_mpv_log_path():
    """
    Keep mpv runtime logs out of user content folders.
    """
    logs_dir = _resolve_config_path(LOG_DIR)
    os.makedirs(logs_dir, exist_ok=True)
    return os.path.join(logs_dir, MPV_LOG_FILE)


def resolve_mpv_executable():
    if MPV_EXECUTABLE:
        configured = _resolve_config_path(MPV_EXECUTABLE)
        if os.path.exists(configured):
            return configured

    mpv_exe = shutil.which('mpv')
    if mpv_exe:
        return mpv_exe

    for path in MPV_FALLBACK_PATHS:
        expanded = os.path.expandvars(path)
        if os.path.exists(expanded):
            return expanded
    return None


def main():
    try:
        apply_config(load_config())
        if MPV_CONF_READER_OVERRIDES:
            _apply_reader_opts(_parse_kardenwort_reader_opts(_find_mpv_conf()))

        if len(sys.argv) < 2:
            raise ValueError("No file provided. Drag and drop a subtitle/text file onto the script or shortcut.")

        input_paths = normalize_cli_input_paths(sys.argv)
        if not input_paths:
            raise ValueError("No file provided. Drag and drop a subtitle/text file onto the script or shortcut.")

        ordered_input_paths = order_input_paths_for_roles(input_paths)
        input_path = ordered_input_paths[0]
        secondary_input_path = ordered_input_paths[1] if len(ordered_input_paths) >= 2 else None
        if not os.path.isfile(input_path):
            raise FileNotFoundError(f"Input file not found: {input_path}")
        if secondary_input_path and not os.path.isfile(secondary_input_path):
            raise FileNotFoundError(f"Secondary input file not found: {secondary_input_path}")

        primary_ext = os.path.splitext(input_path)[1].lower()
        secondary_ext = os.path.splitext(secondary_input_path)[1].lower() if secondary_input_path else ""

        if secondary_input_path and primary_ext in SUPPORTED_TEXT_EXTENSIONS and secondary_ext in SUPPORTED_TEXT_EXTENSIONS:
            sub_path, secondary_sub = build_parallel_reader_srts(input_path, secondary_input_path)
            generated_reader_sub = True
        else:
            sub_path, generated_reader_sub = resolve_subtitle_input(input_path)
            secondary_sub = resolve_secondary_subtitle(
                input_path,
                sub_path,
                generated_reader_sub,
                secondary_input_path
            )

        # 1. Resolve base directory and file name
        sub_dir, sub_file = os.path.split(input_path)
        sub_base, sub_ext = os.path.splitext(sub_file)

        # 2. Support Kardenwort language suffix naming (e.g. file.de.srt -> base is file)
        parts = sub_base.split('.')
        if len(parts) > 1 and parts[-1].lower() in LANG_SUFFIXES:
            main_base = '.'.join(parts[:-1])
        else:
            main_base = sub_base

        # 3. Determine the highlight TSV path
        tsv_path = os.path.join(sub_dir, f"{main_base}.tsv")

        # 4. Secondary track is already resolved above.

        # 5. Locate mpv executable robustly on the system
        mpv_exe = resolve_mpv_executable()

        if not mpv_exe:
            raise FileNotFoundError(
                "Could not find the 'mpv' player. Please ensure it is installed\n"
                "and either added to your system environment variables (PATH) or\n"
                "configured via mpv_executable or mpv_fallback_paths in config.ini."
            )

        # 6. Build the mpv command using configuration values
        black_video = _resolve_config_path(BLACK_VIDEO_FILE)
        if not os.path.exists(black_video):
            raise FileNotFoundError(
                f"Bundled seekable canvas is missing: {black_video}\n"
                "Run scripts/_tools/sub-viewer/install.py to generate or restore black.mp4."
            )
        video_input = black_video

        log_path = get_mpv_log_path()
        cmd = [
            mpv_exe,
            video_input,
            f'--sub-file={sub_path}',
            f'--script-opts-append=kardenwort-anki_record_file={tsv_path}',
            f'--pause={PAUSE_ON_LAUNCH}',
            f'--log-file={log_path}',
            f'--force-window={FORCE_WINDOW}',
        ]
        if RESUME_PLAYBACK.strip().lower() in ("no", "false", "0"):
            cmd.append('--no-resume-playback')
        else:
            cmd.append(f'--resume-playback={RESUME_PLAYBACK}')

        # If secondary subtitles were found, load them as the secondary track
        if secondary_sub:
            cmd.append(f'--sub-file={secondary_sub}')
            cmd.append('--sid=1')
            cmd.append('--secondary-sid=2')

        # 7. Parse first subtitle start time to auto-seek to the first card on load
        start_time = get_first_sub_start(sub_path, VIRTUAL_VIDEO_DURATION)
        if start_time is not None:
            cmd.append(f'--start={start_time}')

        # 8. Dynamically clip the timeline to match the subtitle length exactly
        last_end = get_last_sub_end(sub_path, VIRTUAL_VIDEO_DURATION)
        if last_end is not None and last_end > 0:
            # Add configured padding for comfortable OSD breathing room at the end
            cmd.append(f'--length={last_end + END_PADDING_SECONDS}')

        # 9. Launch mpv normally so it gains foreground focus and detaches cleanly
        # Use CREATE_NO_WINDOW to prevent Windows Terminal or CMD from spawning a secondary black window
        creationflags = 0
        if os.name == 'nt':
            creationflags = 0x08000000  # CREATE_NO_WINDOW
            
        subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=creationflags
        )

    except Exception as e:
        error_msg = f"{e}\n\nTraceback:\n{traceback.format_exc()}"
        log_error_and_alert(error_msg)
        sys.exit(1)

if __name__ == '__main__':
    main()
