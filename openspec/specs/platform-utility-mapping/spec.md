# Spec: Platform Utility Mapping

## Context
Each platform has preferred command-line tools for clipboard access.

## Requirements
- Map the following utilities to the detected platforms:
    - **Windows**: `powershell -Command "..."` with configurable retry logic.
    - **macOS**: `pbcopy` / `pbpaste`
    - **Linux (Wayland)**: `wl-copy` / `wl-paste`
    - **Linux (X11)**: `xclip` / `xsel`
    - **Termux**: `termux-clipboard-get` / `termux-clipboard-set`
- Implement fallback logic if a specific utility is missing in Linux (e.g., try `wl-copy` then `xclip`).

### Requirement: Windows Clipboard Reliability
The Windows implementation MUST include a retry mechanism to handle clipboard resource locking by background processes (e.g., dictionary tools).
- The retry count MUST be configurable via `win_clipboard_retries`.
- The retry delay MUST be configurable via `win_clipboard_retry_delay`.
- The implementation SHALL utilize a PowerShell `try/catch` loop with `Start-Sleep` for retries.

## Verification
- Test on a Windows machine to ensure PowerShell is still used.
- (Manual) Verify that the script branches correctly when mock platform variables are used.
