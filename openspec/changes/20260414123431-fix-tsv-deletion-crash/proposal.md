# Proposal: Robust TSV Recovery and Drum Window Initialization

## Problem
The script currently crashes or hangs (showing a blank UI with no messages) when the TSV record file is externally deleted or cleared. This is due to a combination of:
1. **Startup Crash**: Synchronous failures in `load_anki_tsv` during script initialization prevent keybindings from registering.
2. **Stale Memory**: Highlights persist in memory even after the source file is deleted.
3. **Empty Data Ghosting**: The Drum Window transitions to "on" but renders nothing if subtitles are missing, providing no feedback.

## Proposed Changes

### 1. Robust Initialization (`update_media_state`)
- Wrap the initial `load_anki_tsv()` call in a `pcall`.
- Ensure that if a crash occurs during startup, the script still proceeds to register keybindings so the user doesn't lose control.

### 2. Defensive TSV Loading (`load_anki_tsv`)
- **Missing File**: Explicitly set `FSM.ANKI_HIGHLIGHTS = {}` when `io.open` fails.
- **Header Protection**: Dynamically detect headers using the configured `term` field name from `anki_mapping.ini`.
- **Parsing Safety**: Wrap the record parsing loop in a `pcall` to handle malformed lines (e.g., junk bytes from a partial clear).

### 3. Drum Window Visibility & Feedback (`cmd_toggle_drum_window`)
- Explicitly check if subtitles are loaded. If `#Tracks.pri.subs == 0`, show a clear OSD message and **prevent** opening the blank window.
- Force a `load_anki_tsv(true)` refresh when opening to catch deletions that happened while mpv was paused.

## Success Criteria
- Deleting the TSV file should result in all highlights vanishing from the player immediately or upon next DW toggle.
- Clearing the TSV to 0 bytes should result in no highlights.
- The script should never "disappear" (keys stopped working) regardless of file state.
- Pressing `w` when subs are missing should show a helpful error message instead of a blank screen.
