# Spec: Platform Utility Mapping

## Context
Each platform has preferred command-line tools for clipboard access.

## Requirements
- Map the following utilities to the detected platforms:
    - **Windows**: `powershell -Command "..."`
    - **macOS**: `pbcopy` / `pbpaste`
    - **Linux (Wayland)**: `wl-copy` / `wl-paste`
    - **Linux (X11)**: `xclip` / `xsel`
    - **Termux**: `termux-clipboard-get` / `termux-clipboard-set`
- Implement fallback logic if a specific utility is missing in Linux (e.g., try `wl-copy` then `xclip`).

## Verification
- Test on a Windows machine to ensure PowerShell is still used.
- (Manual) Verify that the script branches correctly when mock platform variables are used.
