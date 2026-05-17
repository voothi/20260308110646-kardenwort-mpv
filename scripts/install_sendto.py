#!/usr/bin/env python
import os
import sys
import subprocess

def main():
    print("=== Kardenwort 'Send to' Shortcut Installer ===")

    # 1. Locate paths
    current_dir = os.path.dirname(os.path.abspath(__file__))
    script_path = os.path.join(current_dir, 'kardenwort_sub_viewer.py')
    
    if not os.path.exists(script_path):
        print(f"Error: Could not find {script_path}")
        sys.exit(1)
        
    pythonw_path = sys.executable.lower().replace("python.exe", "pythonw.exe")
    if not os.path.exists(pythonw_path):
        # Fall back to sys.executable if pythonw.exe is not found
        pythonw_path = sys.executable

    sendto_dir = os.path.expandvars(r'%APPDATA%\Microsoft\Windows\SendTo')
    shortcut_path = os.path.join(sendto_dir, 'Kardenwort Subtitle Only.lnk')

    print(f"Script Path:       {script_path}")
    print(f"Pythonw Path:      {pythonw_path}")
    print(f"SendTo Directory:  {sendto_dir}")
    print(f"Shortcut Path:     {shortcut_path}")

    # 2. Build and execute PowerShell command to create the WScript Shell shortcut
    # This avoids any third-party library dependencies (like pywin32)
    ps_script = (
        f"$WshShell = New-Object -ComObject WScript.Shell; "
        f"$Shortcut = $WshShell.CreateShortcut('{shortcut_path}'); "
        f"$Shortcut.TargetPath = '{pythonw_path}'; "
        f"$Shortcut.Arguments = '\"{script_path}\" \"%1\"'; "
        f"$Shortcut.WindowStyle = 7; "  # Minimized window style
        f"$Shortcut.Save()"
    )

    try:
        print("Creating shortcut in Windows 'Send to' menu...")
        result = subprocess.run(
            ['powershell', '-NoProfile', '-Command', ps_script],
            capture_output=True,
            text=True,
            check=True
        )
        print("SUCCESS: Shortcut created successfully!")
        print("\nHow to use:")
        print("1. Locate any subtitle file (.srt, .ass, .vtt) in Windows Explorer.")
        print("2. Right-click the file -> Show more options -> Send to -> 'Kardenwort Subtitle Only'.")
        print("3. mpv will launch with a virtual black background and Kardenwort active!")
        print("4. A matching highlight TSV file will be automatically managed next to the subtitles.")
    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to create shortcut. PowerShell error details:\n{e.stderr}")
        sys.exit(1)

if __name__ == '__main__':
    main()
