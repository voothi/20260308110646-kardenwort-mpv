local mp = require 'mp'
local utils = require 'mp.utils'

-- =========================================================================
-- CONFIGURATION OPTIONS
-- =========================================================================
-- copy_mode determines which part of a multi-line subtitle gets copied.
-- Options: "A" (first block of lines), "B" (last block of lines)
local config = {
    copy_mode = "A"
}

-- Cycle through the copy modes
local function cycle_copy_mode()
    if config.copy_mode == "A" then
        config.copy_mode = "B"
    else
        config.copy_mode = "A"
    end
    
    local ass_enable = mp.get_property("osd-ass-cc/0") or ""
    mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Copy Subtitle Mode: " .. config.copy_mode, 2.0)
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
    
    if config.copy_mode == "A" then
        -- Grab the first logical chunk of lines
        table.insert(final_lines, lines[1])
        
    elseif config.copy_mode == "B" then
        -- Grab the very last logical chunk of lines
        table.insert(final_lines, lines[#lines])
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
