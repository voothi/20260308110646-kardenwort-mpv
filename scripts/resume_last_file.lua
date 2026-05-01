-- resume_last_file.lua
-- Automatically saves the last played file and resumes it if MPV is started without arguments.

-- =========================================================================
-- OPTIONS
-- =========================================================================
local opts = {
    -- Duration of the OSD resume message in seconds (0.5 = 500ms)
    osd_duration = 2,
    -- Delay before checking if we should resume on startup (seconds)
    startup_delay = 0.1,
    -- File to store the last played path
    state_file = "~~/resume_session.state",
    -- Message prefix for OSD
    msg_prefix = "test:",
    -- OSD font size (set to 0 to use system default)
    osd_font_size = 25
}

local utils = require 'mp.utils'
local state_path = mp.command_native({"expand-path", opts.state_file})

-- Function to save the current file path
local function save_last_file()
    local path = mp.get_property("path")
    -- We only save if it's a valid path and not a dummy/pseudo-file
    if path and path ~= "" and not path:match("^%[") then
        local f = io.open(state_path, "w")
        if f then
            f:write(path)
            f:close()
        end
    end
end

-- Register events to save the path
mp.register_event("file-loaded", save_last_file)
mp.register_event("shutdown", save_last_file)

-- On startup, check if we should resume
mp.add_timeout(opts.startup_delay, function()
    local path = mp.get_property("path")
    local playlist_count = tonumber(mp.get_property("playlist-count") or 0)
    
    -- If no file is currently loaded and the playlist is empty
    if (not path or path == "") and playlist_count == 0 then
        local f = io.open(state_path, "r")
        if f then
            local last_path = f:read("*a")
            f:close()
            if last_path and last_path ~= "" then
                -- Check if file exists (or is a URL)
                local is_url = last_path:match("^https?://") or last_path:match("^ytdl://")
                local info = is_url or utils.file_info(last_path)
                if info then
                    local filename = last_path:match("([^/\\]+)$")
                    local msg = opts.msg_prefix .. filename
                    if opts.osd_font_size > 0 then
                        msg = string.format("{\\fs%d}%s", opts.osd_font_size, msg)
                    end
                    mp.osd_message(msg, opts.osd_duration)
                    mp.msg.info("Resuming last session: " .. last_path)
                    mp.commandv("loadfile", last_path)
                else
                    mp.msg.warn("Last session file not found: " .. last_path)
                end
            end
        end
    end
end)
