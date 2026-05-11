-- resume_last_file.lua
-- Automatically saves the last played file and resumes it if MPV is started without arguments.

-- =========================================================================
-- OPTIONS
-- =========================================================================
local utils = require 'mp.utils'
local options = require 'mp.options'

local opts = {
    -- Duration of the OSD resume message in seconds (0.5 = 500ms)
    osd_duration = 5,
    -- Delay before checking if we should resume on startup (seconds)
    startup_delay = 0.1,
    -- File to store the last played path
    state_file = "~~/resume-session.state",
    -- Message prefix for OSD
    msg_prefix = "",
    -- OSD font size (set to 0 to use system default)
    osd_font_size = 34,
    -- OSD font name (set to "" to use system default)
    osd_font_name = "Consolas",
    -- Whether to show the OSD message with the filename
    show_filename = false,
    -- Whether to include information about connected subtitles in the OSD
    show_subtitles = false
}

options.read_options(opts, "resume_last_file")

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
                    
                    if opts.show_filename then
                        local osd = mp.create_osd_overlay("ass-events")
                        osd.res_x = 1920
                        osd.res_y = 1080
                        
                        if opts.show_subtitles then
                            local dir, name = utils.split_path(last_path)
                            local base_name = name:gsub("%.%w+$", "")
                            local files = utils.readdir(dir)
                            local subs_found = {}
                            if files then
                                for _, f in ipairs(files) do
                                    if f:match("^" .. base_name:gsub("[%%()%.%+%-%*%?%[%]%^%$]", "%%%1") .. ".*%.[as][rs]t$") then
                                        table.insert(subs_found, f)
                                    end
                                end
                            end
                            if #subs_found > 0 then
                                table.sort(subs_found, function(a, b)
                                    -- Priority: push .ru to the end
                                    local a_ru = a:lower():match("%.ru%.")
                                    local b_ru = b:lower():match("%.ru%.")
                                    if a_ru and not b_ru then return false end
                                    if b_ru and not a_ru then return true end
                                    return a:lower() < b:lower()
                                end)
                                msg = msg .. "\n" .. table.concat(subs_found, "\n")
                            end
                        end

                        local ass_msg = string.format("{\\an7}{\\pos(20,20)}{\\fs%d}{\\fn%s}{\\bord1.5}{\\shad1.0}%s", 
                            opts.osd_font_size, opts.osd_font_name, msg:gsub("\n", "\\N"))
                        osd.data = ass_msg
                        osd:update()
                        
                        mp.add_timeout(opts.osd_duration, function()
                            osd:remove()
                        end)
                    end
                    
                    mp.msg.info("Resuming last session: " .. last_path)
                    mp.commandv("loadfile", last_path)
                else
                    mp.msg.warn("Last session file not found: " .. last_path)
                end
            end
        end
    end
end)
