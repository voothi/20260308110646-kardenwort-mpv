#!/usr/bin/env python
import os
import sys
import glob
import subprocess

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

def main():
    if len(sys.argv) < 2:
        print("Usage: python viewer.py <subtitle_file>")
        sys.exit(1)

    sub_path = os.path.abspath(sys.argv[1])
    if not os.path.isfile(sub_path):
        print(f"Error: Subtitle file not found: {sub_path}")
        sys.exit(1)

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

    # 4. Search for a matching secondary translation subtitle track
    secondary_sub = None
    
    for candidate in glob.glob(os.path.join(sub_dir, f"{main_base}.*")):
        cand_ext = os.path.splitext(candidate)[1].lower()
        if cand_ext in SUPPORTED_EXTENSIONS and os.path.abspath(candidate) != sub_path:
            secondary_sub = candidate
            break

    # 5. Build the mpv command using configuration values
    cmd = [
        'mpv',
        f'av://lavfi:color=c={VIRTUAL_VIDEO_COLOR}:s={VIRTUAL_VIDEO_SIZE}:d={VIRTUAL_VIDEO_DURATION}',
        f'--sub-file={sub_path}',
        f'--script-opts=kardenwort-anki_record_file={tsv_path}',
        f'--pause={PAUSE_ON_LAUNCH}'
    ]

    # If secondary subtitles were found, load them as the secondary track
    if secondary_sub:
        cmd.append(f'--sub-file={secondary_sub}')
        cmd.append('--sid=1')
        cmd.append('--secondary-sid=2')
        print(f"[Sub Viewer] Found secondary subtitle: {os.path.basename(secondary_sub)}")
    else:
        print("[Sub Viewer] Single subtitle track mode")

    print(f"[Sub Viewer] Primary subtitle:   {os.path.basename(sub_path)}")
    print(f"[Sub Viewer] Highlight TSV:      {os.path.basename(tsv_path)}")
    print(f"[Sub Viewer] Running command:    {' '.join(cmd)}")

    # 6. Launch mpv detached so the caller processes can exit immediately
    try:
        subprocess.Popen(
            cmd,
            creationflags=subprocess.DETACHED_PROCESS if os.name == 'nt' else 0,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except FileNotFoundError:
        print("Error: 'mpv' executable not found on PATH. Please ensure mpv is installed and added to system variables.")
        sys.exit(1)

if __name__ == '__main__':
    main()

