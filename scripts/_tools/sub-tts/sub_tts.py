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
import os
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

SHORTCUT_DISPLAY_NAME = "Kardenwort Sub TTS"

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


def resolve_output_path(srt_path, output_dir, config, lang, zid_cache):
    """
    Build the output .mp4 path.
    Policy: base filename WITHOUT language postfix + .mp4, in output_dir.
    Duplicates: ZID-dir, skip, or overwrite (from config).
    """
    stem = Path(srt_path).stem          # e.g., 'video.de'  (strip .srt)
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

def synthesize_cue(cue, lang, wav_path, piper_root, total, current):
    """
    Call piper_tts.py to synthesize a single subtitle cue to a WAV file.
    Returns True on success, False on error (non-fatal).
    """
    piper_script = piper_root / "piper_tts.py"
    print(f"  [{current}/{total}] Synthesizing cue {cue['index']}: \"{cue['text'][:60]}\"", flush=True)

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
            print(
                f"  [WARN] Piper failed for cue {cue['index']}:\n"
                f"    {result.stderr.strip()}",
                file=sys.stderr,
            )
            return False
        return True
    except subprocess.TimeoutExpired:
        print(f"  [WARN] Piper timed out for cue {cue['index']}.", file=sys.stderr)
        return False
    except Exception as exc:
        print(f"  [WARN] Piper error for cue {cue['index']}: {exc}", file=sys.stderr)
        return False


def synthesize_all_cues(cues, lang, temp_dir, piper_root):
    """
    Synthesize all cues. Returns a list of result dicts:
        {cue: dict, wav_path: Path | None, ok: bool}
    """
    total = len(cues)
    results = []

    for i, cue in enumerate(cues, start=1):
        wav_name = f"cue_{cue['index']:05d}.wav"
        wav_path = temp_dir / wav_name
        ok = synthesize_cue(cue, lang, wav_path, piper_root, total, i)

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
# TIMED AUDIO ASSEMBLY (tasks 5.1 – 5.4)
# ==============================================================================

def build_ffmpeg_concat_list(synthesis_results, temp_dir, ffmpeg_path):
    """
    Build an FFmpeg concat file-list that interleaves per-cue WAVs with
    silence pads to match original SRT timing.

    Returns path to the concat list file, or None if no cues were synthesized.

    Strategy:
      - Track 'cursor_ms': where the audio stream is currently positioned.
      - For each cue with a synthesized WAV:
          1. If cue.start_ms > cursor_ms → insert a silence segment.
          2. Append the cue WAV.
          3. Advance cursor_ms by the WAV's actual duration.
    """
    silence_wav = temp_dir / "silence.wav"
    concat_list_path = temp_dir / "concat.txt"

    # ------------------------------------------------------------------
    # Strategy: anchor EVERY cue at its exact SRT start_ms.
    # cursor_ms tracks where the audio stream currently is.
    # If cue_start_ms > cursor_ms → insert silence to reach it.
    # If the previous cue's WAV overlapped (cursor_ms > cue_start_ms)
    # → we still insert 0 ms of silence (no gap) but do NOT skip the
    #   cue; the result is cues played back-to-back.  This is better
    #   than the old behaviour which pushed ALL subsequent cues forward.
    # ------------------------------------------------------------------
    segments = []  # list of ("silence", ms) | ("wav", path)

    cursor_ms = 0

    for item in synthesis_results:
        cue = item["cue"]
        wav_path = item["wav_path"]

        if wav_path is None:
            # Failed cue: advance cursor to its end_ms so we stay aligned
            cursor_ms = max(cursor_ms, cue["end_ms"])
            continue

        cue_start_ms = cue["start_ms"]

        # Gap before this cue (may be 0 if previous WAV ran long)
        gap_ms = max(0, cue_start_ms - cursor_ms)
        if gap_ms > 0:
            segments.append(("silence", gap_ms))

        # Actual duration of the synthesized WAV
        wav_dur_ms = get_wav_duration_ms(wav_path, ffmpeg_path)
        if wav_dur_ms <= 0:
            wav_dur_ms = cue["end_ms"] - cue["start_ms"]  # SRT window as fallback

        segments.append(("wav", str(wav_path)))
        # Advance cursor to cue_start_ms + WAV duration (not cursor_ms + WAV duration)
        cursor_ms = cue_start_ms + wav_dur_ms

    if not segments:
        return None

    # Generate individual silence WAVs per required duration
    concat_entries = []
    silence_index = 0

    for seg in segments:
        if seg[0] == "silence":
            dur_ms = seg[1]
            if dur_ms <= 0:
                continue
            dur_s = dur_ms / 1000.0
            sil_path = temp_dir / f"silence_{silence_index:04d}.wav"
            sil_cmd = [
                ffmpeg_path, "-y",
                "-f", "lavfi",
                "-i", "anullsrc=r=22050:cl=mono",
                "-t", f"{dur_s:.3f}",
                "-c:a", "pcm_s16le",
                str(sil_path),
            ]
            result = subprocess.run(sil_cmd, capture_output=True, timeout=60)
            if result.returncode == 0 and sil_path.exists():
                concat_entries.append(str(sil_path))
                silence_index += 1
        elif seg[0] == "wav":
            concat_entries.append(seg[1])

    if not concat_entries:
        return None

    # Write FFmpeg concat list
    with open(concat_list_path, "w", encoding="utf-8") as f:
        for entry in concat_entries:
            # Escape backslashes for FFmpeg concat protocol
            safe = entry.replace("\\", "/")
            f.write(f"file '{safe}'\n")

    return concat_list_path


def assemble_audio(synthesis_results, temp_dir, ffmpeg_path):
    """
    Assemble all per-cue WAVs (with silence gaps) into one combined WAV.
    Returns path to the assembled WAV, or None on failure.
    """
    concat_list = build_ffmpeg_concat_list(synthesis_results, temp_dir, ffmpeg_path)
    if concat_list is None:
        print("Error: No audio segments to assemble.", file=sys.stderr)
        return None

    assembled_wav = temp_dir / "assembled.wav"
    cmd = [
        ffmpeg_path, "-y",
        "-f", "concat",
        "-safe", "0",
        "-i", str(concat_list),
        "-c:a", "pcm_s16le",
        str(assembled_wav),
    ]

    print("  Assembling timed audio track...", flush=True)
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        if result.returncode != 0:
            print(f"Error: FFmpeg audio assembly failed:\n{result.stderr}", file=sys.stderr)
            return None
        return assembled_wav
    except Exception as exc:
        print(f"Error: FFmpeg audio assembly exception: {exc}", file=sys.stderr)
        return None


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

    print(f"  Muxing to MP4: {output_mp4}", flush=True)
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=1800)
        if result.returncode != 0:
            print(f"Error: FFmpeg MP4 muxing failed:\n{result.stderr}", file=sys.stderr)
            return False
        return True
    except Exception as exc:
        print(f"Error: FFmpeg muxing exception: {exc}", file=sys.stderr)
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
        print(
            f"  [INFO] Temporary files preserved for debugging: '{temp_dir}'",
            file=sys.stderr,
        )


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
                lang_override=None, output_dir_override=None, zid_cache=None):
    """
    Full pipeline for a single SRT file:
      1. Detect language
      2. Parse SRT
      3. Synthesize per-cue WAVs
      4. Assemble timed audio
      5. Mux to MP4
      6. Cleanup

    Returns True on success, False on failure.
    """
    if zid_cache is None:
        zid_cache = {}

    srt_path = Path(srt_path).resolve()
    print(f"\n{'='*60}")
    print(f"Processing: {srt_path.name}")
    print(f"{'='*60}")

    # 1. Language detection
    if lang_override:
        lang = lang_override.strip().lower()
        print(f"  Language: {lang} (CLI override)")
    else:
        lang = detect_language(str(srt_path), config)
        print(f"  Language detected: {lang} (from filename postfix)")

    supported = get_supported_languages(piper_config)
    validate_language(lang, piper_config, supported)

    section = f"voice_{lang}"
    model_file = piper_config.get(section, "model", fallback="(unknown)")
    print(f"  Piper model: {model_file}")

    # 2. Parse SRT
    print("  Parsing SRT...", flush=True)
    try:
        cues = parse_srt(str(srt_path))
    except Exception as exc:
        print(f"Error parsing SRT file: {exc}", file=sys.stderr)
        return False

    if not cues:
        print("Error: No valid subtitle cues found in the SRT file.", file=sys.stderr)
        return False

    print(f"  Found {len(cues)} cues to synthesize.")

    # 3. Temporary directory
    output_dir = Path(output_dir_override) if output_dir_override else srt_path.parent
    output_dir.mkdir(parents=True, exist_ok=True)
    temp_dir = Path(tempfile.mkdtemp(prefix="sub_tts_", dir=output_dir))
    print(f"  Temp dir: {temp_dir}")

    success = False
    try:
        # 4. Per-cue synthesis
        synthesis_results = synthesize_all_cues(cues, lang, temp_dir, piper_root)
        successful = sum(1 for r in synthesis_results if r["ok"])
        print(f"  Synthesis complete: {successful}/{len(cues)} cues succeeded.")

        if successful == 0:
            print("Error: All cue synthesis attempts failed. Check Piper TTS setup.", file=sys.stderr)
            return False

        # 5. Assemble timed audio
        assembled_wav = assemble_audio(synthesis_results, temp_dir, ffmpeg_path)
        if assembled_wav is None:
            return False

        # 6. Output path
        output_mp4, policy = resolve_output_path(str(srt_path), output_dir, config, lang, zid_cache)
        if policy == "skip":
            print(f"  Skipping (output already exists): {output_mp4}")
            success = True
            return True

        output_mp4.parent.mkdir(parents=True, exist_ok=True)

        # 7. Mux to MP4
        ok = mux_to_mp4(assembled_wav, output_mp4, ffmpeg_path)
        if ok:
            print(f"  ✓ Output: {output_mp4}")
            success = True
        return ok

    finally:
        cleanup_temp_dir(temp_dir, success)


# ==============================================================================
# CLI INTERFACE (tasks 8.1 – 8.3)
# ==============================================================================

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

    # Collect input files
    input_files = args.srt_files

    if not input_files:
        print(
            "No SRT files provided.\n"
            "Usage: python sub_tts.py video.de.srt [video2.ru.srt ...]\n"
            "   or: python sub_tts.py --sendto <file1> <file2>  (SendTo mode)",
            file=sys.stderr,
        )
        sys.exit(1)

    # Filter to .srt files only
    srt_files = [f for f in input_files if f.lower().endswith(".srt")]
    skipped = [f for f in input_files if not f.lower().endswith(".srt")]
    for s in skipped:
        print(f"[SKIP] Not an SRT file: {s}")

    if not srt_files:
        print("Error: No valid .srt files were provided.", file=sys.stderr)
        sys.exit(1)

    # Load configuration
    config = load_config()

    # Resolve FFmpeg
    try:
        ffmpeg_path = resolve_ffmpeg(config, cli_override=args.ffmpeg_path)
    except FileNotFoundError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)

    # Load Piper TTS config
    piper_config, piper_root = get_piper_config(config)

    # Process each file
    zid_cache = {}
    results = []

    for srt_path in srt_files:
        ok = process_srt(
            srt_path,
            config=config,
            piper_config=piper_config,
            piper_root=piper_root,
            ffmpeg_path=ffmpeg_path,
            lang_override=args.lang,
            output_dir_override=args.output_dir,
            zid_cache=zid_cache,
        )
        results.append((srt_path, ok))

    # Summary
    elapsed = time.time() - start_time
    succeeded = sum(1 for _, ok in results if ok)
    total = len(results)

    print(f"\n{'='*60}")
    print(f"Completed in {elapsed:.1f}s — {succeeded}/{total} files converted successfully.")
    if succeeded < total:
        print("Failed files:")
        for path, ok in results:
            if not ok:
                print(f"  ✗ {path}")
    print(f"{'='*60}")

    if args.pause:
        try:
            input("\nPress Enter to close this window...")
        except (EOFError, KeyboardInterrupt):
            pass

    sys.exit(0 if succeeded == total else 1)


if __name__ == "__main__":
    main()
