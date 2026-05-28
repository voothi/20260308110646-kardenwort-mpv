## Why

During free listening of subtitles (when no yellow selection range or single-word yellow pointer is active), pressing the `g` hotkey (dw-add) is expected to save the current subtitle in its entirety to Anki and highlight it orange. However, the current logic either exports late or ahead of time, or fails completely, especially in Book Mode or when playback centers dynamically, due to reliance on a lagging or frozen `FSM.DW_CURSOR_LINE` instead of live playback time focus.

## What Changes

- **Live Playback Focus Fallback**: Introduce a smart fallback to resolve the target subtitle line from live playback `time-pos` when no selection exists at the moment of the `g` hotkey press.
- **Universal Cursor Synchronization**: Harden the `master_tick` cursor tracking to keep `FSM.DW_CURSOR_LINE` perfectly synchronized with `active_idx` in all follow modes (including Book Mode) when no range or pointer selection is active.
- **Robust Selection Checks**: Standardize the check for empty selection state using established `al == -1 and cw == -1` pattern across logic and OSD updates.

## Capabilities

### New Capabilities

*(None)*

### Modified Capabilities

- `export-engine-hardening`: Ensure that export actions gracefully fall back to the live playback subtitle line when no active selection is present.
- `fsm-architecture`: Refine the cursor tracking state machine in `master_tick` to keep the copy-cursor properly synchronized during free listening.

## Impact

- `scripts/kardenwort/main.lua`: Minimal, surgical changes to `dw_anki_export_selection()` and the universal cursor synchronization block in `master_tick()`.
