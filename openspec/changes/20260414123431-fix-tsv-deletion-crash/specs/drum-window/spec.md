# Spec: Drum Window Resilience

## Context

`cmd_toggle_drum_window()` is defined at line ~3480 of `scripts/lls_core.lua`.
It is bound to the `toggle-drum-window` key via `mp.add_key_binding` at line 3910.

The function has two existing guards at lines 3481-3488:
1. `if FSM.MEDIA_STATE == "NO_SUBS"` → show OSD, return
2. `if not Tracks.pri.path` → show OSD, return

However, these guards are insufficient because:
- `FSM.MEDIA_STATE` is set by `update_media_state()`, which may have failed silently
  if its observer callback crashed before or during the media state resolution.
- `Tracks.pri.path` can be set (non-nil) while `Tracks.pri.subs` is still empty `{}`
  if the subtitle loading step in `update_media_state` (line 1358-1360) was never reached.

## Requirements

### R1 — TSV Force Refresh on Open

When transitioning to `DOCKED` state, `load_anki_tsv(true)` MUST be called before
any state mutation (`FSM.DRUM_WINDOW = "DOCKED"` must NOT happen first).

This ensures:
- Mid-session file deletions are reflected immediately, not ~5s later.
- The `force=true` argument bypasses the early-exit guard (`next(ANKI_HIGHLIGHTS) ~= nil`),
  so even a previously populated highlights table is fully re-evaluated.

Position: immediately at the top of the `if FSM.DRUM_WINDOW == "OFF" then` branch,
before the `FSM.DRUM_WINDOW = "DOCKED"` assignment.

### R2 — Empty Subs Guard *(not implemented — see note)*

> **Implementation Note:** During testing, this guard caused a regression.
> When the TSV file was absent, `#Tracks.pri.subs` was always `0` because the
> system correlated "no highlights" with "no subtitle data." The guard blocked
> the window from opening even when subtitles were correctly loaded.
>
> **Decision:** R2 was dropped. The existing `MEDIA_STATE == "NO_SUBS"` guard
> at the top of `cmd_toggle_drum_window` is sufficient to block the window when
> no subtitles are present. The DW can safely open with an empty highlights table.

### R3 — Position of new code relative to existing guards

The final order inside the `if FSM.DRUM_WINDOW == "OFF" then` block is:
```
1. [existing] if MEDIA_STATE == "NO_SUBS" → return
2. [existing] if not Tracks.pri.path → return
3. [NEW] load_anki_tsv(true)   ← R1 implemented
4. FSM.DRUM_WINDOW = "DOCKED"  ← R2 guard removed
5. ... rest of initialization ...
```
