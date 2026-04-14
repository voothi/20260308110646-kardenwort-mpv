# Design: Robust Startup and State Recovery

## Root Cause Analysis

Three independent failure modes combine to produce the "blank/dead script" symptom:

```
┌──────────────────────────────────────────────────────────────────┐
│  USER DELETES OR CLEARS TSV FILE                                │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────┐   ┌──────────────────────────────┐
│  FAILURE A: Stale Memory     │   │  FAILURE B: Header Pollution │
│                              │   │                              │
│  load_anki_tsv: io.open      │   │  If TSV has only a header,   │
│  fails → returns nil         │   │  "Quotation" (the term col)  │
│  ANKI_HIGHLIGHTS stays full  │   │  is NOT in the hardcoded     │
│  → phantom highlights shown  │   │  filter list, so it loads as │
│                              │   │  a real word to highlight.   │
└──────────────────────────────┘   └──────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│  FAILURE C: Ghost Window ("blank screen/no messages")           │
│                                                                  │
│  The 5-second periodic timer is already pcall-wrapped.          │
│  BUT: the initial call at startup via mp.observe_property is NOT.│
│                                                                  │
│  update_media_state() is called by the observer callback.       │
│  That callbacks calls load_anki_tsv() without pcall.            │
│  If load_anki_tsv() crashes (e.g. invalid path encoding on      │
│  Windows), the callback throws — but mp.observe_property does   │
│  NOT re-register it. The entire observer is silently dropped.   │
│  The track-list is never re-read: Tracks.pri.subs stays {}.     │
│                                                                  │
│  Then user presses 'w' → cmd_toggle_drum_window()               │
│  → MEDIA_STATE != NO_SUBS (still default, not re-set)           │
│  → Tracks.pri.path might be set but subs == []                  │
│  → get_center_index returns nil or 1                            │
│  → tick_dw renders 0 lines → blank OSD                         │
└──────────────────────────────────────────────────────────────────┘
```

## Architecture Changes

### Change 1 — Wrap `update_media_state` call in observers (lines 3875-3882)

The three `mp.observe_property` callbacks that call `update_media_state` must each wrap
the call in a `pcall` so that any crash inside the function does not kill the observer:

**Current code (line 3875-3882):**
```lua
mp.observe_property("sid", "number", update_media_state)
mp.observe_property("secondary-sid", "number", update_media_state)
mp.observe_property("track-list", "native", function()
    update_media_state()
    ...
end)
```

**Required change:**
```lua
mp.observe_property("sid", "number", function(name, val)
    pcall(update_media_state)
end)
mp.observe_property("secondary-sid", "number", function(name, val)
    pcall(update_media_state)
end)
mp.observe_property("track-list", "native", function()
    pcall(update_media_state)
    if Options.font_scaling_enabled then
        pcall(update_font_scale)
    end
end)
```

### Change 2 — Fix `load_anki_tsv` stale-state bug (line 1133)

**Current code (line 1132-1133):**
```lua
local f = io.open(tsv_path, "r")
if not f then return end  -- BUG: leaves stale ANKI_HIGHLIGHTS intact
```

**Required change:**
```lua
local f = io.open(tsv_path, "r")
if not f then
    FSM.ANKI_HIGHLIGHTS = {}  -- clear stale highlights
    mp.msg.verbose("load_anki_tsv: file not found, cleared: " .. tostring(tsv_path))
    return
end
```

### Change 3 — Fix header detection in `load_anki_tsv` (line 1171)

The header filter must use the actual configured field name, not just hardcoded strings.
After the column indices are resolved (lines 1138-1146), the field name at `term_col` is
the header value for the term column. Add one line:

**After line 1146 (the end of the column-resolution loop), add:**
```lua
-- Capture the header name for the term column dynamically
local term_header_name = config.fields[term_col]  -- e.g. "Quotation", "Term", etc.
```

**Current filter code (line 1171):**
```lua
if term and term ~= "" and term ~= "WordSource" and term ~= "Term" then
```

**Required change:**
```lua
local is_header = (term == "WordSource" or term == "Term"
                   or (term_header_name and term == term_header_name))
if term and term ~= "" and not is_header then
```

### Change 4 — Force-refresh TSV in `cmd_toggle_drum_window` (around line 3490)

When the user opens the Drum Window, force a `load_anki_tsv(true)` refresh immediately
before transitioning to `DOCKED` state, so mid-session file deletions are reflected
instantly rather than waiting for the next 5-second timer cycle.

**After the existing guard at line 3488 (after `if not Tracks.pri.path then ... end`), add:**
```lua
-- Force-refresh TSV to reflect any mid-session file deletion
load_anki_tsv(true)
```

> **Implementation Note:** The original design included a secondary subs guard
> (`if #Tracks.pri.subs == 0 then ... return end`) after the TSV refresh.
> This was **removed during testing** — it caused a regression where the window
> refused to open whenever the TSV was absent, because the system falsely correlated
> an empty highlights table with an empty subtitle set. The primary `NO_SUBS` guard
> at the function entry point is sufficient.

---

## Extra Hardening (Added During Implementation)

During debugging it became clear that the script was failing silently with zero console
output. Three additional changes were necessary to diagnose and fix the root cause:

### Extra 1 — TSV Auto-Creation

When `io.open(tsv_path, "r")` returns nil (file missing), instead of only clearing
highlights and returning, the script now attempts to **create** a fresh `.tsv` file
with a default header row (`Term\tSentence\tTime`).

This prevents cascading nil-reference errors in downstream callers that assume a
valid file always exists after the first write, and also gives the user a visible
artifact confirming the script is running.

### Extra 2 — Loud Initialization Markers

Two `print()` calls were added at script load time:
- `[LLS] SCRIPT INITIALIZING...` — at the top of the initialization block
- `[LLS] SCRIPT LOADED SUCCESSFULLY` — at the very end of the file

`mp.msg.*` calls are filtered by mpv's log level and were not reliably appearing in
the terminal. `print()` writes directly to stdout and is always visible, making it
possible to confirm script execution without changing any mpv flags.

### Extra 3 — `print()` for All Observer Error Handlers

All `mp.msg.error` calls inside `pcall` error handlers in the observer callbacks were
replaced with `print()`. This was the primary reason no diagnostic output appeared
during the investigation — mpv was suppressing the log messages based on log level.
