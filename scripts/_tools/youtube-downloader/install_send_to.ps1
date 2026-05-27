# ==============================================================================
# YouTube Video Downloader - Windows SendTo Shortcut Installer
#
# Creates a "Download YouTube Video" shortcut in the Windows "Send to" folder.
# ==============================================================================

$ShortcutName = "Download YouTube Video"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptPath = Join-Path $ScriptDir "youtube_downloader.py"

# Find python.exe
$PythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $PythonPath) {
    # Try common installation paths or fallback to sys.executable in a helper
    $PythonPath = "python.exe"
}

# Ensure we use python.exe, not pythonw.exe so a console window is visible
if ($PythonPath.EndsWith("pythonw.exe")) {
    $PythonPath = $PythonPath.Substring(0, $PythonPath.Length - 11) + "python.exe"
}

$SendToDir = [System.Environment]::ExpandEnvironmentVariables("%APPDATA%\Microsoft\Windows\SendTo")
if (-not (Test-Path $SendToDir)) {
    New-Item -ItemType Directory -Force -Path $SendToDir | Out-Null
}

$ShortcutPath = Join-Path $SendToDir "$ShortcutName.lnk"

Write-Host "=== YouTube Downloader Shortcut Installer ==="
Write-Host "Script Path:      $ScriptPath"
Write-Host "Python Path:      $PythonPath"
Write-Host "SendTo Directory: $SendToDir"
Write-Host "Shortcut Path:    $ShortcutPath"

# Create the shortcut via COM
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $PythonPath
    $Shortcut.Arguments = """$ScriptPath"" --sendto --pause"
    $Shortcut.Description = "Downloads YouTube videos and subtitles from files or folders"
    $Shortcut.WindowStyle = 1 # Normal window
    $Shortcut.Save()
    
    Write-Host "`nSUCCESS: '$ShortcutName' shortcut created in SendTo menu!" -ForegroundColor Green
    Write-Host "How to use:"
    Write-Host "  1. Right-click any file/folder containing YouTube links."
    Write-Host "  2. Select 'Send to' -> '$ShortcutName'."
    Write-Host "  3. The downloader will open, parse links, and download videos/subtitles."
} catch {
    Write-Error "Failed to create shortcut: $_"
    exit 1
}
