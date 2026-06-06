#!/usr/bin/env python
# ==============================================================================
# Kardenwort Sub TTS Pipeline
# Converts SRT subtitle files to MP4 (black canvas + Piper TTS speech audio).
#
# Usage (CLI):
#   python sub_tts.py video.de.srt
#   python sub_tts.py video.de.srt --lang de --output-dir C:/out
#   python sub_tts.py --sendto video.de.srt lesson.ru.srt
#
# Installation (Windows SendTo):
#   python install.py
# ==============================================================================

import argparse
import configparser
import re
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import datetime
from pathlib import Path

# ==============================================================================
# GLOBAL CONSTANTS
# ==============================================================================
SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_FILE = SCRIPT_DIR / "config.ini"
CONFIG_TEMPLATE = SCRIPT_DIR / "config.ini.template"

# Console auto-close timeout in seconds (on successful runs in SendTo/pause mode)
PAUSE_AUTO_CLOSE_TIMEOUT_SECS = 15

SHORTCUT_DISPLAY_NAME = "Kardenwort Sub TTS"

# ==============================================================================
# PIP-STYLE CONSOLE OUTPUT HELPERS
# ==============================================================================
_IS_TTY = sys.stdout.isatty()

def _c(code, text):
    """Wraps text in an ANSI escape if stdout is a TTY."""
    return f"\x1b[{code}m{text}\x1b[0m" if _IS_TTY else text

def _tag_info():    return _c("1;36", "[INFO]")
def _tag_warn():    return _c("1;33", "[WARN]")
def _tag_error():   return _c("1;31", "[ERROR]")
def _tag_ok():      return _c("1;32", "[OK]")
def _tag_skip():    return _c("1;35", "[SKIP]")

def _dim(text):     return _c("90", text)
def _bold(text):    return _c("1", text)
def _cyan(text):    return _c("36", text)
def _green(text):   return _c("32", text)

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
    """Clears the current console line completely to prevent character leftovers."""
    sys.stdout.write("\r\x1b[K" + " " * width + "\r")
    sys.stdout.flush()

def make_cue_progress_bar(current, total, label, detail="", bar_width=40, indent="  "):
    percent_val = (current / total) * 100.0 if total > 0 else 0
    filled_width = int(round(bar_width * percent_val / 100.0))
    bar = _green("━" * filled_width) + _dim("━" * (bar_width - filled_width))
    tag = _dim(f"[{current}/{total}]")
    
    line = f"\r{indent}{bar} {tag} {label}"
    if detail:
        line += f": {_dim(detail)}"
    return line


# Built-in alias table: subtitle filename postfix → Piper language code
BUILTIN_LANG_ALIASES = {
    "eng": "en",
    "ger": "de",
    "deu": "de",
    "rus": "ru",
    "ukr": "uk",
    "spa": "es",
    "fra": "fr",
    "ita": "it",
    # Short forms are identity-mapped implicitly (no alias needed)
}

# Known language postfix candidates (short forms)
KNOWN_LANG_CODES = {"en", "de", "ru", "uk", "es", "fr", "it"}

# FFmpeg black-canvas video encoding parameters (mirrors convert_media.py)
DEFAULT_VIDEO_FILTER = "color=c=black:s=256x144"
DEFAULT_VIDEO_CODEC = "libx264"
DEFAULT_VIDEO_PRESET = "veryslow"
DEFAULT_VIDEO_CRF = "36"
DEFAULT_VIDEO_TUNE = "stillimage"
DEFAULT_VIDEO_X264_PARAMS = "keyint=300:min-keyint=300:scenecut=0"
DEFAULT_VIDEO_FPS = "15"
DEFAULT_PIXEL_FORMAT = "yuv420p"
DEFAULT_AUDIO_CODEC = "aac"
DEFAULT_AUDIO_BITRATE = "128k"
DEFAULT_MOVFLAGS = "+faststart"

_FFMPEG_FILTER_CACHE = {}


# ==============================================================================
# CONFIGURATION LOADING
# ==============================================================================

def load_config():
    """Load and validate config.ini. Exits with a clear message if missing."""
    if not CONFIG_FILE.exists():
        template_hint = f"copy '{CONFIG_TEMPLATE}' to '{CONFIG_FILE}'"
        print(
            f"Error: Configuration file not found at '{CONFIG_FILE}'.\n"
            f"Please {template_hint} and edit the paths.",
            file=sys.stderr,
        )
        sys.exit(1)

    config = configparser.ConfigParser()
    config.read(CONFIG_FILE, encoding="utf-8")
    return config


def get_piper_config(config):
    """Load the Piper TTS config.ini from the configured piper_tts_root."""
    piper_root = Path(config.get("paths", "piper_tts_root"))
    piper_config_path = piper_root / "config.ini"

    if not piper_root.exists():
        print(f"Error: piper_tts_root does not exist: '{piper_root}'", file=sys.stderr)
        sys.exit(1)

    if not piper_config_path.exists():
        print(
            f"Error: Piper TTS config.ini not found at '{piper_config_path}'.",
            file=sys.stderr,
        )
        sys.exit(1)

    piper_config = configparser.ConfigParser()
    piper_config.read(piper_config_path, encoding="utf-8")
    return piper_config, piper_root


def get_supported_languages(piper_config):
    """Return the set of language codes supported by Piper TTS."""
    raw = piper_config.get("tts_settings", "supported_languages", fallback="en")
    return {lang.strip() for lang in raw.split(",")}


# ==============================================================================
# SRT PARSER (tasks 2.1 – 2.3)
# ==============================================================================

_SRT_TIME_RE = re.compile(
    r"(\d{2,}):(\d{2}):(\d{2})[,.](\d{3})"
)
_HTML_TAG_RE = re.compile(r"<[^>]+>")
_ASS_TAG_RE = re.compile(r"\{[^}]+\}")
_SRT_INDEX_RE = re.compile(r"^\d+\s*$")


def _parse_time_to_ms(h, m, s, ms):
    return (int(h) * 3600 + int(m) * 60 + int(s)) * 1000 + int(ms)


def sanitize_text(text):
    """Strip HTML and ASS override tags, normalize whitespace."""
    text = _HTML_TAG_RE.sub("", text)
    text = _ASS_TAG_RE.sub("", text)
    # Collapse internal whitespace / newlines
    text = re.sub(r"[\r\n]+", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def parse_srt(filepath):
    """
    Parse an SRT file and return a list of cue dicts:
        {index: int, start_ms: int, end_ms: int, text: str}

    Handles:
      - BOM-prefixed UTF-8 files
      - Multi-line cue text
      - Empty cues (excluded from output)
    """
    path = Path(filepath)
    if not path.exists():
        raise FileNotFoundError(f"SRT file not found: '{filepath}'")

    content = path.read_text(encoding="utf-8-sig", errors="replace")  # utf-8-sig strips BOM

    cues = []
    # Split on blank lines between blocks
    blocks = re.split(r"\n{2,}", content.strip().replace("\r\n", "\n").replace("\r", "\n"))

    for block in blocks:
        lines = block.strip().splitlines()
        if not lines:
            continue

        # First line: cue index (skip if it's not a number)
        idx_line = lines[0].strip()
        if not _SRT_INDEX_RE.match(idx_line):
            continue
        cue_index = int(idx_line)

        if len(lines) < 2:
            continue

        # Second line: timecode
        time_line = lines[1].strip()
        time_parts = _SRT_TIME_RE.findall(time_line)
        if len(time_parts) < 2:
            continue

        start_ms = _parse_time_to_ms(*time_parts[0])
        end_ms = _parse_time_to_ms(*time_parts[1])

        # Remaining lines: text (may be multi-line)
        raw_text = " ".join(line.strip() for line in lines[2:] if line.strip())
        clean_text = sanitize_text(raw_text)

        if not clean_text:
            # Skip empty cues (after stripping tags)
            continue

        cues.append({
            "index": cue_index,
            "start_ms": start_ms,
            "end_ms": end_ms,
            "text": clean_text,
        })

    return cues


# ==============================================================================
# LANGUAGE DETECTION (tasks 3.1 – 3.3)
# ==============================================================================

def build_alias_map(config):
    """
    Build a normalized alias map from built-ins + [lang_aliases] in config.
    Result: {postfix_lower: language_code}
    """
    alias_map = dict(BUILTIN_LANG_ALIASES)  # copy built-ins

    if config.has_section("lang_aliases"):
        for postfix, lang_code in config.items("lang_aliases"):
            alias_map[postfix.strip().lower()] = lang_code.strip().lower()

    return alias_map


def detect_language(filepath, config):
    """
    Detect language from filename postfix (e.g., video.de.srt → 'de').
    Falls back to config default_lang when no postfix is recognized.

    Returns the resolved language code string.
    """
    stem = Path(filepath).stem  # e.g., 'video.de' from 'video.de.srt'
    parts = stem.rsplit(".", 1)
    alias_map = build_alias_map(config)

    if len(parts) == 2:
        candidate = parts[1].lower()
        # Direct short code?
        if candidate in KNOWN_LANG_CODES:
            return candidate
        # Via alias map?
        if candidate in alias_map:
            return alias_map[candidate]

    # Fallback to default
    default = config.get("tts_settings", "default_lang", fallback="en").strip()
    return default


def validate_language(lang, piper_config, supported_languages):
    """
    Ensure the detected language has a voice section in Piper's config.
    Exits with an informative message if unsupported.
    """
    if lang not in supported_languages:
        print(
            f"Error: Language '{lang}' is not supported by your Piper TTS installation.\n"
            f"Supported languages (from Piper config.ini): {sorted(supported_languages)}\n"
            f"Add the voice to Piper's config.ini or use --lang to specify a supported language.",
            file=sys.stderr,
        )
        sys.exit(1)

    section = f"voice_{lang}"
    if not piper_config.has_section(section):
        print(
            f"Error: Piper TTS config.ini has language '{lang}' listed in supported_languages\n"
            f"but is missing the '[{section}]' voice section.",
            file=sys.stderr,
        )
        sys.exit(1)


# ==============================================================================
# ZID GENERATION (task 6.3)
# ==============================================================================

def get_zid(config):
    """Generate a ZID timestamp using zid.py if available, else datetime.now()."""
    zid_script = config.get("paths", "zid_script", fallback="").strip()
    if zid_script:
        zid_path = Path(zid_script)
        if zid_path.exists():
            try:
                result = subprocess.run(
                    [sys.executable, str(zid_path), "--no-clipboard"],
                    capture_output=True, text=True, check=True, timeout=5,
                )
                zid = result.stdout.strip()
                if zid and zid.isdigit() and len(zid) == 14:
                    return zid
            except Exception:
                pass

    return datetime.now().strftime("%Y%m%d%H%M%S")


# ==============================================================================
# OUTPUT PATH RESOLUTION (tasks 6.2 + 6.3)
# ==============================================================================

def strip_lang_postfix(stem, lang):
    """
    Strip the language postfix from the stem if present.
    e.g., 'video.de' with lang='de' → 'video'
         'video.rus' with lang='ru' and alias → 'video'
         'video' (no postfix) → 'video'
    """
    # Check if the rightmost extension of stem matches the lang code
    # or any of its known source aliases.
    parts = stem.rsplit(".", 1)
    if len(parts) == 2:
        candidate = parts[1].lower()
        # Build alias reverse map: lang_code → [postfixes that map to it]
        all_postfixes = {lang}  # include the code itself
        for postfix, code in BUILTIN_LANG_ALIASES.items():
            if code == lang:
                all_postfixes.add(postfix)
        if candidate in all_postfixes:
            return parts[0]
    return stem


def resolve_output_path(srt_path, output_dir, config, lang, zid_cache, keep_lang_postfix=None):
    """
    Build the output .mp4 path.
    Policy: base filename + .mp4 in output_dir; language postfix stripped unless
    keep_lang_postfix is True (via argument or tts_settings.keep_lang_postfix in config).
    Duplicates: ZID-dir, skip, or overwrite (from config).
    """
    if keep_lang_postfix is None:
        keep_lang_postfix = config_bool(config, "tts_settings", "keep_lang_postfix", False)

    stem = Path(srt_path).stem          # e.g., 'video.de'  (strip .srt)
    if keep_lang_postfix:
        base = stem
    else:
        clean_stem = strip_lang_postfix(stem, lang)   # e.g., 'video'
        base = clean_stem
    primary = Path(output_dir) / f"{base}.mp4"

    if not primary.exists():
        return primary, "new"

    dup_mode = config.get("tts_settings", "duplicate_mode", fallback="zid-dir").strip()

    if dup_mode == "overwrite":
        return primary, "overwrite"
    if dup_mode == "skip":
        return primary, "skip"

    # Default: zid-dir
    if not zid_cache.get("value"):
        zid_cache["value"] = get_zid(config)

    dup_dir = Path(output_dir) / zid_cache["value"]
    dup_dir.mkdir(parents=True, exist_ok=True)

    candidate = dup_dir / f"{base}.mp4"
    if not candidate.exists():
        return candidate, "zid-dir"

    idx = 2
    while True:
        c = dup_dir / f"{base}-{idx}.mp4"
        if not c.exists():
            return c, "zid-dir-indexed"
        idx += 1


# ==============================================================================
# PER-CUE TTS SYNTHESIS (tasks 4.1 – 4.4)
# ==============================================================================

def synthesize_cue(cue, lang, wav_path, piper_root):
    """
    Call piper_tts.py to synthesize a single subtitle cue to a WAV file.
    Returns True on success, False on error (non-fatal).
    """
    piper_script = piper_root / "piper_tts.py"

    cmd = [
        sys.executable,
        str(piper_script),
        "--lang", lang,
        "--text", cue["text"],
        "--output-file", str(wav_path),
    ]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=120,
        )
        if result.returncode != 0:
            if _IS_TTY:
                clear_line()
            log_warn(f"Piper failed for cue {cue['index']}: {result.stderr.strip()}")
            return False
        return True
    except subprocess.TimeoutExpired:
        if _IS_TTY:
            clear_line()
        log_warn(f"Piper timed out for cue {cue['index']}.")
        return False
    except Exception as exc:
        if _IS_TTY:
            clear_line()
        log_warn(f"Piper error for cue {cue['index']}: {exc}")
        return False


def synthesize_all_cues(cues, lang, temp_dir, piper_root):
    """
    Synthesize all cues. Returns a list of result dicts:
        {cue: dict, wav_path: Path | None, ok: bool}
    """
    total = len(cues)
    results = []
    last_pct = -10.0

    for i, cue in enumerate(cues, start=1):
        percent_val = (i / total) * 100.0 if total > 0 else 0.0
        label = f"Synthesizing cue {cue['index']}"
        detail = repr(cue['text'][:40])
        
        # Build progress bar string
        bar_line = make_cue_progress_bar(i, total, label, detail=detail)
        
        if _IS_TTY:
            clear_line()
            sys.stdout.write(bar_line)
            sys.stdout.flush()
        else:
            # Non-TTY throttling algorithm (delta-based)
            if i == 1 or i == total or (percent_val - last_pct >= 10.0):
                sys.stdout.write(bar_line.lstrip("\r") + "\n")
                sys.stdout.flush()
                last_pct = percent_val
        
        wav_name = f"cue_{cue['index']:05d}.wav"
        wav_path = temp_dir / wav_name
        ok = synthesize_cue(cue, lang, wav_path, piper_root)

        results.append({
            "cue": cue,
            "wav_path": wav_path if ok and wav_path.exists() else None,
            "ok": ok,
        })

    return results


# ==============================================================================
# WAV DURATION HELPER
# ==============================================================================

def get_wav_duration_ms(wav_path, ffmpeg_path):
    """Return duration in milliseconds of a WAV file using ffprobe/ffmpeg."""
    # Use ffmpeg's stderr output to parse duration
    try:
        cmd = [ffmpeg_path, "-i", str(wav_path), "-f", "null", "-"]
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=30
        )
        # Parse "Duration: HH:MM:SS.mmm" from stderr
        match = re.search(r"Duration:\s*(\d+):(\d+):(\d+)\.(\d+)", result.stderr)
        if match:
            h, m, s, cs = match.groups()
            return (int(h) * 3600 + int(m) * 60 + int(s)) * 1000 + int(cs) * 10
    except Exception:
        pass
    return 0


# ==============================================================================
# SPEED ADJUSTMENT (Subtitle Edit-style FixSpeed stage)
# ==============================================================================

def config_bool(config, section, key, default=False):
    """Read a boolean config value with a tolerant fallback."""
    try:
        return config.getboolean(section, key, fallback=default)
    except ValueError:
        return default


def config_float(config, section, key, default):
    """Read a float config value with a tolerant fallback."""
    try:
        return config.getfloat(section, key, fallback=default)
    except ValueError:
        return default


def calculate_speed_factor(duration_ms, target_ms, max_speed_factor):
    """
    Return the speed-up factor needed to fit duration_ms into target_ms.
    Values <= 1.0 mean no speed-up is needed.
    """
    if duration_ms <= 0 or target_ms <= 0:
        return 1.0
    factor = duration_ms / target_ms
    if factor <= 1.0:
        return 1.0
    return min(factor, max(1.0, max_speed_factor))


def ffmpeg_filter_exists(ffmpeg_path, filter_name):
    """Return True if the FFmpeg build reports a named filter."""
    cache_key = (str(ffmpeg_path), filter_name)
    if cache_key in _FFMPEG_FILTER_CACHE:
        return _FFMPEG_FILTER_CACHE[cache_key]
    try:
        result = subprocess.run(
            [ffmpeg_path, "-hide_banner", "-filters"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        exists = result.returncode == 0 and filter_name in result.stdout
    except Exception:
        exists = False
    _FFMPEG_FILTER_CACHE[cache_key] = exists
    return exists


def run_ffmpeg_audio_filter(ffmpeg_path, input_file, output_file, audio_filter, timeout=300):
    """Run FFmpeg with a single audio filter and return True on usable output."""
    cmd = [
        ffmpeg_path, "-y",
        "-i", str(input_file),
        "-af", audio_filter,
        str(output_file),
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        if result.returncode == 0 and Path(output_file).exists() and Path(output_file).stat().st_size > 0:
            return True
        return False
    except Exception:
        return False


def build_atempo_filter(speed_factor):
    """
    Build an atempo chain. Chaining keeps compatibility with FFmpeg builds that
    only accept 0.5..2.0 per atempo instance.
    """
    remaining = max(0.5, float(speed_factor))
    parts = []
    while remaining > 2.0:
        parts.append("atempo=2.000")
        remaining /= 2.0
    parts.append(f"atempo={remaining:.3f}")
    return ",".join(parts)


def change_audio_speed(input_file, output_file, speed_factor, ffmpeg_path, high_quality):
    """
    Speed up audio while preserving pitch. Prefer rubberband when requested and
    available, otherwise use atempo.
    """
    speed = max(0.5, min(float(speed_factor), 100.0))
    if high_quality and ffmpeg_filter_exists(ffmpeg_path, "rubberband"):
        rubberband = (
            f"rubberband=tempo={speed:.3f}:"
            "transients=smooth:engine=faster:window=short"
        )
        if run_ffmpeg_audio_filter(ffmpeg_path, input_file, output_file, rubberband):
            return True

    return run_ffmpeg_audio_filter(
        ffmpeg_path,
        input_file,
        output_file,
        build_atempo_filter(speed),
    )


def trim_silence_for_cue(cue_index, current_file, temp_dir, ffmpeg_path, vad_enabled, vad_max_silence):
    """Trim boundary silence and optionally compress internal silence."""
    trim_output = temp_dir / f"trim_{cue_index:05d}.wav"
    trim_filter = (
        "areverse,atrim=start=0.1,"
        "silenceremove=start_periods=1:start_silence=0.1:start_threshold=0.01,"
        "areverse,atrim=start=0.1,"
        "silenceremove=start_periods=1:start_silence=0.1:start_threshold=0.01"
    )
    if run_ffmpeg_audio_filter(ffmpeg_path, current_file, trim_output, trim_filter):
        current_file = trim_output

    if vad_enabled:
        vad_output = temp_dir / f"vad_{cue_index:05d}.wav"
        max_silence = max(0.01, vad_max_silence)
        vad_filter = (
            "silenceremove=stop_periods=-1:"
            f"stop_duration={max_silence:.2f}:stop_threshold=-40dB"
        )
        if run_ffmpeg_audio_filter(ffmpeg_path, current_file, vad_output, vad_filter):
            current_file = vad_output

    return current_file


def trim_cues_only(synthesis_results, temp_dir, ffmpeg_path, config):
    """
    Trim silence for cues without changing speed (used for the primary track in fit-to-recording mode).
    """
    vad_enabled = config_bool(config, "tts_settings", "vad_silence_compression", False)
    vad_max_silence = config_float(config, "tts_settings", "vad_max_silence_seconds", 0.15)

    print("  Trimming silence (no speed adjustment)...", flush=True)
    adjusted = []
    total = len(synthesis_results)
    last_pct = -10.0

    for index, item in enumerate(synthesis_results):
        cue = item["cue"]
        loop_pos = index + 1
        percent_val = (loop_pos / total) * 100.0 if total > 0 else 0.0
        
        skipped = not item["ok"] or not item["wav_path"]
        if skipped:
            label = f"Skipping cue {cue['index']} (synthesis failed)"
        else:
            label = f"Trimming silence for cue {cue['index']}"
        
        # Build progress bar string
        bar_line = make_cue_progress_bar(loop_pos, total, label)
        
        if _IS_TTY:
            clear_line()
            sys.stdout.write(bar_line)
            sys.stdout.flush()
        else:
            # Non-TTY throttling (delta-based)
            if loop_pos == 1 or loop_pos == total or (percent_val - last_pct >= 10.0):
                sys.stdout.write(bar_line.lstrip("\r") + "\n")
                sys.stdout.flush()
                last_pct = percent_val

        if skipped:
            adjusted.append(item)
            continue

        current_file = Path(item["wav_path"])
        current_file = trim_silence_for_cue(cue["index"], current_file, temp_dir, ffmpeg_path, vad_enabled, vad_max_silence)

        adjusted_item = dict(item)
        adjusted_item["wav_path"] = current_file
        adjusted_item["speed_factor"] = 1.0
        adjusted_item["speed_limited"] = False
        adjusted_item["target_ms"] = cue["end_ms"] - cue["start_ms"]
        adjusted_item["fit_duration_ms"] = get_wav_duration_ms(current_file, ffmpeg_path)
        adjusted.append(adjusted_item)

    if _IS_TTY:
        clear_line()
    return adjusted


def adjust_speed_for_cues(synthesis_results, temp_dir, ffmpeg_path, config):
    """
    Port of Subtitle Edit's FixSpeed stage:
      1. Trim leading/trailing silence.
      2. Optionally compress internal silence.
      3. Speed up only cues that still exceed their subtitle window.
    """
    vad_enabled = config_bool(config, "tts_settings", "vad_silence_compression", False)
    vad_max_silence = config_float(config, "tts_settings", "vad_max_silence_seconds", 0.15)
    high_quality = config_bool(config, "tts_settings", "high_quality_time_stretch", False)
    max_gap_ms = int(config_float(config, "tts_settings", "max_extra_gap_ms", 1000.0))
    max_speed_factor = config_float(config, "tts_settings", "max_speed_factor", 2.0)

    print("  Adjusting speed to fit subtitle timing...", flush=True)
    adjusted = []
    total = len(synthesis_results)
    last_pct = -10.0

    for index, item in enumerate(synthesis_results):
        cue = item["cue"]
        loop_pos = index + 1
        percent_val = (loop_pos / total) * 100.0 if total > 0 else 0.0
        
        skipped = not item["ok"] or not item["wav_path"]
        if skipped:
            label = f"Skipping cue {cue['index']} (synthesis failed)"
        else:
            label = f"Adjusting speed for cue {cue['index']}"
        
        # Build progress bar string
        bar_line = make_cue_progress_bar(loop_pos, total, label)
        
        if _IS_TTY:
            clear_line()
            sys.stdout.write(bar_line)
            sys.stdout.flush()
        else:
            # Non-TTY throttling (delta-based)
            if loop_pos == 1 or loop_pos == total or (percent_val - last_pct >= 10.0):
                sys.stdout.write(bar_line.lstrip("\r") + "\n")
                sys.stdout.flush()
                last_pct = percent_val

        if skipped:
            adjusted.append(item)
            continue

        current_file = Path(item["wav_path"])

        current_file = trim_silence_for_cue(cue["index"], current_file, temp_dir, ffmpeg_path, vad_enabled, vad_max_silence)

        add_duration_ms = 0
        if index + 1 < total:
            next_cue = synthesis_results[index + 1]["cue"]
            if cue["end_ms"] < next_cue["start_ms"]:
                add_duration_ms = min(max_gap_ms, next_cue["start_ms"] - cue["end_ms"])

        target_ms = max(1, cue["end_ms"] - cue["start_ms"] + add_duration_ms)
        duration_ms = get_wav_duration_ms(current_file, ffmpeg_path)
        speed_factor = calculate_speed_factor(duration_ms, target_ms, max_speed_factor)

        speed_limited = duration_ms > 0 and target_ms > 0 and duration_ms / target_ms > max_speed_factor
        if speed_factor > 1.0:
            speed_output = temp_dir / f"speed_{cue['index']:05d}.wav"
            if change_audio_speed(current_file, speed_output, speed_factor, ffmpeg_path, high_quality):
                current_file = speed_output
            else:
                if _IS_TTY:
                    clear_line()
                print(f"  [WARN] Speed adjustment failed for cue {cue['index']}; using trimmed audio.", file=sys.stderr)

        adjusted_item = dict(item)
        adjusted_item["wav_path"] = current_file
        adjusted_item["speed_factor"] = speed_factor
        adjusted_item["speed_limited"] = speed_limited
        adjusted_item["target_ms"] = target_ms
        adjusted_item["fit_duration_ms"] = get_wav_duration_ms(current_file, ffmpeg_path)
        adjusted.append(adjusted_item)

    if _IS_TTY:
        clear_line()
    speedups = [r.get("speed_factor", 1.0) for r in adjusted if r.get("speed_factor", 1.0) > 1.0]
    limited = sum(1 for r in adjusted if r.get("speed_limited"))
    if speedups:
        print(
            f"  Speed adjustment: {len(speedups)} cue(s) sped up; "
            f"max factor {max(speedups):.2f}x; limited cues {limited}.",
            flush=True,
        )

    return adjusted


class ShiftPlan(list):
    """List of cue shifts with duration cache metadata for assembly."""

    def __init__(self, shifts=(), wav_durations_ms=None):
        super().__init__(shifts)
        self.wav_durations_ms = wav_durations_ms or {}
        self.explicit_ends_ms = {}
        self.explicit_targets_ms = {}


def plan_recording_timeline(synthesis_results, ffmpeg_path):
    """
    Build a canonical timeline derived from the primary track's recording durations.
    Returns a ShiftPlan with explicit end times and target durations.

    Cues are packed back-to-back with no forced inter-cue gap (mirroring
    plan_subtitle_shifts): a cue's audio may fill the entire natural gap before
    the next cue, and later cues are shifted forward only by the residual overlap.
    """
    if not synthesis_results:
        return ShiftPlan()

    original_starts = [item["cue"]["start_ms"] for item in synthesis_results]
    durations = []
    duration_cache = {}
    
    for idx, item in enumerate(synthesis_results):
        cue = item["cue"]
        if item["ok"] and item["wav_path"]:
            wav_dur_ms = item.get("fit_duration_ms")
            if not wav_dur_ms:
                wav_dur_ms = get_wav_duration_ms(item["wav_path"], ffmpeg_path)
            if wav_dur_ms <= 0:
                wav_dur_ms = cue["end_ms"] - cue["start_ms"]
            duration_cache[idx] = wav_dur_ms
        else:
            wav_dur_ms = cue["end_ms"] - cue["start_ms"]
            duration_cache[idx] = wav_dur_ms
        durations.append(wav_dur_ms)

    drift = 0
    shifts = []
    explicit_ends_ms = {}
    explicit_targets_ms = {}
    count = len(synthesis_results)
    
    for idx in range(count):
        shifts.append(drift)
        shifted_start = original_starts[idx] + drift
        audio_dur = durations[idx]
        explicit_ends_ms[idx] = shifted_start + audio_dur
        explicit_targets_ms[idx] = audio_dur
        
        if idx + 1 < count:
            next_original_start = original_starts[idx + 1]
            next_shifted_start = next_original_start + drift
            audio_end = explicit_ends_ms[idx]
            gap_required = audio_end - next_shifted_start
            if gap_required > 0:
                drift += gap_required

    plan = ShiftPlan(shifts, duration_cache)
    plan.explicit_ends_ms = explicit_ends_ms
    plan.explicit_targets_ms = explicit_targets_ms
    return plan


def plan_subtitle_shifts(synthesis_results, ffmpeg_path):
    """
    Build a cumulative drift plan by cue position.
    Returns a list[int] where each entry is the total drift (ms) for cue position.
    """
    if not synthesis_results:
        return ShiftPlan()

    original_starts = [item["cue"]["start_ms"] for item in synthesis_results]
    durations = []
    duration_cache = {}
    for idx, item in enumerate(synthesis_results):
        cue = item["cue"]
        if item["ok"] and item["wav_path"]:
            wav_dur_ms = get_wav_duration_ms(item["wav_path"], ffmpeg_path)
            if wav_dur_ms <= 0:
                wav_dur_ms = cue["end_ms"] - cue["start_ms"]
            duration_cache[idx] = wav_dur_ms
        else:
            wav_dur_ms = 0
        durations.append(wav_dur_ms)

    drift = 0
    shifts = []
    count = len(synthesis_results)
    for idx in range(count):
        shifts.append(drift)
        shifted_start = original_starts[idx] + drift
        audio_end = shifted_start + durations[idx]
        if idx + 1 < count:
            next_shifted_start = original_starts[idx + 1] + drift
            gap_required = audio_end - next_shifted_start
            if gap_required > 0:
                drift += gap_required

    return ShiftPlan(shifts, duration_cache)


def apply_shift_plan(synthesis_results, shift_plan, propagate_duration_cache=True):
    """
    Return a new synthesis result list with shifted cue timing copies.
    Shift entries apply by cue position.
    """
    shifted_results = []
    duration_cache = getattr(shift_plan, "wav_durations_ms", {}) if propagate_duration_cache else {}
    explicit_ends_ms = getattr(shift_plan, "explicit_ends_ms", {})

    for idx, item in enumerate(synthesis_results):
        new_item = dict(item)
        cue = item.get("cue")
        if cue is None:
            shifted_results.append(new_item)
            continue

        new_cue = dict(cue)
        if idx < len(shift_plan):
            drift = shift_plan[idx]
            new_cue["start_ms"] = cue["start_ms"] + drift
            if idx in explicit_ends_ms:
                new_cue["end_ms"] = explicit_ends_ms[idx]
            else:
                new_cue["end_ms"] = cue["end_ms"] + drift
        if idx in duration_cache:
            new_item["wav_duration_ms_cached"] = duration_cache[idx]

        new_item["cue"] = new_cue
        shifted_results.append(new_item)

    return shifted_results


def speed_fit_to_slots(synthesis_results, shift_plan, temp_dir, ffmpeg_path, config):
    """
    Speed-fit secondary cues to canonical slot durations defined by the primary track.
    """
    high_quality = config_bool(config, "tts_settings", "high_quality_time_stretch", False)
    max_speed_factor = config_float(config, "tts_settings", "max_speed_factor", 2.0)
    explicit_targets_ms = getattr(shift_plan, "explicit_targets_ms", {})

    print("  Speed-fitting secondary cues to canonical slots...", flush=True)
    adjusted = []
    
    for idx, item in enumerate(synthesis_results):
        if not item["ok"] or not item["wav_path"] or idx not in explicit_targets_ms:
            adjusted.append(item)
            continue
            
        cue = item["cue"]
        current_file = Path(item["wav_path"])
        target_ms = explicit_targets_ms[idx]
        duration_ms = item.get("fit_duration_ms")
        if not duration_ms:
            duration_ms = get_wav_duration_ms(current_file, ffmpeg_path)
        
        speed_factor = calculate_speed_factor(duration_ms, target_ms, max_speed_factor)
        speed_limited = duration_ms > 0 and target_ms > 0 and duration_ms / target_ms > max_speed_factor
        
        if speed_factor > 1.0:
            speed_output = temp_dir / f"speed_sec_{cue['index']:05d}.wav"
            if change_audio_speed(current_file, speed_output, speed_factor, ffmpeg_path, high_quality):
                current_file = speed_output
            else:
                if _IS_TTY: clear_line()
                print(f"  [WARN] Speed adjustment failed for secondary cue {cue['index']}.", file=sys.stderr)

        new_item = dict(item)
        new_item["wav_path"] = current_file
        new_item["speed_factor"] = speed_factor
        new_item["speed_limited"] = speed_limited
        new_item["target_ms"] = target_ms
        new_item["fit_duration_ms"] = get_wav_duration_ms(current_file, ffmpeg_path)
        adjusted.append(new_item)
        
    return adjusted


# ==============================================================================
# TIMED AUDIO ASSEMBLY (tasks 5.1 – 5.4)
# ==============================================================================

def build_audio_placement_plan(synthesis_results, ffmpeg_path):
    """
    Build the pure timing plan used by assemble_audio().

    Each successful cue is anchored to its SRT start timestamp. The overflow
    fields are diagnostic: they reveal where synthesized speech runs past the
    next subtitle start, which is the core source of perceived subtitle/audio
    desync if playback expects non-overlapping narration.
    """
    valid_cues = []
    for item in synthesis_results:
        if not item["ok"] or not item["wav_path"]:
            continue
        cue = item["cue"]
        wav_dur_ms = item.get("wav_duration_ms_cached")
        if wav_dur_ms is None:
            wav_dur_ms = get_wav_duration_ms(item["wav_path"], ffmpeg_path)
        if wav_dur_ms <= 0:
            wav_dur_ms = cue["end_ms"] - cue["start_ms"]

        valid_cues.append({
            "path": item["wav_path"],
            "start_ms": cue["start_ms"],
            "end_ms": cue["end_ms"],
            "dur_ms": wav_dur_ms,
            "audio_end_ms": cue["start_ms"] + wav_dur_ms,
            "overflow_ms": 0,
        })

    for idx, cue_info in enumerate(valid_cues[:-1]):
        next_start = valid_cues[idx + 1]["start_ms"]
        cue_info["next_start_ms"] = next_start
        cue_info["overflow_ms"] = max(0, cue_info["audio_end_ms"] - next_start)
    if valid_cues:
        valid_cues[-1]["next_start_ms"] = None

    max_end_ms = 0
    for cue_info in valid_cues:
        max_end_ms = max(max_end_ms, cue_info["audio_end_ms"], cue_info["end_ms"])

    return valid_cues, max_end_ms


def assemble_audio(synthesis_results, temp_dir, ffmpeg_path):
    """
    Assemble all per-cue WAVs into one combined WAV by placing each at its
    exact SRT start time. Uses FFmpeg's adelay and amix filters.
    Processes in batches to avoid command-line length limits.
    """
    valid_cues, max_end_ms = build_audio_placement_plan(synthesis_results, ffmpeg_path)

    if not valid_cues:
        log_error("No audio segments to assemble.")
        return None

    log_info("Assembling timed audio track (anchored to absolute timestamps)...")
    overflow_count = sum(1 for cue_info in valid_cues if cue_info["overflow_ms"] > 0)
    if overflow_count:
        worst = max(cue_info["overflow_ms"] for cue_info in valid_cues)
        log_warn(
            f"{overflow_count} synthesized cue(s) exceed the next subtitle start; "
            f"largest overflow is {worst / 1000.0:.2f}s."
        )

    base_wav = temp_dir / "base_0.wav"
    # Create an initial silent base track of the total required duration
    cmd_base = [
        ffmpeg_path, "-y",
        "-f", "lavfi",
        "-i", "anullsrc=r=22050:cl=mono",
        "-t", f"{max_end_ms / 1000.0:.3f}",
        "-c:a", "pcm_s16le",
        str(base_wav)
    ]
    try:
        subprocess.run(cmd_base, capture_output=True, check=True)
    except Exception as exc:
        log_error(f"FFmpeg base track generation failed: {exc}")
        return None

    batch_size = 64
    current_base = base_wav

    for batch_idx, i in enumerate(range(0, len(valid_cues), batch_size)):
        batch = valid_cues[i:i + batch_size]
        next_base = temp_dir / f"base_{batch_idx + 1}.wav"
        script_path = temp_dir / f"filter_{batch_idx}.txt"

        cmd = [ffmpeg_path, "-y", "-i", str(current_base)]
        filter_lines = []
        amix_inputs = ["[0:a]"]

        for j, cue_info in enumerate(batch, start=1):
            cmd.extend(["-i", str(cue_info["path"])])
            delay = cue_info["start_ms"]
            # Delay in ms for all channels
            filter_lines.append(f"[{j}:a]adelay={delay}|{delay}[a{j}];")
            amix_inputs.append(f"[a{j}]")

        amix_str = "".join(amix_inputs)
        num_inputs = len(batch) + 1
        # duration=first keeps the length locked to the base track length
        # normalize=0 prevents volume dropping when multiple streams mix
        filter_lines.append(f"{amix_str}amix=inputs={num_inputs}:duration=first:dropout_transition=0:normalize=0[aout]")

        with open(script_path, "w", encoding="utf-8") as f:
            f.write("\n".join(filter_lines))

        cmd.extend([
            "-filter_complex_script", str(script_path),
            "-map", "[aout]",
            "-c:a", "pcm_s16le",
            str(next_base)
        ])

        try:
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
            if res.returncode != 0:
                log_error(f"FFmpeg audio batch {batch_idx} failed:\n{res.stderr}")
                return None
        except Exception as exc:
            log_error(f"FFmpeg audio batch {batch_idx} exception: {exc}")
            return None

        current_base = next_base

    final_wav = temp_dir / "assembled.wav"
    import shutil
    shutil.move(current_base, final_wav)
    return final_wav


# ==============================================================================
# MP4 MUXING (task 6.1)
# ==============================================================================

def mux_to_mp4(assembled_wav, output_mp4, ffmpeg_path):
    """
    Mux assembled_wav with a black canvas to produce the final MP4.
    Uses the same encoding parameters as convert_media.py.
    """
    cmd = [
        ffmpeg_path, "-y",
        "-i", str(assembled_wav),
        "-f", "lavfi",
        "-i", DEFAULT_VIDEO_FILTER,
        "-shortest",
        "-c:v", DEFAULT_VIDEO_CODEC,
        "-preset", DEFAULT_VIDEO_PRESET,
        "-crf", DEFAULT_VIDEO_CRF,
        "-tune", DEFAULT_VIDEO_TUNE,
        "-x264-params", DEFAULT_VIDEO_X264_PARAMS,
        "-r", DEFAULT_VIDEO_FPS,
        "-pix_fmt", DEFAULT_PIXEL_FORMAT,
        "-c:a", DEFAULT_AUDIO_CODEC,
        "-b:a", DEFAULT_AUDIO_BITRATE,
        "-movflags", DEFAULT_MOVFLAGS,
        str(output_mp4),
    ]

    log_info(f"Muxing to MP4: {_dim(str(output_mp4))}")
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=1800)
        if result.returncode != 0:
            log_error(f"FFmpeg MP4 muxing failed:\n{result.stderr}")
            return False
        return True
    except Exception as exc:
        log_error(f"FFmpeg muxing exception: {exc}")
        return False


# ==============================================================================
# CLEANUP (tasks 7.1 – 7.2)
# ==============================================================================

def cleanup_temp_dir(temp_dir, success):
    """
    Remove the temporary directory on success.
    On failure, preserve it and print a diagnostic.
    """
    if success:
        try:
            shutil.rmtree(temp_dir, ignore_errors=True)
        except Exception:
            pass
    else:
        log_info(f"Temporary files preserved for debugging: '{temp_dir}'")


# ==============================================================================
# FFMPEG PATH RESOLUTION (task 7.3)
# ==============================================================================

def resolve_ffmpeg(config, cli_override=None):
    """Resolve FFmpeg path: CLI override → config → PATH."""
    if cli_override:
        p = Path(cli_override)
        if p.exists():
            return str(p)
        raise FileNotFoundError(f"ffmpeg not found at CLI-specified path: '{cli_override}'")

    config_path = config.get("paths", "ffmpeg_executable", fallback="").strip()
    if config_path:
        p = Path(config_path)
        if p.exists():
            return str(p)

    discovered = shutil.which("ffmpeg")
    if discovered:
        return discovered

    raise FileNotFoundError(
        "ffmpeg was not found. Install ffmpeg, add it to PATH, "
        "or set ffmpeg_executable in config.ini."
    )


# ==============================================================================
# SINGLE-FILE PIPELINE
# ==============================================================================

def process_srt(srt_path, config, piper_config, piper_root, ffmpeg_path,
                lang_override=None, output_dir_override=None, zid_cache=None,
                keep_lang_postfix_override=None, timeline_source_override=None,
                shift_subtitles_on_overflow_override=None,
                canonical_shift_plan=None, canonical_filename=None):
    """
    Full pipeline for a single SRT file:
      1. Detect language
      2. Parse SRT
      3. Synthesize per-cue WAVs
      4. Assemble timed audio
      5. Mux to MP4
      6. Cleanup

    Returns (success, shift_plan).
    """
    if zid_cache is None:
        zid_cache = {}

    srt_path = Path(srt_path).resolve()
    log_section(f"Processing: {_bold(srt_path.name)}")

    # 1. Language detection
    if lang_override:
        lang = lang_override.strip().lower()
        log_detail(f"Language: {_cyan(lang)} (CLI override)")
    else:
        lang = detect_language(str(srt_path), config)
        log_detail(f"Language detected: {_cyan(lang)} (from filename postfix)")

    supported = get_supported_languages(piper_config)
    validate_language(lang, piper_config, supported)

    section = f"voice_{lang}"
    model_file = piper_config.get(section, "model", fallback="(unknown)")
    log_detail(f"Piper model: {_dim(model_file)}")

    # 2. Parse SRT
    log_info("Parsing SRT...")
    try:
        cues = parse_srt(str(srt_path))
    except Exception as exc:
        log_error(f"Error parsing SRT file: {exc}")
        return False, None

    if not cues:
        log_error("No valid subtitle cues found in the SRT file.")
        return False, None

    log_detail(f"Found {_bold(str(len(cues)))} cues to synthesize.")

    # 3. Temporary directory
    output_dir = Path(output_dir_override) if output_dir_override else srt_path.parent
    output_dir.mkdir(parents=True, exist_ok=True)
    temp_dir = Path(tempfile.mkdtemp(prefix="sub_tts_", dir=output_dir))
    log_detail(f"Temp dir: {_dim(str(temp_dir))}")

    success = False
    try:
        # 4. Per-cue synthesis
        log_section("TTS SYNTHESIS")
        synthesis_results = synthesize_all_cues(cues, lang, temp_dir, piper_root)
        successful = sum(1 for r in synthesis_results if r["ok"])
        if _IS_TTY:
            clear_line()
        if successful == len(cues):
            log_ok(f"Synthesis complete: {successful}/{len(cues)} cues.")
        else:
            log_warn(f"Synthesis complete: {successful}/{len(cues)} cues.")

        if successful == 0:
            log_error("All cue synthesis attempts failed. Check Piper TTS setup.")
            return False, None

        # 5. Timeline building and speed fitting
        timeline_source = timeline_source_override
        if timeline_source is None:
            timeline_source = config.get("tts_settings", "timeline_source", fallback="primary_subtitle").strip().lower()
        if timeline_source not in ("primary_subtitle", "primary_audio"):
            log_warn(f"Unknown timeline_source '{timeline_source}' in config.ini. Falling back to 'primary_subtitle'.")
            timeline_source = "primary_subtitle"

        produced_shift_plan = None

        if timeline_source == "primary_audio":
            if canonical_shift_plan is None:
                # Primary track: derive timeline
                synthesis_results = trim_cues_only(synthesis_results, temp_dir, ffmpeg_path, config)
                produced_shift_plan = plan_recording_timeline(synthesis_results, ffmpeg_path)
                synthesis_results = apply_shift_plan(synthesis_results, produced_shift_plan)
                shifted_count = sum(1 for drift in produced_shift_plan if drift > 0)
                total_drift_ms = max(produced_shift_plan) if produced_shift_plan else 0
                log_info(
                    f"Built recording-derived timeline: {shifted_count} cue(s) shifted, total drift {total_drift_ms / 1000.0:.2f}s"
                )
            else:
                # Secondary track: map to canonical slots
                synthesis_results = trim_cues_only(synthesis_results, temp_dir, ffmpeg_path, config)
                synthesis_results = apply_shift_plan(synthesis_results, canonical_shift_plan, propagate_duration_cache=False)
                if getattr(canonical_shift_plan, "explicit_targets_ms", None):
                    synthesis_results = speed_fit_to_slots(synthesis_results, canonical_shift_plan, temp_dir, ffmpeg_path, config)
                if canonical_filename:
                    log_info(f"Applying canonical recording timeline from {canonical_filename}")
                local_cue_count = len(synthesis_results)
                if local_cue_count != len(canonical_shift_plan):
                    log_warn(
                        f"{srt_path.name}: cue count {local_cue_count} differs from canonical {len(canonical_shift_plan)}; shifting overlap only"
                    )
        else:
            # primary_subtitle mode (default legacy behavior)
            synthesis_results = adjust_speed_for_cues(synthesis_results, temp_dir, ffmpeg_path, config)

            shift_subtitles_on_overflow = shift_subtitles_on_overflow_override
            if shift_subtitles_on_overflow is None:
                shift_subtitles_on_overflow = config_bool(config, "tts_settings", "shift_subtitles_on_overflow", False)

            if shift_subtitles_on_overflow:
                if canonical_shift_plan is None:
                    produced_shift_plan = plan_subtitle_shifts(synthesis_results, ffmpeg_path)
                    synthesis_results = apply_shift_plan(synthesis_results, produced_shift_plan)
                    shifted_count = sum(1 for drift in produced_shift_plan if drift > 0)
                    total_drift_ms = max(produced_shift_plan) if produced_shift_plan else 0
                    log_info(
                        f"Fitting subtitles to audio: {shifted_count} cue(s) shifted, total drift {total_drift_ms / 1000.0:.2f}s"
                    )
                else:
                    synthesis_results = apply_shift_plan(synthesis_results, canonical_shift_plan, propagate_duration_cache=False)
                    if canonical_filename:
                        log_info(f"Applying canonical shift plan from {canonical_filename}")
                    local_cue_count = len(synthesis_results)
                    if local_cue_count != len(canonical_shift_plan):
                        log_warn(
                            f"{srt_path.name}: cue count {local_cue_count} differs from canonical {len(canonical_shift_plan)}; shifting overlap only"
                        )

        # 6. Assemble timed audio
        log_section("AUDIO ASSEMBLY")
        assembled_wav = assemble_audio(synthesis_results, temp_dir, ffmpeg_path)
        if assembled_wav is None:
            return False, None

        # 7. Output path
        output_mp4, policy = resolve_output_path(
            str(srt_path),
            output_dir,
            config,
            lang,
            zid_cache,
            keep_lang_postfix=keep_lang_postfix_override,
        )
        if policy == "skip":
            log_skip(f"Output already exists: {output_mp4}")
            success = True
            return True, produced_shift_plan

        output_mp4.parent.mkdir(parents=True, exist_ok=True)

        # 8. Mux to MP4
        log_section("MP4 MUXING")
        ok = mux_to_mp4(assembled_wav, output_mp4, ffmpeg_path)
        if ok:
            log_ok(f"Output: {_cyan(str(output_mp4))}")
            success = True
        return ok, produced_shift_plan

    finally:
        cleanup_temp_dir(temp_dir, success)


def pause_console(success=True, timeout_secs=PAUSE_AUTO_CLOSE_TIMEOUT_SECS):
    """Pauses the console window.
    If success is True and timeout_secs is provided, shows a premium countdown to auto-close.
    If success is False or timeout_secs is None, pauses indefinitely so the user can inspect errors.
    """
    if not success or timeout_secs is None or timeout_secs == "":
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

def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Kardenwort Sub TTS Pipeline — Convert SRT subtitle files to MP4 "
            "with synthesized Piper TTS speech audio.\n\n"
            "Language is auto-detected from the filename postfix (e.g., .de.srt → German)."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "srt_files",
        nargs="*",
        metavar="FILE",
        help="One or more .srt subtitle files to process.",
    )
    parser.add_argument(
        "--lang",
        type=str,
        default=None,
        help="Override language detection. Must match a Piper TTS supported language code (e.g., de, ru, en).",
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default=None,
        help="Override output directory. Default: same directory as the input SRT file.",
    )
    parser.add_argument(
        "--ffmpeg-path",
        type=str,
        default=None,
        help="Override FFmpeg executable path.",
    )
    parser.add_argument(
        "--keep-lang-postfix",
        action="store_true",
        default=None,
        help="Keep the language postfix in the output MP4 filename.",
    )
    parser.add_argument(
        "--no-keep-lang-postfix",
        action="store_false",
        dest="keep_lang_postfix",
        help="Strip the language postfix from the output MP4 filename (overrides config).",
    )
    parser.add_argument(
        "--timeline-source",
        choices=["primary_subtitle", "primary_audio"],
        default=None,
        help="Source of truth for the timeline: 'primary_subtitle' (audio speeds up to fit) or 'primary_audio' (timeline rebuilt around primary track's native audio).",
    )
    parser.add_argument(
        "--shift-subtitles-on-overflow",
        action="store_true",
        default=None,
        help="When timeline-source is primary_subtitle: shift subtitle timings later to avoid overlap when audio overflows.",
    )
    parser.add_argument(
        "--no-shift-subtitles-on-overflow",
        action="store_false",
        dest="shift_subtitles_on_overflow",
        help="Do not shift subtitle timings on overflow (overrides config).",
    )
    parser.add_argument(
        "--sendto",
        action="store_true",
        help="Windows SendTo mode: treat all positional arguments as selected files.",
    )
    parser.add_argument(
        "--pause",
        action="store_true",
        help="Pause and wait for Enter key after processing (useful when launched from SendTo so the window stays open).",
    )

    return parser.parse_args()


def main():
    start_time = time.time()
    args = parse_args()
    config = load_config()
    print(f"\n{_bold('Kardenwort Sub TTS Pipeline')} {_dim(f'(ZID: {get_zid(config)})')}\n", flush=True)

    # Collect input files
    input_files = args.srt_files

    if not input_files:
        log_error(
            "No SRT files provided.\n"
            "Usage: python sub_tts.py video.de.srt [video2.ru.srt ...]\n"
            "   or: python sub_tts.py --sendto <file1> <file2>  (SendTo mode)"
        )
        if args.pause:
            pause_console(success=False)
        sys.exit(1)

    # Filter to .srt files only
    srt_files = [f for f in input_files if f.lower().endswith(".srt")]
    skipped = [f for f in input_files if not f.lower().endswith(".srt")]
    for s in skipped:
        log_skip(f"Not an SRT file: {s}")

    if not srt_files:
        log_error("No valid .srt files were provided.")
        if args.pause:
            pause_console(success=False)
        sys.exit(1)

    # Resolve FFmpeg
    try:
        ffmpeg_path = resolve_ffmpeg(config, cli_override=args.ffmpeg_path)
    except FileNotFoundError as exc:
        log_error(str(exc))
        if args.pause:
            pause_console(success=False)
        sys.exit(1)

    # Load Piper TTS config
    piper_config, piper_root = get_piper_config(config)

    # Process each file
    zid_cache = {}
    results = []
    shift_plan = None
    canonical_filename = None

    # Effective recording mode: its canonical timeline must persist across files.
    timeline_source = args.timeline_source
    if timeline_source is None:
        timeline_source = config.get("tts_settings", "timeline_source", fallback="primary_subtitle").strip().lower()
    if timeline_source not in ("primary_subtitle", "primary_audio"):
        log_warn(f"Unknown timeline_source '{timeline_source}' in config.ini. Falling back to 'primary_subtitle'.")
        timeline_source = "primary_subtitle"

    for srt_path in srt_files:
        ok, generated_shift_plan = process_srt(
            srt_path,
            config=config,
            piper_config=piper_config,
            piper_root=piper_root,
            ffmpeg_path=ffmpeg_path,
            lang_override=args.lang,
            output_dir_override=args.output_dir,
            zid_cache=zid_cache,
            keep_lang_postfix_override=args.keep_lang_postfix,
            timeline_source_override=args.timeline_source,
            shift_subtitles_on_overflow_override=args.shift_subtitles_on_overflow,
            canonical_shift_plan=shift_plan,
            canonical_filename=canonical_filename,
        )
        results.append((srt_path, ok))
        if shift_plan is None and generated_shift_plan is not None and ok:
            shift_plan = generated_shift_plan
            canonical_filename = Path(srt_path).name
        if args.shift_subtitles_on_overflow is False and timeline_source != "primary_audio":
            shift_plan = None
            canonical_filename = None

    # Summary
    elapsed = time.time() - start_time
    succeeded = sum(1 for _, ok in results if ok)
    total = len(results)

    print(flush=True)
    if succeeded == total:
        log_ok(f"All {succeeded}/{total} file(s) converted in {elapsed:.1f}s.")
    else:
        log_warn(f"Converted {succeeded}/{total} file(s) in {elapsed:.1f}s.")
        for path, ok in results:
            if not ok:
                log_error(f"Failed: {path}")

    if args.pause:
        timeout_val = config.get("tts_settings", "auto_close_timeout_secs", fallback="").strip()
        if not timeout_val:
            timeout = None
        else:
            try:
                timeout = int(timeout_val)
            except Exception:
                timeout = PAUSE_AUTO_CLOSE_TIMEOUT_SECS
        pause_console(success=(succeeded == total), timeout_secs=timeout)

    sys.exit(0 if succeeded == total else 1)


if __name__ == "__main__":
    main()
