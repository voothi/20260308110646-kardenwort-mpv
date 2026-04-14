# Tasks: Fixing TSV Deletion and Drum Window Hang

## Task 1 — Protect observer callbacks with `pcall`

**File:** `scripts/lls_core.lua`
**Location:** Lines 3875–3882 (the `-- SYSTEM EVENTS` block)

Replace the three `mp.observe_property` calls that reference `update_media_state`
with wrapped versions that use `pcall`. This prevents an error inside `update_media_state`
(e.g. from a bad path or malformed TSV) from silently killing the observer callback and
leaving `Tracks.pri.subs` empty for the rest of the session.

**Find this block:**
```lua
mp.observe_property("sid", "number", update_media_state)
mp.observe_property("secondary-sid", "number", update_media_state)
mp.observe_property("track-list", "native", function()
    update_media_state()
    if Options.font_scaling_enabled then
        update_font_scale()
    end
end)
```

**Replace with:**
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

**Why:** `mp.observe_property` with a direct function reference passes the property
name and value as arguments to that function. `update_media_state` ignores its arguments,
but if the function *itself* throws a Lua error, mpv silently drops the callback and
never calls it again. Wrapping in `pcall` catches the error and keeps the observer alive.

- [x] 1.1 Make this replacement
- [ ] 1.2 Verify: check mpv log at `--log-level=verbose` — the phrase "load_anki_tsv" should appear in the log on startup without crashing mpv

---

## Task 2 — Clear stale highlights when TSV file is missing

**File:** `scripts/lls_core.lua`
**Location:** Line 1133 inside `load_anki_tsv`

**Find this exact line:**
```lua
    if not f then return end
```
(It appears immediately after `local f = io.open(tsv_path, "r")` on line 1132.)

**Replace with:**
```lua
    if not f then
        FSM.ANKI_HIGHLIGHTS = {}
        mp.msg.verbose("load_anki_tsv: file not found, cleared: " .. tostring(tsv_path))
        return
    end
```

**Why:** The original code returns without modifying `FSM.ANKI_HIGHLIGHTS`. If the file
was deleted while mpv was running, the old highlight data stays in memory forever. The
5-second periodic timer calls `load_anki_tsv(true)`, but the missing file makes it return
immediately, so highlights are never cleared. After this fix, missing file = empty highlights.

- [x] 2.1 Make this replacement

---

## Task 3 — Fix dynamic header detection

**File:** `scripts/lls_core.lua`
**Location:** Inside `load_anki_tsv`, after line 1146 (the closing `end` of the
column-index resolution loop) and at line 1171 (the header filter condition)

**Step 3a — Capture the configured header name:**

Find this block (lines 1138-1146):
```lua
    local term_col, ctx_col, time_col = 1, 2, 3
    if #config.fields > 0 then
        for i, fld in ipairs(config.fields) do
            local src = config.mapping[fld]
            if src == "source_word" then term_col = i
            elseif src == "source_sentence" then ctx_col = i
            elseif src == "time" then time_col = i end
        end
    end
```

**Add one line immediately after the closing `end` of that block:**
```lua
    local term_header_name = config.fields[term_col]
```

**Step 3b — Use the dynamic name in the filter:**

Find this line (line 1171):
```lua
                if term and term ~= "" and term ~= "WordSource" and term ~= "Term" then
```

**Replace with:**
```lua
                local is_header = (term == "WordSource" or term == "Term"
                                   or (term_header_name and term == term_header_name))
                if term and term ~= "" and not is_header then
```

**Why:** In the user's `anki_mapping.ini`, the "source_word" field is named `"Quotation"`
(or another custom name). When the TSV file exists but contains only the header row
(written by `save_anki_tsv_row` when the file is freshly created), the word `"Quotation"`
is read as column 1 of that row and passes the hardcoded filter `term ~= "WordSource"
and term ~= "Term"`. It then gets added to `ANKI_HIGHLIGHTS` as a fake word. This fix
compares against the actual configured name so the header is always skipped.

- [x] 3.1 Add `local term_header_name = config.fields[term_col]` after the loop
- [x] 3.2 Replace the filter condition with the `is_header` variable check

---

## Task 4 — Add TSV refresh to `cmd_toggle_drum_window`

**File:** `scripts/lls_core.lua`
**Location:** Inside `cmd_toggle_drum_window`, inside the `if FSM.DRUM_WINDOW == "OFF"` branch

Added `load_anki_tsv(true)` force-refresh at the top of the `OFF → DOCKED` branch so that
mid-session file deletions are reflected immediately when the user opens the window.

> **Note:** The `#Tracks.pri.subs == 0` guard from the original design was **not** kept.
> Testing revealed it incorrectly blocked the window from opening whenever the TSV file
> was absent (even though subtitles were loaded), because the system associated an empty
> highlights table with "no data to show." The primary `NO_SUBS` guard at the start of
> the function is sufficient.

- [x] 4.1 Added `load_anki_tsv(true)` before `FSM.DRUM_WINDOW = "DOCKED"`
- [x] 4.2 Wrapped `cmd_toggle_drum_window` body in `pcall` — errors now logged via `print()` instead of crashing silently

---

## Task 5 — Extra Hardening (added during implementation)

During debugging, the root cause was traced to the script loading silently with no
output — making it impossible to determine whether the script was running at all.
The following additional changes were made beyond the original plan:

### 5.1 — TSV Auto-Creation

**File:** `scripts/lls_core.lua` — inside `load_anki_tsv`

If `io.open` returns `nil` (file missing), the script now attempts to **create** a fresh
`.tsv` file with a default header row (`Term\tSentence\tTime`). This ensures subsequent
calls have a valid file to open and prevents cascading nil-reference errors.

- [x] 5.1.1 Added auto-creation block after the `if not f then` check

### 5.2 — Loud Initialization Logging

Added two `print()` statements at script load time:
- `[LLS] SCRIPT INITIALIZING...` — at the very top of the initialization block
- `[LLS] SCRIPT LOADED SUCCESSFULLY` — at the very end of the file

This allows the user to confirm via terminal that the script is being executed by mpv
at all, ruling out configuration or path errors before debugging internal logic.

- [x] 5.2.1 Added `print("[LLS] SCRIPT INITIALIZING...")` at script start
- [x] 5.2.2 Added `print("[LLS] SCRIPT LOADED SUCCESSFULLY")` at end of file

### 5.3 — `print()`-based Diagnostics for All Observers

Replaced `mp.msg.error` calls in observer callbacks with `print()` to bypass mpv's
internal log-level filtering. This was the primary reason diagnostic messages were
not appearing in the console during the investigation.

- [x] 5.3.1 Observer error handlers use `print()` instead of `mp.msg.error`

---

## Task 6 — Verification

- [x] 6.1 **Scenario A — File never existed**: Script loads normally. Keys (`w`, `q`, etc.) work.
  Auto-creation creates a fresh `.tsv` on first use. Window opens correctly.

- [ ] 6.2 **Scenario B — File deleted mid-session**: Delete `.tsv` while mpv is running.
  Wait ~6s. Expected: highlights disappear from the DW.

- [ ] 6.3 **Scenario C — File cleared to 0 bytes**: Clear `.tsv` in editor, wait ~6s.
  Expected: All highlights disappear. No phantom "Quotation" highlight.

- [ ] 6.4 **Scenario D — Observer pcall coverage**: Check mpv terminal for `[LLS] SCRIPT LOADED SUCCESSFULLY`
  on startup. Confirms script is running. Any observer errors appear as `[LLS ERROR] ...` lines.
