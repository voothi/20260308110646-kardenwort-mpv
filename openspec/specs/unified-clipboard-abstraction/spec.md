# Spec: Unified Clipboard & Dictionary Engine (v1.58.58)

## Context
Standardizing the clipboard synchronization bridge between MPV and GoldenDict to ensure reliable, layout-independent operation and to eliminate race conditions and recursive trigger loops.

## Technical Requirements

### 1. Decoupled Key Schema
The system must support independent key assignments for copying and dictionary lookup to prevent unintended interface activation.

- **`key_copy_standard`**: (Default `Ctrl+C`) Standard clipboard update. Mode `none`.
- **`key_copy_popup`**: (Default `Shift+C`) Clipboard update + Side Popup trigger. Mode `side`.
- **`key_copy_main`**: (Default `Alt+C`) Clipboard update + Main window trigger. Mode `main`.

### 2. Multi-Engine Reliability
- **PowerShell Engine**: Must utilize `Add-Type` for direct Win32 access to ensure sub-100ms trigger latency.
- **Python Engine**: Must utilize `ctypes` and provide a configurable `python_trigger_delay` (0.1s - 0.5s) to ensure OS-level clipboard propagation.

### 3. Anti-Recursion Logic
The script must implement a global `gd_trigger_lock_duration` (Default 2.0s). If a dictionary trigger has been fired within this window, any subsequent copy commands (e.g., from AHK feedback) must update the clipboard buffer silently without re-injecting hotkeys.

### 4. Layout-Independence
All trigger signals must be injected as **Virtual Key (VK)** codes to ensure 100% reliability across EN and RU keyboard layouts. Sending characters (e.g., `^!+q`) is strictly prohibited.
The system SHALL expose a consistent `gd_` prefix for all dictionary-related settings in `mpv.conf`, supporting independent hotkeys for "Popup" and "Main Window" modes.

## Verification
- Call `set_clipboard(text, "side")` and verify the GoldenDict Popup activates.
- Call `set_clipboard(text, "none")` and verify only the clipboard is updated without triggering dictionary.
- Verify that a rapid second `^c` signal (within 2s) does not trigger a second dictionary window.
