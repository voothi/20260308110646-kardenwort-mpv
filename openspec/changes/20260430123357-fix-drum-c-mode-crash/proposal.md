## Why

Drum Mode (C) completely fails to render subtitles due to a fatal Lua string formatting error introduced in commit `81ee67b`. The newly added `DRUM_DRAW_CACHE` relies on `%d` format specifiers for floating-point values (`lh_mul` and `vsp`), which throws a runtime exception that is silently trapped by `xpcall`, resulting in invisible OSD output. This regression must be immediately patched to restore core functionality.

## What Changes

- Modify the cache key generation in `draw_drum` to safely format floating point config variables.
- Replace `%d` with `%g` for `lh_mul`, `vsp`, and `font_size` to prevent `number has no integer representation` errors.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- None

## Impact

- **Affected Code**: `scripts/lls_core.lua` (`draw_drum` cache logic).
- **Behavioral Impact**: Safely restores rendering pipeline stability for Drum Mode without mutating the underlying layout specifications.
