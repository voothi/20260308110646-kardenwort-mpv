## Why

Clipboard synchronization between `kardenwort-mpv` and GoldenDict was prone to race conditions and keyboard layout conflicts (EN/RU). Character-based hotkey injection often resulted in "garbage" text (e.g., `q`, `й`) appearing in search fields, while AHK polling introduced unpredictable latency.

## What Changes

- **Layout-Independent VK Engine**: Implemented raw Win32 `keybd_event` injection via PowerShell, ensuring the trigger works identically across all keyboard layouts without typing "ghost" characters.
- **Dual-Mode Lookup Support**: Added independent notification paths for "Side Popup" and "Main Window" modes, triggered by standard and context-aware copy operations.
- **Asynchronous Execution**: Fully decoupled the notification bridge from the MPV main thread to ensure zero UI stutter.
- **Unified Naming**: Standardized configuration keys (`gd_trigger_enabled`, `gd_hotkey_...`) for improved maintainability.

## Capabilities

### Modified Capabilities
- `unified-clipboard-abstraction`: Enhanced with a high-reliability, layout-agnostic, multi-mode notification engine.

## Impact

- **Affected Code**: `scripts/lls_core.lua`, `mpv.conf`.
- **UX**: Near-instantaneous dictionary popups that are 100% reliable regardless of active keyboard layout, with zero "garbage" characters in the search field.
