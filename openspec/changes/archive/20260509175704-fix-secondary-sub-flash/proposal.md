## Why

In Drum Mode and single-line SRT mode, switching the secondary subtitle track causes a visual "flash" or "twitch" where native mpv subtitles are briefly visible before the custom OSD suppresses them. This degrades the premium feel of the Kardenwort-mpv immersion engine and causes momentary OSD blockage.

## What Changes

- **Synchronous Suppression**: Immediately set `secondary-sub-visibility` to `false` when cycling tracks if custom OSD rendering is active.
- **Observer Hardening**: Ensure the `secondary-sid` observer also enforces immediate suppression to cover track changes initiated via external means (e.g. native mpv keys or scripts).
- **Initialization Fix**: Ensure that on startup or file-load, the visibility state is correctly synchronized with the FSM intent before the first tick.

## Capabilities

### New Capabilities
- `secondary-sub-visibility-suppression`: Ensures immediate suppression of native secondary subtitles when custom OSD is active, eliminating race conditions during track switching.

### Modified Capabilities
<!-- None -->

## Impact

- `lls_core.lua`: Affects `cmd_cycle_sec_sid`, the `secondary-sid` observer, and potentially `master_tick`'s initial pass.
- Visual UX: Eliminates flickering and OSD "twitching" during secondary track selection.
