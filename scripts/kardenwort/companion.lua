-- ===============================================================================
-- companion.lua — Companion audio/subtitle/video track selection for kardenwort
-- Contains the language-postfix family, path canonicalization, and the
-- ensure_companion_* / get_companion_* / select_companion_* functions.
-- cmd_cycle_audio and cmd_cycle_sec_sid stay in main.lua (carve-out: they are
-- general playback commands, not companion-internal).
-- Reads FSM/Options/Diagnostic at call time via injected references.
-- ===============================================================================

local mp = require 'mp'
local utils = require 'mp.utils'

local M = {}

local FSM, Options, Diagnostic

function M.init(fsm, opts, diagnostic)
    assert(fsm, "FATAL: fsm dependency missing")
    assert(opts, "FATAL: opts dependency missing")
    assert(diagnostic, "FATAL: diagnostic dependency missing")
    FSM = fsm
    Options = opts
    Diagnostic = diagnostic
end

-- --- language-postfix family (zero external callers) ----------------------

function M.normalize_language_postfix(postfix)
    if not postfix or postfix == "" then return nil end
    return postfix:gsub("_", "-")
end

function M.is_language_postfix(postfix)
    local normalized = M.normalize_language_postfix(postfix)
    if not normalized or not normalized:match("^[%a%d-]+$") then return false end

    local parts = {}
    for part in normalized:gmatch("[^-]+") do
        table.insert(parts, part)
    end
    if #parts == 0 then return false end

    local primary = parts[1]
    if not primary:match("^[%a][%a][%a]?$") then
        return false
    end

    for idx = 2, #parts do
        local part = parts[idx]
        if not (
            part:match("^%a%a$") or
            part:match("^%a%a%a$") or
            part:match("^%a%a%a%a$") or
            part:match("^%d%d%d$")
        ) then
            return false
        end
    end

    return true
end

function M.split_base_and_language_postfix(stem)
    if not stem or stem == "" then return nil, nil end
    local base, postfix = stem:match("^(.+)%.([%w%-_]+)$")
    if base and M.is_language_postfix(postfix) then
        return base, M.normalize_language_postfix(postfix)
    end
    return stem, nil
end

function M.format_language_postfix_label(postfix)
    local normalized = M.normalize_language_postfix(postfix)
    if not normalized then return nil end
    return normalized:upper()
end

function M.extract_lang_from_title_or_path(title, path)
    local filepath = (path and path ~= "") and path or title
    if not filepath or filepath == "" then return nil end
    filepath = filepath:gsub("\\", "/")
    local filename = filepath:match("([^/]+)$") or filepath

    if M.is_language_postfix(filename) then
        return M.format_language_postfix_label(filename)
    end

    local ext = filename:match("%.([^%.]+)$") or ""
    if ext ~= "" then
        local filename_no_ext = filename:sub(1, #filename - #ext - 1)
        if M.is_language_postfix(filename_no_ext) then
            return M.format_language_postfix_label(filename_no_ext)
        end

        local _, postfix = M.split_base_and_language_postfix(filename_no_ext)
        if postfix then
            return M.format_language_postfix_label(postfix)
        end
    end

    return nil
end

-- --- path canonicalization -------------------------------------------------

function M.normalize_path_for_compare(path)
    if not path or path == "" then return "" end
    local normalized = path:gsub("\\", "/")
    if package.config:sub(1,1) == "\\" then
        normalized = normalized:lower()
    end
    return normalized
end

function M.canonicalize_local_path(path)
    if not path or path == "" then return "" end
    local normalized = path
    local ok, expanded = pcall(mp.command_native, {"expand-path", path})
    if ok and type(expanded) == "string" and expanded ~= "" then
        normalized = expanded
    end
    local ok2, canonical = pcall(mp.command_native, {"normalize-path", normalized})
    if ok2 and type(canonical) == "string" and canonical ~= "" then
        normalized = canonical
    end
    return M.normalize_path_for_compare(normalized)
end

-- --- companion audio -------------------------------------------------------

function M.ensure_companion_audio_tracks(path)
    if Options.companion_audio_enabled == false then return end
    if not path or path == "" then return end
    local normalized_path = path:gsub("\\", "/")
    local dir = normalized_path:match("^(.*/)") or ""
    local filename = normalized_path:sub(#dir + 1)
    local ext = filename:match("%.([^%.]+)$") or ""
    if ext == "" then return end

    local filename_no_ext = filename:sub(1, #filename - #ext - 1)
    local base_prefix = M.split_base_and_language_postfix(filename_no_ext)
    if not base_prefix or base_prefix == "" then return end

    local companions = M.get_companion_files(dir, base_prefix, ext)
    if #companions <= 1 then return end

    local current_path_norm = M.canonicalize_local_path(path)
    local existing_audio = {}
    local tracks = mp.get_property_native("track-list") or {}
    for _, t in ipairs(tracks) do
        if t.type == "audio" and t.external then
            local p = t["external-filename"] or t["external_filename"] or ""
            existing_audio[M.canonicalize_local_path(p)] = true
        end
    end

    local is_windows = package.config:sub(1,1) == "\\"
    for _, companion in ipairs(companions) do
        if companion.postfix ~= "ORIGINAL" then
            local normalized_companion_path = M.canonicalize_local_path(companion.path)
            if normalized_companion_path ~= current_path_norm and not existing_audio[normalized_companion_path] then
                local load_path = companion.path
                if is_windows then
                    load_path = load_path:gsub("/", "\\")
                end
                mp.commandv("audio-add", load_path, "auto", companion.postfix, companion.raw_postfix)
            end
        end
    end

end

-- --- companion files / subtitles ------------------------------------------

function M.get_companion_files(dir, base_prefix, ext)
    local files = utils.readdir(dir, "files") or {}
    local companions = {}

    for _, f in ipairs(files) do
        local f_ext = f:match("%.([^%.]+)$")
        if f_ext and f_ext:lower() == ext:lower() then
            local f_no_ext = f:sub(1, #f - #f_ext - 1)
            if f_no_ext == base_prefix then
                table.insert(companions, {
                    path = dir .. f,
                    postfix = "ORIGINAL",
                    raw_postfix = ""
                })
            else
                local p_base, p_postfix = M.split_base_and_language_postfix(f_no_ext)
                if p_base == base_prefix and p_postfix then
                    table.insert(companions, {
                        path = dir .. f,
                        postfix = M.format_language_postfix_label(p_postfix),
                        raw_postfix = p_postfix
                    })
                end
            end
        end
    end

    table.sort(companions, function(a, b)
        return a.postfix < b.postfix
    end)

    return companions
end

function M.get_companion_subtitles(dir, base_prefix)
    local files = utils.readdir(dir, "files") or {}
    local sub_files = {}
    local sub_exts = { srt = true, ass = true, ssa = true, vtt = true }

    for _, f in ipairs(files) do
        local f_ext = f:match("%.([^%.]+)$")
        if f_ext and sub_exts[f_ext:lower()] then
            local f_no_ext = f:sub(1, #f - #f_ext - 1)
            if f_no_ext == base_prefix then
                table.insert(sub_files, {
                    path = dir .. f,
                    postfix = "ORIGINAL",
                    raw_postfix = ""
                })
            else
                local p_base, p_postfix = M.split_base_and_language_postfix(f_no_ext)
                if p_base == base_prefix and p_postfix then
                    table.insert(sub_files, {
                        path = dir .. f,
                        postfix = M.format_language_postfix_label(p_postfix),
                        raw_postfix = p_postfix
                    })
                end
            end
        end
    end

    table.sort(sub_files, function(a, b)
        return a.postfix < b.postfix
    end)

    return sub_files
end

function M.subtitle_track_matches_postfix(track, target_postfix)
    if not track or not target_postfix then return false end
    local target = target_postfix:lower()
    if track.lang and track.lang:lower() == target then return true end
    if track.title and track.title:lower() == target then return true end

    local path = track["external-filename"] or track["external_filename"] or ""
    if path ~= "" then
        local normalized_path = path:gsub("\\", "/")
        local filename = normalized_path:match("([^/]+)$") or normalized_path
        local ext = filename:match("%.([^%.]+)$") or ""
        if ext ~= "" then
            local filename_no_ext = filename:sub(1, #filename - #ext - 1)
            local _, path_postfix = M.split_base_and_language_postfix(filename_no_ext)
            if path_postfix and path_postfix:lower() == target then
                return true
            end
        end
    end

    return false
end

function M.select_companion_subtitle_tracks(current_postfix)
    local current_tracks = mp.get_property_native("track-list") or {}
    local sub_tracks = {}
    for _, t in ipairs(current_tracks) do
        if t.type == "sub" and t.external then
            table.insert(sub_tracks, t)
        end
    end
    if #sub_tracks == 0 then return end

    table.sort(sub_tracks, function(a, b)
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)

    local primary_sid = tonumber(mp.get_property("sid") or 0) or 0
    if current_postfix then
        for _, t in ipairs(sub_tracks) do
            local tid = tonumber(t.id)
            if tid and M.subtitle_track_matches_postfix(t, current_postfix) then
                primary_sid = tid
                mp.set_property_number("sid", tid)
                break
            end
        end
    elseif primary_sid == 0 and sub_tracks[1] then
        local tid = tonumber(sub_tracks[1].id)
        if tid then
            primary_sid = tid
            mp.set_property_number("sid", tid)
        end
    end

    local secondary_sid = tonumber(mp.get_property("secondary-sid") or 0) or 0
    if secondary_sid == 0 then
        for _, t in ipairs(sub_tracks) do
            local tid = tonumber(t.id)
            if tid and tid ~= primary_sid then
                mp.set_property_number("secondary-sid", tid)
                FSM.__auto_track_selected_sec = true
                break
            end
        end
    end
end

function M.ensure_companion_subtitle_tracks(path)
    if Options.companion_subtitle_enabled == false then return end
    if not path or path == "" then return end
    local normalized_path = path:gsub("\\", "/")
    local dir = normalized_path:match("^(.*/)") or ""
    local filename = normalized_path:sub(#dir + 1)
    local ext = filename:match("%.([^%.]+)$") or ""
    if ext == "" then return end

    local filename_no_ext = filename:sub(1, #filename - #ext - 1)
    local base_prefix, current_postfix = M.split_base_and_language_postfix(filename_no_ext)
    if not base_prefix or base_prefix == "" then return end

    local sub_files = M.get_companion_subtitles(dir, base_prefix)
    if #sub_files == 0 then return end

    local existing_subs = {}
    local tracks = mp.get_property_native("track-list") or {}
    for _, t in ipairs(tracks) do
        if t.type == "sub" and t.external then
            local p = t["external-filename"] or t["external_filename"] or ""
            if p ~= "" then
                existing_subs[M.canonicalize_local_path(p)] = true
            end
        end
    end

    local is_windows = package.config:sub(1,1) == "\\"
    for _, sub in ipairs(sub_files) do
        local normalized_sub_path = M.canonicalize_local_path(sub.path)
        if not existing_subs[normalized_sub_path] then
            local load_path = sub.path
            if is_windows then
                load_path = load_path:gsub("/", "\\")
            end

            local flag = "auto"
            if current_postfix and sub.raw_postfix:lower() == current_postfix:lower() then
                flag = "select"
            end
            mp.commandv("sub-add", load_path, flag, sub.postfix, sub.raw_postfix)
        end
    end

    M.select_companion_subtitle_tracks(current_postfix)
    mp.add_timeout(0.1, function()
        M.select_companion_subtitle_tracks(current_postfix)
    end)
end

-- --- companion video -------------------------------------------------------

function M.get_bundled_black_video_source()
    local script_dir = mp.get_script_directory()
    if script_dir and script_dir ~= "" then
        local candidate = script_dir:gsub("\\", "/") .. "/../_tools/sub-viewer/black.mp4"
        local ok, normalized = pcall(mp.command_native, {"normalize-path", candidate})
        if ok and type(normalized) == "string" and normalized ~= "" and utils.file_info(normalized) then
            return normalized
        end
        if utils.file_info(candidate) then
            return candidate
        end
    end

    return nil
end

function M.add_bundled_black_video_track(message)
    local source = M.get_bundled_black_video_source()
    if not source then
        Diagnostic.error(message .. " Bundled seekable black video track is unavailable: scripts/_tools/sub-viewer/black.mp4")
        return
    end
    Diagnostic.info(message .. " Using bundled seekable black video track.")
    mp.commandv("video-add", source, "select")
end

function M.try_next_video_candidate()
    FSM.current_candidate_idx = FSM.current_candidate_idx + 1
    local candidate = FSM.video_candidates[FSM.current_candidate_idx]
    if not candidate then
        Diagnostic.debug("try_next_video_candidate: no more candidates")
        local tracks = mp.get_property_native("track-list") or {}
        local has_real_video = false
        for _, t in ipairs(tracks) do
            if t.type == "video" and not t.albumart and not t.image then
                has_real_video = true
                break
            end
        end
        if not has_real_video then
            M.add_bundled_black_video_track("All companion video candidates failed to load.")
        end
        return
    end

    local tracks = mp.get_property_native("track-list") or {}
    for _, t in ipairs(tracks) do
        if t.type == "video" then
            Diagnostic.debug("try_next_video_candidate: already has video, skipping")
            return
        end
    end

    local is_windows = package.config:sub(1,1) == "\\"
    local load_path = candidate.path
    if is_windows then
        load_path = load_path:gsub("/", "\\")
    end

    Diagnostic.debug("try_next_video_candidate: adding candidate path=" .. load_path)
    mp.commandv("video-add", load_path, "select", candidate.postfix, candidate.raw_postfix)

    mp.add_timeout(0.2, function()
        local tracks_after = mp.get_property_native("track-list") or {}
        local found_video = false
        local video_track_id = nil
        local selected_video = false
        for _, t in ipairs(tracks_after) do
            if t.type == "video" then
                found_video = true
                video_track_id = t.id
                if t.selected then
                    selected_video = true
                end
                Diagnostic.debug("found video track id=" .. tostring(t.id) .. " selected=" .. tostring(t.selected))
            end
        end
        if found_video then
            if not selected_video and video_track_id then
                Diagnostic.debug("attempting to select video track id=" .. tostring(video_track_id))
                mp.set_property_number("vid", video_track_id)
                Diagnostic.debug("vid property now=" .. tostring(mp.get_property("vid")))
            else
                Diagnostic.debug("video already selected=" .. tostring(selected_video))
            end
        else
            Diagnostic.debug("no video track found, trying next candidate")
            M.try_next_video_candidate()
        end
    end)
end

function M.get_companion_video_files(dir, base_prefix)
    local video_files = {}
    local video_exts = { mp4 = true, mkv = true, avi = true, webm = true, flv = true, mov = true, wmv = true, mpg = true, mpeg = true }

    local function scan_video_dir(scan_dir, depth)
        local dir_files = utils.readdir(scan_dir, "files") or {}
        for _, f in ipairs(dir_files) do
            local f_ext = f:match("%.([^%.]+)$")
            if f_ext and video_exts[f_ext:lower()] then
                local f_no_ext = f:sub(1, #f - #f_ext - 1)
                if f_no_ext == base_prefix then
                    table.insert(video_files, {
                        path = scan_dir .. f,
                        postfix = "ORIGINAL",
                        raw_postfix = "",
                        _depth = depth,
                    })
                else
                    local p_base, p_postfix = M.split_base_and_language_postfix(f_no_ext)
                    if p_base == base_prefix and p_postfix then
                        table.insert(video_files, {
                            path = scan_dir .. f,
                            postfix = M.format_language_postfix_label(p_postfix),
                            raw_postfix = p_postfix,
                            _depth = depth,
                        })
                    end
                end
            end
        end
    end

    scan_video_dir(dir, 0)

    local subdirs = utils.readdir(dir, "dirs") or {}
    for _, sub in ipairs(subdirs) do
        scan_video_dir(dir .. sub .. "/", 1)
    end

    table.sort(video_files, function(a, b)
        if (a._depth or 0) ~= (b._depth or 0) then return (a._depth or 0) < (b._depth or 0) end
        if a.postfix == "ORIGINAL" then return true end
        if b.postfix == "ORIGINAL" then return false end
        return a.postfix < b.postfix
    end)

    return video_files
end

function M.ensure_companion_video_track(path)
    Diagnostic.debug("ensure_companion_video_track: called with path=" .. tostring(path))
    if Options.companion_video_enabled == false then
        Diagnostic.debug("ensure_companion_video_track: companion_video_enabled is false, returning")
        return
    end
    if not path or path == "" then
        Diagnostic.debug("ensure_companion_video_track: empty path, returning")
        return
    end

    local tracks = mp.get_property_native("track-list") or {}
    local has_real_video = false
    local selected_real_video = false
    local first_real_video_id = nil
    local has_album_art = false
    for _, t in ipairs(tracks) do
        if t.type == "video" then
            if t.albumart or t.image then
                has_album_art = true
            else
                has_real_video = true
                if not first_real_video_id then
                    first_real_video_id = t.id
                end
                if t.selected then
                    selected_real_video = true
                end
            end
        end
    end
    if has_album_art and not has_real_video then
        Diagnostic.debug("ensure_companion_video_track: only album art video present, deselecting vid")
        mp.set_property("vid", "no")
    end
    if selected_real_video then
        Diagnostic.debug("ensure_companion_video_track: real video track already selected, returning")
        return
    end
    if has_real_video then
        if first_real_video_id then
            Diagnostic.debug("ensure_companion_video_track: real video track exists but not selected. Selecting id=" .. tostring(first_real_video_id))
            mp.set_property_number("vid", first_real_video_id)
        end
        return
    end

    local normalized_path = path:gsub("\\", "/")
    local dir = normalized_path:match("^(.*/)") or ""
    local filename = normalized_path:sub(#dir + 1)
    local ext = filename:match("%.([^%.]+)$") or ""
    if ext == "" then
        Diagnostic.debug("ensure_companion_video_track: empty ext, returning")
        return
    end

    local filename_no_ext = filename:sub(1, #filename - #ext - 1)
    local base_prefix = M.split_base_and_language_postfix(filename_no_ext)
    if not base_prefix or base_prefix == "" then
        Diagnostic.debug("ensure_companion_video_track: empty base_prefix, returning")
        return
    end

    Diagnostic.debug("ensure_companion_video_track: searching in dir=" .. dir .. " base_prefix=" .. base_prefix)
    local video_files = M.get_companion_video_files(dir, base_prefix)
    Diagnostic.debug("ensure_companion_video_track: found #video_files=" .. tostring(#video_files))
    if #video_files == 0 then
        M.add_bundled_black_video_track("Audio-only media detected with no companion video.")
        return
    end

    local current_path_norm = M.canonicalize_local_path(path)

    FSM.video_candidates = {}
    FSM.current_candidate_idx = 0
    for _, candidate in ipairs(video_files) do
        if M.canonicalize_local_path(candidate.path) ~= current_path_norm then
            table.insert(FSM.video_candidates, candidate)
        end
    end

    Diagnostic.debug("ensure_companion_video_track: #video_candidates after filtering=" .. tostring(#FSM.video_candidates))
    M.try_next_video_candidate()
end

return M
