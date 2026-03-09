local mp = require 'mp'
local utils = require 'mp.utils'

-- =========================================================================
-- SCRIPT SETTINGS
-- =========================================================================

-- Which part of a multi-line subtitle gets copied for ASS stacking?
-- Options: "A" (last logical block), "B" (first logical block)
local copy_mode = "A"

-- Duration for OSD status messages (in seconds)
local osd_msg_duration = 1.0

-- Number of words to show in the OSD confirmation message
local osd_word_limit = 3

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
