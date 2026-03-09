local mp = require 'mp'
local utils = require 'mp.utils'

local function has_cyrillic(str)
    -- In UTF-8, Cyrillic characters fall in the range D0 80 to D3 bf
    -- Checking for D0 (\208) and D1 (\209) covers standard Russian characters
    return str:find("[\208\209]") ~= nil
end

-- Function to clean up ASS tags, newlines, and filter out Russian text
local function clean_subtitle(text)
    if not text then return "" end
    -- Remove ASS override tags like {\an8} or {\b1}
    text = text:gsub("{[^}]+}", "")
    -- Normalize explicit \N to standard newlines
    text = text:gsub("\\N", "\n")
    
    local clean_lines = {}
    for line in text:gmatch("[^\n]+") do
        -- Strip leading/trailing whitespace
        line = line:match("^%s*(.-)%s*$")
        -- If line is not empty and DOES NOT contain Russian characters, keep it
        if line and line ~= "" and not has_cyrillic(line) then
            table.insert(clean_lines, line)
        end
    end
    
    -- Join the valid lines into a single string with spaces
    return table.concat(clean_lines, " ")
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

