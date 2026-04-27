## Why

Ensure all script-level options in `lls_core.lua` are configurable via `mpv.conf` to improve user customization and maintain parity between implementation and configuration. This addresses gaps identified in tasks `20260427020857` and `20260427021305`.

## What Changes

- **Option Synchronization**: Added 6 missing LLS script options to `mpv.conf` (`osd_interactivity`, `dw_scrolloff`, `dw_active_opacity`, `dw_context_opacity`, `dw_key_cycle_copy_mode`, `dw_key_toggle_copy_context`).
- **Configuration Documentation**: Added explanatory comments for `osd_interactivity` and `dw_scrolloff` in `mpv.conf`.
- **Code Cleanup**: Removed a duplicate `book_mode` definition in `lls_core.lua`.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `centralized-script-options`: Synchronized configuration file with the core script options table.

## Impact

- `mpv.conf`: 6 new options exposed, 2 new comments added.
- `scripts/lls_core.lua`: Removed one duplicate line in the `Options` table.
