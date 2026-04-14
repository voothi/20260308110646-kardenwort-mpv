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

### R2 — Empty Subs Guard

After the TSV refresh (R1), the function MUST check `#Tracks.pri.subs == 0`.
If true:
1. Call `show_osd("Drum Window: Subtitles not loaded yet")`
2. `return` — do NOT transition to DOCKED

**Why this matters:** `tick_dw` (the rendering function) calls `dw_build_layout`
which iterates `Tracks.pri.subs`. If the table is empty, it renders zero lines.
The `dw_osd.data` is set to an ASS string with only the background box, no text.
The user sees what appears to be a frozen or blank application with none of the
familiar keyboard shortcuts working (because those bindings ARE registered — but
they operate on empty data and produce no visible output).

### R3 — Position of new guard relative to existing guards

The new code must come AFTER the two existing guards (the `NO_SUBS` and `path` checks)
and BEFORE the `FSM.DRUM_WINDOW = "DOCKED"` line.

Final order inside the `if FSM.DRUM_WINDOW == "OFF" then` block:
```
1. [existing] if MEDIA_STATE == "NO_SUBS" → return
2. [existing] if not Tracks.pri.path → return
3. [NEW] load_anki_tsv(true)
4. [NEW] if #Tracks.pri.subs == 0 → return
5. FSM.DRUM_WINDOW = "DOCKED"
6. ... rest of initialization ...
```
