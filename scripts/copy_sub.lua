local mp = require 'mp'
local utils = require 'mp.utils'

-- =========================================================================
-- CONFIGURATION OPTIONS
-- =========================================================================
-- copy_mode determines which part of a multi-line subtitle gets copied.
-- Options: "all" (default), "top" (first block of lines), "bottom" (last block of lines)
-- For ASS subtitles that stack languages, "top" usually grabs the primary language,
-- and "bottom" grabs the secondary language.
local config = {
    copy_mode = "all",
    -- Fallback compatibility: if set to true, filters out any line with Cyrillic characters 
    -- (Only applies if copy_mode = "all")
    filter_russian = false
}

local function has_cyrillic(str)
    return str:find("[\208\209]") ~= nil
end

-- Cycle through the copy modes
local function cycle_copy_mode()
    if config.copy_mode == "all" then
        config.copy_mode = "top"
    elseif config.copy_mode == "top" then
        config.copy_mode = "bottom"
    else
        config.copy_mode = "all"
    end
    
    local ass_enable = mp.get_property("osd-ass-cc/0") or ""
    mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Copy Subtitle Mode: " .. config.copy_mode:upper(), 2.0)
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
    
    if config.copy_mode == "top" then
        -- Grab the first line. If it's a multi-line language block separated by an empty visual gap, 
        -- we try to just grab the first logical chunk. For simplicity, we grab the first line here.
        -- Often ASS subtitles format Top language as Line 1, Bottom as Line 2.
        table.insert(final_lines, lines[1])
        
    elseif config.copy_mode == "bottom" then
        -- Grab the very last line
        table.insert(final_lines, lines[#lines])
        
    elseif config.copy_mode == "all" then
        for _, line in ipairs(lines) do
            if not (config.filter_russian and has_cyrillic(line)) then
                table.insert(final_lines, line)
            end
        end
    end
    
    -- Join the valid lines into a single string with spaces for the clipboard
    return table.concat(final_lines, " ")
end

local function copy_subtitle()
    local text = mp.get_property("sub-text")
    local cleaned_text = clean_subtitle(text)
    
    if cleaned_text and cleaned_text ~= "" then
        -- Escape single quotes for PowerShell by doubling them
        local escaped_text = cleaned_text:gsub("'", "''")
        
        -- Use PowerShell to set the Windows clipboard
        local cmd = string.format("[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Set-Clipboard -Value '%s'", escaped_text)
        
        utils.subprocess({
            args = {"powershell", "-NoProfile", "-Command", cmd},
            cancellable = false,
        })
        
        -- Create a truncated version for the OSD message
        local osd_text = cleaned_text
        if string.len(osd_text) > 50 then
            osd_text = string.sub(osd_text, 1, 50) .. "..."
        end
        
        local ass_enable = mp.get_property("osd-ass-cc/0") or ""
        mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Copied [" .. config.copy_mode:upper() .. "]: " .. osd_text, 2.0)
    else
        local ass_enable = mp.get_property("osd-ass-cc/0") or ""
        mp.osd_message(ass_enable .. "{\\an4}{\\fs20}No subtitle to copy", 2.0)
    end
end

-- Register the script-bindings for use in input.conf
mp.add_key_binding(nil, "copy-subtitle", copy_subtitle)
mp.add_key_binding(nil, "cycle-copy-mode", cycle_copy_mode)
