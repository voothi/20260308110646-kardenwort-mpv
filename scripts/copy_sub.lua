local mp = require 'mp'
local utils = require 'mp.utils'

-- Function to clean up ASS tags and newlines from the subtitle text
local function clean_subtitle(text)
    if not text then return "" end
    -- Remove ASS override tags like {\an8} or {\b1}
    text = text:gsub("{[^}]+}", "")
    -- Replace explicit \N newlines with spaces
    text = text:gsub("\\N", " ")
    -- Replace actual newlines with spaces
    text = text:gsub("\n", " ")
    -- Remove any leading/trailing whitespace
    text = text:match("^%s*(.-)%s*$")
    return text
end

local function copy_subtitle()
    local text = mp.get_property("sub-text")
    local cleaned_text = clean_subtitle(text)
    
    if cleaned_text and cleaned_text ~= "" then
        -- Escape single quotes for PowerShell by doubling them
        local escaped_text = cleaned_text:gsub("'", "''")
        
        -- Use PowerShell to set the Windows clipboard
        local command = string.format("[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Set-Clipboard -Value '%s'", escaped_text)
        
        utils.subprocess({
            args = {"powershell", "-NoProfile", "-Command", command},
            cancellable = false,
        })
        
        -- Create a truncated version for the OSD message
        local osd_text = cleaned_text
        if string.len(osd_text) > 50 then
            osd_text = string.sub(osd_text, 1, 50) .. "..."
        end
        
        local ass_enable = mp.get_property("osd-ass-cc/0") or ""
        mp.osd_message(ass_enable .. "{\\an4}{\\fs20}Copied: " .. osd_text, 2.0)
    else
        local ass_enable = mp.get_property("osd-ass-cc/0") or ""
        mp.osd_message(ass_enable .. "{\\an4}{\\fs20}No subtitle to copy", 2.0)
    end
end

-- Register the script-binding for use in input.conf
mp.add_key_binding(nil, "copy-subtitle", copy_subtitle)

