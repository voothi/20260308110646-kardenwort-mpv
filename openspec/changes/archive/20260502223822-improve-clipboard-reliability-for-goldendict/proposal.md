# Proposal: Improve Clipboard Reliability for GoldenDict

## Problem

When using Kardenwort-mpv on Windows with GoldenDict, the clipboard synchronization occasionally fails ("gaps"). This is likely due to clipboard resource locking, where GoldenDict (or another background process) holds the clipboard lock while the script attempts to update it.

Currently, the script uses a hardcoded retry loop (5 tries, 50ms delay) in PowerShell. This may not be sufficient for all environments, or the fixed delay might be poorly timed for GoldenDict's polling behavior.

## What Changes

- Introduce configurable options for Windows clipboard retry logic: `win_clipboard_retries` and `win_clipboard_retry_delay`.
- Update the `set_clipboard` function to utilize these new options dynamically.
- Allow users to debug synchronization issues by adjusting these parameters via `mpv.conf` or script-opts.

## Capabilities

### Modified Capabilities
- `system-clipboard`: Enhance reliability on Windows via configurable retry logic.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (Options and `set_clipboard`).
- **UX**: More reliable translation lookup in GoldenDict, reduced "gaps" in lookup history.
- **Diagnostics**: Easier debugging of OS-level clipboard conflicts.
