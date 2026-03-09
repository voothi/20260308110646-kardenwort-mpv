local mp = require 'mp'
local utils = require 'mp.utils'

-- =========================================================================
-- SCRIPT SETTINGS
-- =========================================================================

-- Which part of a multi-line subtitle gets copied for ASS stacking?
-- Options: "A" (first logical block), "B" (last logical block)
local copy_mode = "A"

-- Duration for OSD status messages (in seconds)
local osd_msg_duration = 1.0

-- =========================================================================
-- MAIN CODE
-- =========================================================================

-- Cycle through the copy modes
local function cycle_copy_mode()
    if copy_mode == "A" then
        copy_mode = "B"
    else
        copy_mode = "A"
    end
    
    local ass_enable = mp.get_property("osd-ass-cc/0") or ""
    mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Copy Subtitle Mode: " .. copy_mode, osd_msg_duration)
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
    
    if copy_mode == "A" then
        -- Grab the last logical block of lines
        table.insert(final_lines, lines[#lines])
        
    elseif copy_mode == "B" then
        -- Grab the very first logical block of lines
        table.insert(final_lines, lines[1])
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
        mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Copied " .. copy_mode:upper() .. ": " .. osd_text, osd_msg_duration)
    else
        local ass_enable = mp.get_property("osd-ass-cc/0") or ""
        mp.osd_message(ass_enable .. "{\\an4}{\\fs20}No subtitle to copy", osd_msg_duration)
    end
end

-- Register the script-bindings for use in input.conf
mp.add_key_binding(nil, "copy-subtitle", copy_subtitle)
mp.add_key_binding(nil, "cycle-copy-mode", cycle_copy_mode)
