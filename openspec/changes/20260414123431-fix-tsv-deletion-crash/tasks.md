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

- [ ] 1.1 Make this replacement
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

- [ ] 2.1 Make this replacement

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

- [ ] 3.1 Add `local term_header_name = config.fields[term_col]` after the loop
- [ ] 3.2 Replace the filter condition with the `is_header` variable check

---

## Task 4 — Add TSV refresh + subs guard to `cmd_toggle_drum_window`

**File:** `scripts/lls_core.lua`
**Location:** Inside `cmd_toggle_drum_window`, inside the `if FSM.DRUM_WINDOW == "OFF"` branch

**Find this exact line (line 3490):**
```lua
    if FSM.DRUM_WINDOW == "OFF" then
        FSM.DRUM_WINDOW = "DOCKED"
```

**Replace with:**
```lua
    if FSM.DRUM_WINDOW == "OFF" then
        -- Refresh TSV before opening: catches any mid-session file deletion or clearing.
        -- The periodic timer runs every 5s, so this ensures instant sync on user action.
        load_anki_tsv(true)

        -- Secondary subs guard: MEDIA_STATE may say subs are loaded, but if the observer
        -- callback failed earlier, Tracks.pri.subs can still be empty. An empty subs
        -- table causes tick_dw to render nothing and the window appears blank.
        if #Tracks.pri.subs == 0 then
            show_osd("Drum Window: Subtitles not loaded yet")
            return
        end

        FSM.DRUM_WINDOW = "DOCKED"
```

**Why:**
- `load_anki_tsv(true)` with `force=true` bypasses the `next(ANKI_HIGHLIGHTS) ~= nil`
  early-exit guard. Even if highlights are non-empty (stale), this forces a full re-read.
- The `#Tracks.pri.subs == 0` guard prevents the window from entering `DOCKED` state
  with no subtitle data. Without this, `tick_dw` renders zero lines → blank OSD.
- The existing guard at line 3481 (`FSM.MEDIA_STATE == "NO_SUBS"`) is not sufficient
  because `MEDIA_STATE` can be stale if the earlier observer crash happened.

- [ ] 4.1 Make this replacement

---

## Task 5 — Verification

- [ ] 5.1 **Scenario A — File never existed**: Open a video with NO `.tsv` file present.
  Expected: Script loads normally. All keys (`w`, `q`, etc.) work. No blank window.

- [ ] 5.2 **Scenario B — File deleted mid-session**: Open video, open DW, add a word (TSV created).
  Then delete the `.tsv` file while mpv is running. Wait 6 seconds (one timer cycle).
  Expected: The highlight on the word disappears from the DW within ~5s.

- [ ] 5.3 **Scenario C — File cleared to 0 bytes**: Open video with an existing `.tsv` file.
  Open the file in an editor and delete all content (save as empty). Wait 6 seconds.
  Expected: All highlights disappear. No "Quotation" phantom highlight.

- [ ] 5.4 **Scenario D — Press 'w' with observer crash simulated**: Check mpv log for
  any `pcall` error messages after starting mpv. Confirm script still operational.
