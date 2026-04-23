## Context

The default mpv behavior links both tracks to the same positional adjustment or requires complex property-setting. This release simplifies the process by exposing the `secondary-sub-pos` property directly to hotkeys and ensuring those hotkeys work regardless of the user's active keyboard layout.

## Goals / Non-Goals

**Goals:**
- Provide independent vertical control for secondary subtitles.
- Ensure `r/t` commands work in both English and Russian layouts.
- Maintain manual position offsets through Drum Mode toggles.

## Decisions

- **Secondary Mapping**: `Shift+R` is mapped to `add secondary-sub-pos -1` and `Shift+T` to `add secondary-sub-pos 1` in `input.conf`.
- **Layout Mirroring**:
    - `r` / `t` (Primary sub-pos) mapped to `к` / `е`.
    - `R` / `T` (Secondary sub-pos) mapped to `К` / `Е`.
- **State Persistence**: The script logic in `lls_core.lua` is updated to respect the current native `sub-pos` and `secondary-sub-pos` properties when calculating context line offsets in Drum Mode.

## Risks / Trade-offs

- **Risk**: Overcrowding `input.conf` with layout-specific mappings.
- **Mitigation**: These mappings are restricted to high-frequency study controls where layout-switching friction is most disruptive.
