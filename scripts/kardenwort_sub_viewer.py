#!/usr/bin/env python
import os
import sys
import glob
import subprocess

def main():
    if len(sys.argv) < 2:
        print("Usage: python kardenwort_sub_viewer.py <subtitle_file>")
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
    if len(parts) > 1 and len(parts[-1]).lower() in ('de', 'ru', 'en', 'eng', 'ger', 'rus', 'uk', 'es', 'fr', 'it'):
        main_base = '.'.join(parts[:-1])
    else:
        main_base = sub_base

    # 3. Determine the highlight TSV path
    tsv_path = os.path.join(sub_dir, f"{main_base}.tsv")

    # 4. Search for a matching secondary translation subtitle track
    secondary_sub = None
    supported_extensions = ('.srt', '.ass', '.vtt')
    
    for candidate in glob.glob(os.path.join(sub_dir, f"{main_base}.*")):
        cand_ext = os.path.splitext(candidate)[1].lower()
        if cand_ext in supported_extensions and os.path.abspath(candidate) != sub_path:
            secondary_sub = candidate
            break

    # 5. Build the mpv command
    # We use av://lavfi to generate a virtual 1280x720 black video stream with a 2-hour timeline (7200s)
    cmd = [
        'mpv',
        'av://lavfi:color=c=black:s=1280x720:d=7200',
        f'--sub-file={sub_path}',
        f'--script-opts=kardenwort-anki_record_file={tsv_path}',
        '--pause=yes'  # Start paused so the user can settle and navigate
    ]

    # If secondary subtitles were found, load them as the secondary track
    if secondary_sub:
        cmd.append(f'--sub-file={secondary_sub}')
        cmd.append('--sid=1')
        cmd.append('--secondary-sid=2')
        print(f"[Kardenwort Launch] Found secondary subtitle: {os.path.basename(secondary_sub)}")
    else:
        print("[Kardenwort Launch] Single subtitle track mode")

    print(f"[Kardenwort Launch] Primary subtitle:   {os.path.basename(sub_path)}")
    print(f"[Kardenwort Launch] Highlight TSV:      {os.path.basename(tsv_path)}")
    print(f"[Kardenwort Launch] Running command:    {' '.join(cmd)}")

    # 6. Launch mpv detached so the caller command/terminal can exit safely
    try:
        subprocess.Popen(
            cmd,
            creationflags=subprocess.CREATE_NEW_CONSOLE | subprocess.DETACHED_PROCESS if os.name == 'nt' else 0,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except FileNotFoundError:
        print("Error: 'mpv' executable not found on PATH. Please ensure mpv is installed and added to your system environment variables.")
        sys.exit(1)

if __name__ == '__main__':
    main()
