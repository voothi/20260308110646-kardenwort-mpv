#!/usr/bin/env python
import os
import sys
import subprocess
import re
import shutil
import traceback

# ==============================================================================
# GLOBAL CONFIGURATION PARAMETERS (Feel free to customize)
# ==============================================================================
# Supported subtitle file extensions to search for primary & secondary tracks
SUPPORTED_EXTENSIONS = ('.srt', '.ass', '.vtt')

# Language code suffixes to strip when determining base name (e.g., file.de.srt -> base file)
LANG_SUFFIXES = ('de', 'ru', 'en', 'eng', 'ger', 'rus', 'uk', 'es', 'fr', 'it')

# Virtual Video Stream Parameters
VIRTUAL_VIDEO_COLOR = 'black'        # Can be black, grey, white, blue, etc.
VIRTUAL_VIDEO_SIZE = '1280x720'      # Dimensions of the player window
VIRTUAL_VIDEO_DURATION = 7200        # Timeline length in seconds (e.g. 7200 = 2 hours)

# Initial playback state (yes = start paused, no = play immediately)
PAUSE_ON_LAUNCH = 'yes'
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

def get_first_sub_start(filepath, max_duration=7200):
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

def main():
    try:
        if len(sys.argv) < 2:
            raise ValueError("No subtitle file provided. Drag and drop a subtitle file onto the script or shortcut.")

        # Detect and handle Windows Explorer passing "%1" literally as the first argument
        raw_arg = sys.argv[1]
        if raw_arg == "%1" and len(sys.argv) >= 3:
            raw_arg = sys.argv[2]
        elif raw_arg == "%1":
            raise ValueError("No subtitle file provided. Drag and drop a subtitle file onto the script or shortcut.")

        sub_path = os.path.abspath(raw_arg)
        if not os.path.isfile(sub_path):
            raise FileNotFoundError(f"Subtitle file not found: {sub_path}")

        # 1. Resolve base directory and file name
        sub_dir, sub_file = os.path.split(sub_path)
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
        secondary_sub = None
        if os.path.exists(sub_dir):
            for entry in os.listdir(sub_dir):
                full_path = os.path.join(sub_dir, entry)
                if os.path.isfile(full_path) and entry.lower().startswith(main_base.lower() + "."):
                    cand_ext = os.path.splitext(entry)[1].lower()
                    if cand_ext in SUPPORTED_EXTENSIONS and os.path.abspath(full_path) != sub_path:
                        secondary_sub = full_path
                        break

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

        log_path = os.path.join(sub_dir, "mpv_sub_viewer.log")
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
        subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

    except Exception as e:
        error_msg = f"{e}\n\nTraceback:\n{traceback.format_exc()}"
        log_error_and_alert(error_msg)
        sys.exit(1)

if __name__ == '__main__':
    main()

