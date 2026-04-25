# Design: Cross-Platform Clipboard Support

## System Architecture
The clipboard system is designed as a modular abstraction layer within `lls_core.lua`.

### Components
1.  **Platform Detector**:
    - Uses `package.config:sub(1,1)` to identify the directory separator (`\` vs `/`).
    - Further refines Unix detection via `uname` command results to distinguish macOS from Linux/Android.
2.  **Clipboard Abstraction (`get_clipboard` / `set_clipboard`)**:
    - Encapsulates the execution of external shell commands.
    - Handles string escaping to prevent command injection or shell errors.
3.  **Refactored Commands**:
    - `cmd_dw_copy`: Copies selected text from the Drum Window.
    - `cmd_copy_sub`: Copies the current active subtitle.
    - `paste_from_clipboard`: Retrieves text for Search Mode or configuration overrides.

## Implementation Strategy
- **Windows**: Use `powershell.exe -NoProfile -Command "Get-Clipboard"` and similar.
- **macOS**: Use `pbcopy` and `pbpaste`.
- **Linux (Wayland)**: Use `wl-copy` and `wl-paste`.
- **Linux (X11)**: Use `xclip -selection clipboard`.
- **Termux**: Use `termux-clipboard-get` and `termux-clipboard-set`.
- **Robustness**: Always wrap clipboard text in single/double quotes and escape existing quotes during shell execution.
