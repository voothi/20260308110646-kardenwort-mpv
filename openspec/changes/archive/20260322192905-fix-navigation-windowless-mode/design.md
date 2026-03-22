# Design: Fix Navigation in Windowless Mode

## Overview
This design aims to unify subtitle navigation logic by making the reliable `cmd_dw_seek_delta` function available globally through script-bindings.

## Components

### 1. `lls_core.lua` (Script Bindings)
We will export the existing seeking logic at the end of the script (where other bindings are defined).

- **New Bindings**:
  - `lls-seek_prev`: Calls `cmd_dw_seek_delta(-1)`.
  - `lls-seek_next`: Calls `cmd_dw_seek_delta(1)`.

### 2. `input.conf` (Global Bindings)
We will update the default key-mappings to point to our custom script-bindings instead of the native `sub-seek` command.

| Key | Old Command | New Command |
| --- | --- | --- |
| `a` | `sub-seek -1` | `script-binding lls-seek_prev` |
| `d` | `sub-seek 1` | `script-binding lls-seek_next` |
| `ф` | `sub-seek -1` | `script-binding lls-seek_prev` |
| `в` | `sub-seek 1` | `script-binding lls-seek_next` |

## Data Flow
1. User presses `d`.
2. mpv triggers `script-binding lls-seek_next`.
3. `lls_core.lua` executes `cmd_dw_seek_delta(1)`.
4. The script identifies the next subtitle start time from `Tracks.pri.subs`.
5. The script issues `seek <time> absolute+exact`.
6. Playback jumps instantly to the start of the next phrase.

## Considerations
- **Internal State**: The `cmd_dw_seek_delta` function resets `FSM.DW_CURSOR_WORD` to `-1`. This is beneficial even in windowless mode, as it ensures that if the user subsequently opens the Drum Window, the pointer starts fresh.
- **Autopause Compatibility**: This fix directly addresses the race condition between `sub-seek` and the "pause-at-padding" threshold.
