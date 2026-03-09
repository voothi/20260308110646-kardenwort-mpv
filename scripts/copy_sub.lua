local mp = require 'mp'
local utils = require 'mp.utils'

-- =========================================================================
-- SCRIPT SETTINGS
-- =========================================================================

-- Which part of a multi-line subtitle gets copied for ASS stacking?
-- Options: "A" (last logical block), "B" (first logical block)
-- Note: If 'filter_russian' is true below, these modes become "A" (Foreign) and "B" (Russian).
local copy_mode = "A"

-- Enable smart language detection? (true/false)
-- If true, Mode A will ALWAYS grab foreign text and Mode B will ALWAYS grab Russian,
-- even if the subtitle order in the file changes.
local filter_russian = true

-- Duration for OSD status messages (in seconds)
local osd_msg_duration = 1.0

-- Number of words to show in the OSD confirmation message
local osd_word_limit = 3

-- Number of context lines to copy (before and after) when Context Copy is ON
local context_copy_lines = 2

-- State variable for Context Copy (toggled via Ctrl+X)
local context_copy_enabled = false

-- OSD Style and Position tags (ASS format)
-- \an4 = Middle Left, \fs20 = Font Size 20
local osd_style = "{\\an4}{\\fs20}"

-- Message Strings
local msg_copied_prefix = "Copied "
local msg_mode_prefix = "Copy Subtitle Mode: "
local msg_no_sub = "No subtitle to copy"

-- =========================================================================
-- MAIN CODE
-- =========================================================================

local function has_cyrillic(str)
    -- In UTF-8, Cyrillic characters fall in the range D0 80 to D3 bf
    -- Checking for D0 (\208) and D1 (\209) covers standard Russian characters
    return str:find("[\208\209]") ~= nil
end

-- Cycle through the copy modes
local function cycle_copy_mode()
    if copy_mode == "A" then
        copy_mode = "B"
    else
        copy_mode = "A"
    end
    
    local ass_enable = mp.get_property("osd-ass-cc/0") or ""
    mp.osd_message(ass_enable .. osd_style .. msg_mode_prefix .. copy_mode, osd_msg_duration)
end

local function toggle_copy_context()
    context_copy_enabled = not context_copy_enabled
    local ass_enable = mp.get_property("osd-ass-cc/0") or ""
    local state = context_copy_enabled and ("ON (" .. context_copy_lines .. " lines)") or "OFF"
    mp.osd_message(ass_enable .. osd_style .. "Context Copy: " .. state, osd_msg_duration)
end

local function parse_time(time_str)
    local h, m, s, ms = string.match(time_str, "(%d+):(%d+):(%d+),(%d+)")
    if h and m and s and ms then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms) / 1000
    end
    h, m, s, ms = string.match(time_str, "(%d+):(%d+):(%d+)%.(%d+)")
    if h and m and s and ms then
        return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(ms) / 1000
    end
    return 0
end

local function load_sub(path)
    if not path or path == "" then return {} end
    local f = io.open(path, "r")
    if not f then return {} end
    
    local subs = {}
    local current_sub = nil
    
    local is_ass = path:match("%.ass$") or path:match("%.ssa$")
    
    if is_ass then
        for line in f:lines() do
            if line:match("^Dialogue:") then
                local first_colon = line:find(":")
                if first_colon then
                    local content = line:sub(first_colon + 1)
                    content = content:gsub("^%s+", "")
                    local parts = {}
                    local last_pos = 1
                    for i = 1, 9 do
                        local comma_pos = content:find(",", last_pos)
                        if not comma_pos then break end
                        table.insert(parts, content:sub(last_pos, comma_pos - 1))
                        last_pos = comma_pos + 1
                    end
                    if #parts == 9 then
                        local text = content:sub(last_pos)
                        local start_str = parts[2]:match("^%s*(.-)%s*$")
                        local end_str = parts[3]:match("^%s*(.-)%s*$")
                        if start_str and end_str and text then
                            local raw_text = text:gsub("\\N", " \n "):gsub("{[^}]+}", "")
                            raw_text = raw_text:gsub("%s+", " "):match("^%s*(.-)%s*$")
                            -- Discard purely empty subs
                            if raw_text ~= "" then
                                local parsed_start = parse_time(start_str)
                                local parsed_end = parse_time(end_str)
                                
                                -- Search backwards up to 10 entries to merge identical raw text
                                -- (This bypasses interleaved dual-track Russian translation lines)
                                local merged = false
                                local search_limit = math.max(1, #subs - 10)
                                for i = #subs, search_limit, -1 do
                                    if subs[i].raw_text == raw_text then
                                        subs[i].end_time = math.max(subs[i].end_time, parsed_end)
                                        merged = true
                                        break
                                    end
                                end
                                
                                if not merged then
                                    table.insert(subs, {
                                        start_time = parsed_start,
                                        end_time = parsed_end,
                                        text = raw_text,
                                        raw_text = raw_text
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
        table.sort(subs, function(a, b) return a.start_time < b.start_time end)
    else
        local state = "ID"
        for line in f:lines() do
            line = line:gsub("\r", ""):gsub("<[^>]+>", "")
            if line == "" then
                if current_sub and current_sub.text ~= "" then
                    current_sub.raw_text = current_sub.text:match("^%s*(.-)%s*$")
                    -- Merge identical sequential blocks for SRTs as well (just in case they have similar dupes)
                    if #subs > 0 and subs[#subs].raw_text == current_sub.raw_text then
                        subs[#subs].end_time = math.max(subs[#subs].end_time, current_sub.end_time)
                    else
                        table.insert(subs, current_sub)
                    end
                end
                current_sub = nil
                state = "ID"
            elseif state == "ID" then
                if line:match("^%d+$") then
                    current_sub = {text = ""}
                    state = "TIME"
                end
            elseif state == "TIME" then
                local start_str, end_str = string.match(line, "(%S+)%s+%-%->%s+(%S+)")
                if start_str and end_str then
                    current_sub.start_time = parse_time(start_str)
                    current_sub.end_time = parse_time(end_str)
                    state = "TEXT"
                end
            elseif state == "TEXT" then
                if current_sub.text == "" then
                    current_sub.text = line
                else
                    current_sub.text = current_sub.text .. "\n" .. line
                end
            end
        end
        if current_sub and current_sub.text ~= "" then
            current_sub.raw_text = current_sub.text:match("^%s*(.-)%s*$")
            if #subs > 0 and subs[#subs].raw_text == current_sub.raw_text then
                subs[#subs].end_time = math.max(subs[#subs].end_time, current_sub.end_time)
            else
                table.insert(subs, current_sub)
            end
        end
    end
    
    return subs
end

local function get_center_index(subs, time_pos)
    if not subs or #subs == 0 then return -1 end
    for i = 1, #subs do
        local sub = subs[i]
        if time_pos >= sub.start_time and time_pos <= sub.end_time then
            return i
        end
        if time_pos < sub.start_time then
            if i > 1 then
                local prev = subs[i-1]
                if (time_pos - prev.end_time) < (sub.start_time - time_pos) then
                    return i - 1
                else
                    return i
                end
            else
                return 1
            end
        end
    end
    return #subs
end

local function get_track_path(type)
    local id = type == "primary" and mp.get_property_number("sid", 0) or mp.get_property_number("secondary-sid", 0)
    if id == 0 then return nil end
    local tracks = mp.get_property_native("track-list")
    if not tracks then return nil end
    for _, t in ipairs(tracks) do
        if t.type == "sub" and t.id == id and t.external and t["external-filename"] then
            if t["external-filename"]:match("%.srt$") or t["external-filename"]:match("%.ass$") or t["external-filename"]:match("%.ssa$") then
                return t["external-filename"]
            end
        end
    end
    return nil
end

local function get_context_text(time_pos)
    local p_path = get_track_path("primary")
    local s_path = get_track_path("secondary")
    
    local combined_texts = {}
    
    local function trim(s)
        return s:match("^%s*(.-)%s*$") or ""
    end
    
    local function is_target_lang(s)
        if not s then return false end
        local has_cyr = has_cyrillic(s)
        if copy_mode == "A" then
            return not has_cyr
        else
            return has_cyr
        end
    end
    
    local function append_subs(path)
        if not path then return end
        local subs = load_sub(path)
        if #subs > 0 then
            local idx = get_center_index(subs, time_pos)
            if idx ~= -1 then
                
                -- Determine the target language filter from the center sub if standard detect applies
                -- Or, if filter_russian is on, enforce the appropriate track explicitly
                local target_func = function(t) return true end
                if filter_russian then
                    target_func = is_target_lang
                end

                -- Gather previous context lines
                local pre_lines = {}
                local i = idx - 1
                while i >= 1 and #pre_lines < context_copy_lines do
                    local t = trim(subs[i].text)
                    if t ~= "" and target_func(t) then
                        table.insert(pre_lines, 1, t) 
                    end
                    i = i - 1
                end
                
                -- Add pre-context
                for _, ln in ipairs(pre_lines) do
                    table.insert(combined_texts, ln)
                end
                
                -- Always gather the targeted center if it matches, otherwise try to use the pure center regardless
                local center_text = trim(subs[idx].text)
                if center_text ~= "" and (not filter_russian or target_func(center_text)) then
                    table.insert(combined_texts, center_text)
                end
                
                -- Gather next context lines
                local post_lines = {}
                i = idx + 1
                while i <= #subs and #post_lines < context_copy_lines do
                    local t = trim(subs[i].text)
                    if t ~= "" and target_func(t) then
                        table.insert(post_lines, t)
                    end
                    i = i + 1
                end
                
                -- Add post-context
                for _, ln in ipairs(post_lines) do
                    table.insert(combined_texts, ln)
                end
            end
        end
    end
    
    append_subs(p_path)
    append_subs(s_path)
    
    if #combined_texts > 0 then
        return table.concat(combined_texts, "\n")
    end
    return nil
end


-- Function to clean up ASS tags and extract the requested lines
local function clean_subtitle(text)
    if not text then return "" end
    -- Remove ASS override tags like {\an8} or {\b1}
    text = text:gsub("{[^}]+}", "")
    -- Normalize explicit \N to standard newlines
    text = text:gsub("\\N", "\n")
    
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line and line ~= "" then
            table.insert(lines, line)
        end
    end
    
    if #lines == 0 then return "" end

    local final_lines = {}
    
    if filter_russian then
        -- Robust Language Detection Mode
        if copy_mode == "A" then
            -- Collect all lines WITHOUT Cyrillic (Foreign)
            for i = 1, #lines do
                if not has_cyrillic(lines[i]) then
                    table.insert(final_lines, lines[i])
                end
            end
        else
            -- Collect all lines WITH Cyrillic (Russian)
            for i = 1, #lines do
                if has_cyrillic(lines[i]) then
                    table.insert(final_lines, lines[i])
                end
            end
        end
        
        -- Fallback: if detection found nothing, use the old indexing logic
        if #final_lines == 0 then
            if copy_mode == "A" then table.insert(final_lines, lines[#lines])
            else table.insert(final_lines, lines[1]) end
        end
    else
        -- Simple Indexing Mode
        if copy_mode == "A" then
            -- Grab the last logical block of lines
            table.insert(final_lines, lines[#lines])
        elseif copy_mode == "B" then
            -- Grab the very first logical block of lines
            table.insert(final_lines, lines[1])
        end
    end
    
    -- Join the valid lines into a single string with spaces for the clipboard
    return table.concat(final_lines, " ")
end

local function copy_subtitle()
    local combined_text = ""
    
    if context_copy_enabled then
        local time_pos = mp.get_property_number("time-pos")
        if time_pos then
            local ctx_text = get_context_text(time_pos)
            if ctx_text and ctx_text ~= "" then
                combined_text = ctx_text
            end
        end
    end
    
    if combined_text == "" then
        local p_text = mp.get_property("sub-text") or ""
        local s_text = mp.get_property("secondary-sub-text") or ""
        -- Combine primary and secondary tracks with a newline so clean_subtitle sees them as separate blocks
        combined_text = p_text .. "\n" .. s_text
    end
    
    local cleaned_text = clean_subtitle(combined_text)
    
    if cleaned_text and cleaned_text ~= "" then
        -- Escape single quotes for PowerShell by doubling them
        local escaped_text = cleaned_text:gsub("'", "''")
        
        -- Use PowerShell to set the Windows clipboard
        local cmd = string.format("[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Set-Clipboard -Value '%s'", escaped_text)
        
        utils.subprocess({
            args = {"powershell", "-NoProfile", "-Command", cmd},
            cancellable = false,
        })
        
        -- Create a truncated version for the OSD message (first N words only)
        local words = {}
        for word in cleaned_text:gmatch("%S+") do
            table.insert(words, word)
            if #words == osd_word_limit then break end
        end
        
        local osd_text = table.concat(words, " ")
        local _, word_count = cleaned_text:gsub("%S+", "")
        if word_count > osd_word_limit then
            osd_text = osd_text .. "..."
        end
        
        local ass_enable = mp.get_property("osd-ass-cc/0") or ""
        mp.osd_message(ass_enable .. osd_style .. msg_copied_prefix .. copy_mode:upper() .. ": " .. osd_text, osd_msg_duration)
    else
        local ass_enable = mp.get_property("osd-ass-cc/0") or ""
        mp.osd_message(ass_enable .. osd_style .. msg_no_sub, osd_msg_duration)
    end
end

-- Register the script-bindings for use in input.conf
mp.add_key_binding(nil, "copy-subtitle", copy_subtitle)
mp.add_key_binding(nil, "cycle-copy-mode", cycle_copy_mode)
mp.add_key_binding(nil, "toggle-copy-context", toggle_copy_context)
