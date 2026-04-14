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

### Change 4 — Add subs guard + force-refresh in `cmd_toggle_drum_window` (around line 3490)

The DW should not proceed to `DOCKED` state if there are no subtitle lines in memory.
This is a secondary safeguard (the primary guard at line 3481 catches `NO_SUBS` state),
but `Tracks.pri.subs` can be empty even when `MEDIA_STATE` is set, if the observer
callback failed and subs were never loaded.

Additionally, force-refresh the TSV state immediately before opening, so a mid-session
file deletion is reflected at the exact moment the user opens the window.

**After the existing guard at line 3488 (after `if not Tracks.pri.path then ... end`), add:**
```lua
-- Force-refresh TSV to reflect any mid-session file deletion
load_anki_tsv(true)

-- Guard: if subs failed to load (observer crash), DW cannot render anything useful
if #Tracks.pri.subs == 0 then
    show_osd("Drum Window: Subtitles not loaded yet")
    return
end
```
