## Context
Currently, `cmd_copy_sub` and `cmd_dw_copy` use different sources for subtitle text. `cmd_copy_sub` relies on native `mpv` properties which are suppressed during OSD rendering. This leads to a failure in copying text when Context Copy is disabled in Regular/White-Subtitles mode.

## Goals / Non-Goals

**Goals:**
- Unify the source of subtitle text for all copy operations.
- Ensure `cmd_copy_sub` works correctly regardless of native subtitle visibility.
- Fix the logic that results in `No subtitle to copy` when internal data is actually available.

**Non-Goals:**
- Changing the existing language filtering logic (`COPY_MODE A/B`).
- Altering the Drum Window selection logic (which is already robust).

## Decisions

### 1. Unified Text Extraction
We will introduce a helper function `get_active_sub_text()` (or similar) that checks `Tracks.pri.subs` and `Tracks.sec.subs` using the current playback time. This ensures that the logic used to *render* the subtitles is the same logic used to *copy* them.

### 2. Priority-Based Sourcing
The extraction logic will follow this order:
1. Internal tracks (if loaded and valid).
2. Native properties (as a fallback for external files not yet indexed).
3. Context Copy logic (if enabled).

### 3. Whitespace Fix
Correct the string concatenation at L5802 to ensure `ctext` remains `""` if both primary and secondary sources are empty, rather than becoming `"\n"`.

## Risks / Trade-offs

- **Memory/CPU**: Eager loading of subtitles is already a requirement of the system, so using the internal table adds negligible overhead compared to `mp.get_property`.
- **Sync**: Using internal tables ensures perfect sync with what the user sees on the OSD, whereas native properties can sometimes lag or reflect different tracks if not carefully managed.
