#!/usr/bin/env python
import os
import sys
import subprocess
import re
import shutil
import traceback
import tempfile
import threading

# ==============================================================================
# GLOBAL CONFIGURATION PARAMETERS (Feel free to customize)
# ==============================================================================
# Supported subtitle file extensions to search for primary & secondary tracks
SUPPORTED_EXTENSIONS = ('.srt', '.ass', '.vtt')
SUPPORTED_TEXT_EXTENSIONS = ('.txt', '.md', '.rst', '.log')

# Language code suffixes to strip when determining base name (e.g., file.de.srt -> base file)
LANG_SUFFIXES = ('de', 'ru', 'en', 'eng', 'ger', 'rus', 'uk', 'es', 'fr', 'it')

# Virtual Video Stream Parameters
VIRTUAL_VIDEO_COLOR = 'black'        # Can be black, grey, white, blue, etc.
VIRTUAL_VIDEO_SIZE = '1280x720'      # Dimensions of the player window
VIRTUAL_VIDEO_DURATION = 36000       # Timeline length in seconds (e.g. 36000 = 10 hours)

# Initial playback state (yes = start paused, no = play immediately)
PAUSE_ON_LAUNCH = 'yes'
READER_SECONDS_PER_BLOCK = 6.0
READER_MAX_LINES_PER_BLOCK = 1
READER_MAX_CHARS_PER_LINE = 90
READER_MIN_BLOCKS = 2
# ==============================================================================

def log_error_and_alert(error_msg):
    """
    Logs the error to a local file and displays a Windows MessageBox popup.
    """
    script_dir = os.path.dirname(os.path.abspath(__file__))
    log_path = os.path.join(script_dir, "sub_viewer_launch.log")
    
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
                blocks.append("\\N".join(current_lines))
                current_lines = []
            continue

        wrapped = _split_long_line(stripped, READER_MAX_CHARS_PER_LINE)
        for wrapped_line in wrapped:
            current_lines.append(wrapped_line)
            if len(current_lines) >= READER_MAX_LINES_PER_BLOCK:
                blocks.append("\\N".join(current_lines))
                current_lines = []

    if current_lines:
        blocks.append("\\N".join(current_lines))

    return blocks


def build_reader_srt(text_path):
    with open(text_path, "r", encoding="utf-8", errors="ignore") as f:
        text = f.read()

    blocks = _text_to_blocks(text)
    if not blocks:
        raise ValueError(f"Text file is empty or has no readable lines: {text_path}")

    if len(blocks) < READER_MIN_BLOCKS:
        # Force at least 2 cues for meaningful seek/navigation UX.
        only = blocks[0]
        parts = _split_long_line(only.replace("\\N", " "), READER_MAX_CHARS_PER_LINE // 2)
        if len(parts) >= 2:
            mid = len(parts) // 2
            blocks = [" ".join(parts[:mid]), " ".join(parts[mid:])]

    cue_lines = []
    current_start = 0.0
    for idx, block in enumerate(blocks, 1):
        start = current_start
        end = start + READER_SECONDS_PER_BLOCK
        cue_lines.append(str(idx))
        cue_lines.append(f"{_seconds_to_srt_time(start)} --> {_seconds_to_srt_time(end)}")
        cue_lines.append(block)
        cue_lines.append("")
        current_start = end

    fd, temp_path = tempfile.mkstemp(prefix="kardenwort-reader-", suffix=".srt")
    os.close(fd)
    with open(temp_path, "w", encoding="utf-8", newline="\n") as out:
        out.write("\n".join(cue_lines))
    return temp_path


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


def get_mpv_log_path():
    """
    Keep mpv runtime logs out of user content folders.
    """
    script_dir = os.path.dirname(os.path.abspath(__file__))
    logs_dir = os.path.join(script_dir, "logs")
    os.makedirs(logs_dir, exist_ok=True)
    return os.path.join(logs_dir, "mpv_sub_viewer.log")


def _safe_remove_file(path):
    if not path:
        return
    try:
        os.remove(path)
    except OSError:
        pass


def _cleanup_after_process_exit(proc, temp_path):
    try:
        proc.wait()
    finally:
        _safe_remove_file(temp_path)

def main():
    generated_temp_path = None
    try:
        if len(sys.argv) < 2:
            raise ValueError("No file provided. Drag and drop a subtitle/text file onto the script or shortcut.")

        # Detect and handle Windows Explorer passing "%1" literally as the first argument
        raw_arg = sys.argv[1]
        if raw_arg == "%1" and len(sys.argv) >= 3:
            raw_arg = sys.argv[2]
        elif raw_arg == "%1":
            raise ValueError("No file provided. Drag and drop a subtitle/text file onto the script or shortcut.")

        input_path = os.path.abspath(raw_arg)
        if not os.path.isfile(input_path):
            raise FileNotFoundError(f"Input file not found: {input_path}")

        sub_path, generated_reader_sub = resolve_subtitle_input(input_path)
        if generated_reader_sub:
            generated_temp_path = sub_path

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

        # 4. Search for a matching secondary translation subtitle track (immune to square brackets)
        secondary_sub = None if generated_reader_sub else find_secondary_subtitle(sub_dir, main_base, sub_path)

        # 5. Locate mpv executable robustly on the system
        mpv_exe = shutil.which('mpv')
        if not mpv_exe:
            # Check standard fallback installation locations
            fallback_paths = [
                r"C:\mpv\mpv.exe",
                r"C:\mpv\mpv-0.39.0-x86_64\mpv.exe",
                r"C:\Program Files\mpv\mpv.exe",
            ]
            for path in fallback_paths:
                if os.path.exists(path):
                    mpv_exe = path
                    break

        if not mpv_exe:
            raise FileNotFoundError(
                "Could not find the 'mpv' player. Please ensure it is installed\n"
                "and either added to your system environment variables (PATH) or\n"
                "installed at 'C:\\mpv\\mpv.exe'."
            )

        # 6. Build the mpv command using configuration values
        script_dir = os.path.dirname(os.path.abspath(__file__))
        black_video = os.path.join(script_dir, "black.mp4")
        if os.path.exists(black_video):
            video_input = black_video
        else:
            video_input = f'av://lavfi:color=c={VIRTUAL_VIDEO_COLOR}:s={VIRTUAL_VIDEO_SIZE}:d={VIRTUAL_VIDEO_DURATION}'

        log_path = get_mpv_log_path()
        cmd = [
            mpv_exe,
            video_input,
            f'--sub-file={sub_path}',
            f'--script-opts-append=kardenwort-anki_record_file={tsv_path}',
            f'--pause={PAUSE_ON_LAUNCH}',
            f'--log-file={log_path}',
            '--force-window=yes',
            '--no-resume-playback'
        ]

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
            # Add a 2.0s padding for comfortable OSD breathing room at the end
            cmd.append(f'--length={last_end + 2.0}')

        # 9. Launch mpv normally so it gains foreground focus and detaches cleanly
        # Use CREATE_NO_WINDOW to prevent Windows Terminal or CMD from spawning a secondary black window
        creationflags = 0
        if os.name == 'nt':
            creationflags = 0x08000000  # CREATE_NO_WINDOW
            
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=creationflags
        )
        if generated_temp_path:
            cleanup_thread = threading.Thread(
                target=_cleanup_after_process_exit,
                args=(proc, generated_temp_path),
                daemon=True
            )
            cleanup_thread.start()

    except Exception as e:
        _safe_remove_file(generated_temp_path)
        error_msg = f"{e}\n\nTraceback:\n{traceback.format_exc()}"
        log_error_and_alert(error_msg)
        sys.exit(1)

if __name__ == '__main__':
    main()
