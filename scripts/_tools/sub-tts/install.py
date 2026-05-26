#!/usr/bin/env python
# ==============================================================================
# Kardenwort Sub TTS — Windows SendTo Shortcut Installer
#
# Creates a "Kardenwort Sub TTS" shortcut in the Windows "Send to" folder.
# After installation:
#   1. Select one or more .srt files in Windows Explorer.
#   2. Right-click → Send to → Kardenwort Sub TTS.
#   3. The pipeline runs and produces .mp4 files alongside the SRT files.
#
# Usage:
#   python install.py
# ==============================================================================

import os
import subprocess
import sys

# ==============================================================================
# CONFIGURATION
# ==============================================================================
SHORTCUT_DISPLAY_NAME = "Kardenwort Sub TTS"
LEGACY_SHORTCUT_NAMES = ()   # Add old names here if a rename ever happens
SENDTO_DIRECTORY = r"%APPDATA%\Microsoft\Windows\SendTo"
# ==============================================================================


def main():
    print(f"=== {SHORTCUT_DISPLAY_NAME} Shortcut Installer ===")

    # 1. Locate paths
    current_dir = os.path.dirname(os.path.abspath(__file__))
    script_path = os.path.join(current_dir, "sub_tts.py")

    if not os.path.exists(script_path):
        print(f"Error: Could not find {script_path}")
        sys.exit(1)

    # Use python.exe (NOT pythonw.exe) so a visible console window appears
    # during SendTo processing, letting the user see progress.
    python_path = sys.executable
    # Ensure we use python.exe, not pythonw.exe
    if python_path.lower().endswith("pythonw.exe"):
        python_path = python_path[:-len("pythonw.exe")] + "python.exe"

    sendto_dir = os.path.expandvars(SENDTO_DIRECTORY)
    os.makedirs(sendto_dir, exist_ok=True)
    shortcut_path = os.path.join(sendto_dir, f"{SHORTCUT_DISPLAY_NAME}.lnk")

    # 2. Clean up legacy shortcuts (future-proof for renames)
    for legacy_name in LEGACY_SHORTCUT_NAMES:
        old_path = os.path.join(sendto_dir, f"{legacy_name}.lnk")
        if os.path.exists(old_path):
            try:
                os.remove(old_path)
                print(f"Cleaned up legacy shortcut: {os.path.basename(old_path)}")
            except Exception as exc:
                print(f"Warning: Could not remove old shortcut: {exc}")

    print(f"Script Path:       {script_path}")
    print(f"Python Path:       {python_path}")
    print(f"SendTo Directory:  {sendto_dir}")
    print(f"Shortcut Path:     {shortcut_path}")

    # 3. Build the shortcut using PowerShell + WScript.Shell COM object.
    #    The shortcut passes --sendto so sub_tts.py knows it came from Explorer.
    arguments = f'""{script_path}"" --sendto %1'

    # --pause keeps the console open so user can read progress and close manually.
    ps_script = (
        f"$WshShell = New-Object -ComObject WScript.Shell; "
        f"$Shortcut = $WshShell.CreateShortcut('{shortcut_path}'); "
        f"$Shortcut.TargetPath = '{python_path}'; "
        f"$Shortcut.Arguments = '\"{script_path}\" --sendto --pause'; "
        f"$Shortcut.Description = 'Kardenwort Sub TTS Pipeline — SRT to MP4 with Piper TTS'; "
        f"$Shortcut.WindowStyle = 1; "   # 1 = SW_SHOWNORMAL (visible, normal window)
        f"$Shortcut.Save()"
    )

    try:
        print(f"\nCreating shortcut in Windows 'Send to' menu...")
        subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps_script],
            capture_output=True,
            text=True,
            check=True,
        )
        print(f"\nSUCCESS: '{SHORTCUT_DISPLAY_NAME}' shortcut created!")
        print("\nHow to use:")
        print("  1. Locate one or more .srt files in Windows Explorer.")
        print(f"  2. Right-click → Send to → '{SHORTCUT_DISPLAY_NAME}'.")
        print("  3. The pipeline detects the language from the filename postfix")
        print("     (e.g., video.de.srt → German) and generates video.mp4.")
        print("\nFirst-time setup:")
        print(f"  Make sure config.ini exists at: {os.path.join(os.path.dirname(script_path), 'config.ini')}")
        print(f"  (Copy config.ini.template to config.ini and edit the paths.)")
    except subprocess.CalledProcessError as exc:
        print(f"Error: Failed to create shortcut.\nPowerShell error:\n{exc.stderr}")
        sys.exit(1)


if __name__ == "__main__":
    main()
