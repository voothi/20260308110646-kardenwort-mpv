#!/usr/bin/env python
import os
import sys
import subprocess
import shutil

# ==============================================================================
# GLOBAL CONFIGURATION PARAMETERS (Feel free to customize)
# ==============================================================================
# The display name of the Windows context menu shortcut (excluding .lnk extension)
SHORTCUT_DISPLAY_NAME = "Kardenwort Sub Viewer"

# Legacy shortcut names to search for and automatically clean up during install
LEGACY_SHORTCUT_NAMES = (
    "Kardenwort Subtitle Only",
)

# Standard SendTo location (Windows %APPDATA% mapping)
SENDTO_DIRECTORY = r'%APPDATA%\Microsoft\Windows\SendTo'
# ==============================================================================

def main():
    print(f"=== {SHORTCUT_DISPLAY_NAME} Shortcut Installer ===")

    # 1. Locate paths
    current_dir = os.path.dirname(os.path.abspath(__file__))
    script_path = os.path.join(current_dir, 'viewer.py')
    
    if not os.path.exists(script_path):
        print(f"Error: Could not find {script_path}")
        sys.exit(1)
        
    pythonw_path = sys.executable.lower().replace("python.exe", "pythonw.exe")
    if not os.path.exists(pythonw_path):
        pythonw_path = sys.executable

    sendto_dir = os.path.expandvars(SENDTO_DIRECTORY)
    shortcut_path = os.path.join(sendto_dir, f"{SHORTCUT_DISPLAY_NAME}.lnk")

    # 2. Clean up old obsolete shortcuts if they exist
    for legacy_name in LEGACY_SHORTCUT_NAMES:
        old_path = os.path.join(sendto_dir, f"{legacy_name}.lnk")
        if os.path.exists(old_path):
            try:
                os.remove(old_path)
                print(f"Cleaned up obsolete legacy shortcut: {os.path.basename(old_path)}")
            except Exception as e:
                print(f"Warning: Could not remove old shortcut: {e}")

    print(f"Script Path:       {script_path}")
    print(f"Pythonw Path:      {pythonw_path}")
    print(f"SendTo Directory:  {sendto_dir}")
    print(f"Shortcut Path:     {shortcut_path}")

    # 3. Check if black.mp4 exists, and generate it using ffmpeg if missing
    black_video = os.path.join(current_dir, 'black.mp4')
    if not os.path.exists(black_video):
        print("\nOptimized seekable canvas 'black.mp4' is missing. Checking for ffmpeg...")
        ffmpeg_exe = shutil.which('ffmpeg')
        if ffmpeg_exe:
            print("ffmpeg found! Generating optimized seekable 10-hour black.mp4 canvas...")
            cmd = [
                'ffmpeg', '-y', '-f', 'lavfi', '-i', 'color=c=black:s=1280x720:d=36000',
                '-r', '1', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '51',
                '-preset', 'ultrafast', '-g', '300', '-an', black_video
            ]
            try:
                subprocess.run(cmd, capture_output=True, check=True)
                print("SUCCESS: Optimized black.mp4 canvas generated successfully!")
            except Exception as e:
                print(f"Warning: Failed to generate black.mp4 dynamically: {e}")
        else:
            print("Warning: ffmpeg not found. Sub Viewer will fall back to virtual av://lavfi (which is unseekable).")

    # 4. Create shortcut using PowerShell and WScript
    ps_script = (
        f"$WshShell = New-Object -ComObject WScript.Shell; "
        f"$Shortcut = $WshShell.CreateShortcut('{shortcut_path}'); "
        f"$Shortcut.TargetPath = '{pythonw_path}'; "
        f"$Shortcut.Arguments = '\"{script_path}\"'; "
        f"$Shortcut.WindowStyle = 7; "  # Minimized window style
        f"$Shortcut.Save()"
    )

    try:
        print("Creating shortcut in Windows 'Send to' menu...")
        subprocess.run(
            ['powershell', '-NoProfile', '-Command', ps_script],
            capture_output=True,
            text=True,
            check=True
        )
        print(f"SUCCESS: '{SHORTCUT_DISPLAY_NAME}' shortcut created successfully!")
        print("\nHow to use:")
        print("1. Locate any subtitle file (.srt, .ass, .vtt) in Windows Explorer.")
        print(f"2. Right-click the file -> Send to -> '{SHORTCUT_DISPLAY_NAME}'.")
        print("3. mpv will launch with a virtual black background and Kardenwort active!")
        print("4. A matching highlight TSV file will be automatically managed next to the subtitles.")
    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to create shortcut. PowerShell error details:\n{e.stderr}")
        sys.exit(1)

if __name__ == '__main__':
    main()

