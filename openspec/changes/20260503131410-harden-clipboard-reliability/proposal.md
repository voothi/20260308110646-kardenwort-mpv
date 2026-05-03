## Why

Clipboard synchronization between `kardenwort-mpv` and GoldenDict (via AHK) is currently prone to race conditions due to the latency of PowerShell-based copy operations. This often results in the GoldenDict side window failing to appear because the AHK script times out before the data is ready.

## What Changes

- **Native Clipboard Priority**: Optimize `set_clipboard` to use MPV's native property where available, bypassing shell overhead.
- **Robust Windows Fallback**: Maintain PowerShell fallback with configurable retries and delays.
- **Explicit Lookup Trigger**: Add an option to send the GoldenDict scan hotkey (`^!+n`) directly from MPV after a successful copy.

## Capabilities

### Modified Capabilities
- `unified-clipboard-abstraction`: Enhance with low-latency native support and optional post-copy hooks.

## Impact

- **Affected Code**: `scripts/lls_core.lua`, `mpv.conf`.
- **UX**: Significant reduction in "missed" lookups and faster response time for dictionary popups.
