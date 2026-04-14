# Analysis Dossier: Regression Review Phase 2 (Material Preparation)

## 1. Context Summary
- **Target Commits**: `11bf3ac6a93b` -> `704a49e02578`
- **Scope**: Stability fixes for TSV recovery and UI initialization.
- **Primary File**: `scripts/lls_core.lua`

## 2. Full Git Diff (lls_core.lua)

```patch
--- a/scripts/lls_core.lua
+++ b/scripts/lls_core.lua
@@ -2,6 +2,8 @@ local mp = require 'mp'
 local utils = require 'mp.utils'
 local options = require 'mp.options'
 
+print("[LLS] SCRIPT INITIALIZING (u:\\voothi\\20260308110646-kardenwort-mpv\\scripts\\lls_core.lua)")
+
 -- =========================================================================
 -- LLS CORE CONFIGURATION
 -- =========================================================================
@@ -1130,7 +1132,25 @@ local function load_anki_tsv(force)
     end
 
     local f = io.open(tsv_path, "r")
-    if not f then return end
+    if not f then
+        FSM.ANKI_HIGHLIGHTS = {}
+        print("[LLS] TSV file missing - attempting auto-creation: " .. tostring(tsv_path))
+        
+        -- Try to create a fresh one with a header
+        local wf = io.open(tsv_path, "w")
+        if wf then
+            wf:write("Term\tSentence\tTime\n")
+            wf:close()
+            f = io.open(tsv_path, "r") -- Try to open the newly created file
+            if not f then 
+                print("[LLS] TSV creation failed - path may be read-only")
+                return 
+            end
+        else
+            print("[LLS] TSV creation failed - could not open for writing")
+            return 
+        end
+    end
 
     local new_highlights = {}
     local config = load_anki_mapping_ini()
@@ -1144,6 +1164,10 @@ local function load_anki_tsv(force)
             elseif src == "time" then time_col = i end
         end
     end
+    local term_header_name = nil
+    if config.fields and term_col and config.fields[term_col] then
+        term_header_name = config.fields[term_col]
+    end
 
     for line in f:lines() do
         if not line:match("^#") then
@@ -1168,7 +1192,9 @@ local function load_anki_tsv(force)
                 end
                 
                 -- Don't load headers or empty terms
-                if term and term ~= "" and term ~= "WordSource" and term ~= "Term" then
+                local is_header = (term == "WordSource" or term == "Term"
+                                   or (term_header_name and term == term_header_name))
+                if term and term ~= "" and not is_header then
                     table.insert(new_highlights, { term = term, context = context, time = time_val })
                 end
             end
@@ -3478,6 +3504,8 @@ function cmd_toggle_search()
 end
 
 function cmd_toggle_drum_window()
+    print("[LLS] TOGGLE CALLED: FSM.DRUM_WINDOW=" .. tostring(FSM.DRUM_WINDOW))
+    local ok, err = pcall(function()
     if FSM.MEDIA_STATE == "NO_SUBS" then
         show_osd("Drum Window: No subtitles loaded")
         return
@@ -3488,6 +3516,10 @@ function cmd_toggle_drum_window()
     end
 
     if FSM.DRUM_WINDOW == "OFF" then
+        -- Refresh TSV before opening: catches any mid-session file deletion or clearing.
+        -- The periodic timer runs every 5s, so this ensures instant sync on user action.
+        load_anki_tsv(true)
+
         FSM.DRUM_WINDOW = "DOCKED"
         manage_ui_border_override(true)
         
@@ -3534,6 +3566,11 @@ function cmd_toggle_drum_window()
 
         -- show_osd("Drum Window: CLOSED")
     end
+    end)
+    if not ok then
+        print("[LLS ERROR] Drum Window Toggle: " .. tostring(err))
+        show_osd("LLS ERROR: Check console")
+    end
 end
 
 function toggle_book_mode()
@@ -3872,17 +3909,26 @@ end
 -- SYSTEM EVENTS
 -- =========================================================================
 
-mp.observe_property("sid", "number", update_media_state)
-mp.observe_property("secondary-sid", "number", update_media_state)
+mp.observe_property("sid", "number", function(name, val)
+    local ok, err = pcall(update_media_state)
+    if not ok then print("[LLS ERROR] sid observer: " .. tostring(err)) end
+end)
+mp.observe_property("secondary-sid", "number", function(name, val)
+    local ok, err = pcall(update_media_state)
+    if not ok then print("[LLS ERROR] sec-sid observer: " .. tostring(err)) end
+end)
 mp.observe_property("track-list", "native", function()
-    update_media_state()
+    local ok, err = pcall(update_media_state)
+    if not ok then print("[LLS ERROR] track-list observer: " .. tostring(err)) end
     if Options.font_scaling_enabled then
-        update_font_scale()
+        local ok2, err2 = pcall(update_font_scale)
+        if not ok2 then print("[LLS ERROR] font-scaling: " .. tostring(err2)) end
     end
 end)
 mp.observe_property("osd-dimensions", "native", function()
     if Options.font_scaling_enabled then
-        update_font_scale()
+        local ok, err = pcall(update_font_scale)
+        if not ok then print("[LLS ERROR] osd-dim observer: " .. tostring(err)) end
     end
 end)
 
@@ -3923,13 +3969,15 @@ end)
 
 if Options.anki_sync_period > 0 then
     mp.add_periodic_timer(Options.anki_sync_period, function()
-        pcall(function()
+        local ok, err = pcall(function()
             load_anki_tsv(true)
             drum_osd:update()
             if dw_osd then dw_osd:update() end
         end)
+        if not ok then print("[LLS ERROR] periodic sync: " .. tostring(err)) end
     end)
 end
+print("[LLS] SCRIPT LOADED SUCCESSFULLY")
```

## 3. Critical Observations for Phase 2

### Red Flags / Edge Cases Identified in Phase 1:
1.  **Hardcoded Headers**: `wf:write("Term\tSentence\tTime\n")`. If the user has a custom Anki mapping where the "Term" column is named differently, this template might be rejected or cause mismatches in subsequent loads until the user manually fixes it.
2.  **Toggle Performance**: `load_anki_tsv(true)` is now called synchronously on every Drum Window toggle. If the TSV file becomes very large (>1MB), there may be a noticeable hitch (UI freeze) when opening the window.
3.  **State Rollback**: If `cmd_toggle_drum_window` fails inside the `pcall`, `FSM.DRUM_WINDOW` might have already been set to `DOCKED`. If the window creation fails, the script will think the window is open when it isn't, potentially breaking future toggle calls.
4.  **Observer Spam**: `osd-dimensions` can fire rapidly during window resizing. The `pcall` + `print` overhead is small but could accumulate if there's a permanent error condition during resize.

## 4. Current Configuration
- `anki_mapping.ini` content (need to check if present).
- `mpv.conf` options (need to check for `anki_sync_period`).
