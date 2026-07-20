#!/usr/bin/env python
# ==============================================================================
# YouTube Video Downloader — Windows SendTo Shortcut Installer
#
# Creates a "Kardenwort YouTube Downloader" shortcut in the Windows "Send to" folder.
# After installation:
#   1. Select files or directories containing YouTube URLs.
#   2. Right-click → Send to → Kardenwort YouTube Downloader.
#   3. The downloader runs and downloads videos/subtitles.
#
# Usage:
#   python install.py
# ==============================================================================

import os
import sys
import subprocess

# ==============================================================================
# GLOBAL CONFIGURATION PARAMETERS (Feel free to customize)
# ==============================================================================
# The display name of the Windows context menu shortcut (excluding .lnk extension)
SHORTCUT_DISPLAY_NAME = "Kardenwort Download YouTube"

# Legacy shortcut names to search for and automatically clean up during install
LEGACY_SHORTCUT_NAMES = ("Kardenwort YouTube Downloader", "Download YouTube Video")

# Standard SendTo location (Windows %APPDATA% mapping)
SENDTO_DIRECTORY = r'%APPDATA%\Microsoft\Windows\SendTo'
# ==============================================================================

def main():
    print(f"=== {SHORTCUT_DISPLAY_NAME} Shortcut Installer ===")

    # 1. Locate paths
    current_dir = os.path.dirname(os.path.abspath(__file__))
    script_path = os.path.join(current_dir, 'youtube_downloader.py')
    
    if not os.path.exists(script_path):
        print(f"Error: Could not find {script_path}")
        sys.exit(1)
        
    python_path = sys.executable
    # Ensure we use python.exe, not pythonw.exe so a console window is visible
    if python_path.lower().endswith("pythonw.exe"):
        python_path = python_path[:-len("pythonw.exe")] + "python.exe"

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
    print(f"Python Path:       {python_path}")
    print(f"SendTo Directory:  {sendto_dir}")
    print(f"Shortcut Path:     {shortcut_path}")

    # 3. Create shortcut using PowerShell and WScript
    ps_script = (
        f"$WshShell = New-Object -ComObject WScript.Shell; "
        f"$Shortcut = $WshShell.CreateShortcut('{shortcut_path}'); "
        f"$Shortcut.TargetPath = '{python_path}'; "
        f"$Shortcut.Arguments = '\"{script_path}\" --sendto --pause'; "
        f"$Shortcut.Description = 'Downloads YouTube videos and subtitles from files or folders'; "
        f"$Shortcut.WindowStyle = 1; "  # Normal window style
        f"$Shortcut.Save()"
    )

    try:
        print("\nCreating shortcut in Windows 'Send to' menu...")
        subprocess.run(
            ['powershell', '-NoProfile', '-Command', ps_script],
            capture_output=True,
            text=True,
            check=True
        )
        print(f"SUCCESS: '{SHORTCUT_DISPLAY_NAME}' shortcut created successfully!")
        print("\nHow to use:")
        print("  1. Right-click any file/folder containing YouTube links.")
        print(f"  2. Select 'Send to' -> '{SHORTCUT_DISPLAY_NAME}'.")
        print("  3. The downloader will open, parse links, and download videos/subtitles.")
    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to create shortcut. PowerShell error details:\n{e.stderr}")
        sys.exit(1)

if __name__ == '__main__':
    main()
