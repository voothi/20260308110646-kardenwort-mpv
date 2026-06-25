-- ============================================================================
-- quiz_sync.lua — Sync to external spaced repetition quiz (kardenwort-quiz)
-- Handles extracting ZID, postfix, playback time, and executing background IPC
-- ============================================================================

local mp = require("mp")
local utils = require("mp.utils")
local companion = require("companion")

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

local function discover_quiz_script_path()
    local script_dir = mp.get_script_directory()
    if not script_dir then return nil end
    local parent_dir = utils.join_path(script_dir, "../../..")
    local dirs = utils.readdir(parent_dir, "dirs") or {}
    for _, d in ipairs(dirs) do
        if d:find("kardenwort-quiz", 1, true) then
            local candidate_path = utils.join_path(utils.join_path(parent_dir, d), "tsv_quiz.lua")
            if utils.file_info(candidate_path) then
                return candidate_path
            end
        end
    end
    return nil
end

function M.cmd_sync_to_quiz()
    local osd_cards = require("osd_cards")

    if Options.quiz_integration == false then
        Diagnostic.info("Quiz integration is disabled (quiz_integration = false)")
        osd_cards.show_osd("Quiz Sync: Disabled (enable in mpv.conf)")
        return
    end

    local path = mp.get_property("path")
    if not path or path == "" then
        Diagnostic.warn("No file loaded, cannot sync to quiz")
        osd_cards.show_osd("Quiz Sync: No file loaded")
        return
    end

    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then
        Diagnostic.warn("No playback time available, cannot sync to quiz")
        osd_cards.show_osd("Quiz Sync: Playback time unavailable")
        return
    end

    -- Extract filename from path
    local normalized_path = path:gsub("\\", "/")
    local dir = normalized_path:match("^(.*/)") or ""
    local filename = normalized_path:sub(#dir + 1)
    local ext = filename:match("%.([^%.]+)$") or ""
    local filename_no_ext = filename
    if ext ~= "" then
        filename_no_ext = filename:sub(1, #filename - #ext - 1)
    end

    -- Split base name and postfix
    local base_prefix, current_postfix = companion.split_base_and_language_postfix(filename_no_ext)
    base_prefix = base_prefix or filename_no_ext

    -- Extract 14-digit ZID
    local zid = base_prefix:match("(%d%d%d%d%d%d%d%d%d%d%d%d%d%d)")
    if not zid then
        Diagnostic.warn("Could not extract a 14-digit ZID from media filename: " .. filename)
        osd_cards.show_osd("Quiz Sync: No ZID in filename")
        return
    end

    local pipe_path = Options.quiz_pipe_path or [[\\.\pipe\kardenwort-quiz]]
    local python_path = Options.python_path or "python"

    local is_windows = (package.config:sub(1, 1) == "\\")
    local family = is_windows and "AF_PIPE" or "AF_UNIX"

    -- Send the message to the quiz IPC socket in a background Python subprocess
    -- Format: {'zid': '<zid>', 'time': <time>, 'postfix': '<postfix>'}
    local py_code
    if is_windows then
        py_code = [[
import subprocess, sys
try:
    from multiprocessing.connection import Client
    c = Client(r']] .. pipe_path .. [[', family=']] .. family .. [[')
    c.send({'zid': ']] .. zid .. [[', 'time': ]] .. time_pos .. [[, 'postfix': ']] .. (current_postfix or "") .. [['})
    c.close()
    sys.exit(0)
except Exception:
    pass

try:
    cmd = 'wmic process where "name=\'lua.exe\' or name=\'wlua.exe\'" get commandline'
    out = subprocess.check_output(cmd, shell=True, startupinfo=subprocess.STARTUPINFO(dwFlags=subprocess.STARTF_USESHOWWINDOW, wShowWindow=0)).decode('utf-8', errors='ignore')
    if any('tsv_quiz.lua' in line for line in out.splitlines()):
        sys.exit(2)
except Exception:
    try:
        cmd = ["powershell", "-NoProfile", "-Command", "Get-CimInstance Win32_Process -Filter \"Name='lua.exe' or Name='wlua.exe'\" | Select-Object -ExpandProperty CommandLine"]
        out = subprocess.check_output(cmd, startupinfo=subprocess.STARTUPINFO(dwFlags=subprocess.STARTF_USESHOWWINDOW, wShowWindow=0)).decode('utf-8', errors='ignore')
        if any('tsv_quiz.lua' in line for line in out.splitlines()):
            sys.exit(2)
    except Exception:
        pass

sys.exit(1)
]]
    else
        py_code = string.format(
            "from multiprocessing.connection import Client; c=Client('%s', family='%s'); c.send({'zid': '%s', 'time': %f, 'postfix': '%s'}); c.close()",
            pipe_path,
            family,
            zid,
            time_pos,
            current_postfix or ""
        )
    end

    Diagnostic.info(string.format("Syncing to quiz: ZID %s, time %.2f, postfix %s", zid, time_pos, current_postfix or "nil"))
    osd_cards.show_osd("Syncing to quiz...")

    mp.command_native_async({
        name = "subprocess",
        args = { python_path, "-c", py_code },
        playback_only = false,
        capture_stdout = false,
        capture_stderr = false,
    }, function(success, result, error)
        if not success or (result and result.status ~= 0) then
            if result and result.status == 2 then
                Diagnostic.info("Quiz is already running but busy/not at prompt.")
                osd_cards.show_osd("Quiz Sync: Quiz is busy")
                return
            end
            local script_path = Options.quiz_script_path
            if not script_path or script_path == "" then
                script_path = discover_quiz_script_path()
            end
            if script_path and script_path ~= "" then
                local tsv_export = require("tsv_export")
                local tsv_path = tsv_export.get_tsv_path()
                if tsv_path and tsv_path ~= "" then
                    local lua_path = Options.lua_path or "lua"
                    local clean_tsv_path = tsv_path:gsub('"', '')
                    local clean_script_path = script_path:gsub('"', '')
                    Diagnostic.info("Quiz is not running. Launching quiz for: " .. clean_tsv_path)
                    osd_cards.show_osd("Launching Quiz...")
                    
                    if is_windows then
                        mp.command_native_async({
                            name = "subprocess",
                            args = { "cmd.exe", "/c", "start", "", lua_path, clean_script_path, clean_tsv_path, "--sync", zid, string.format("%f", time_pos) },
                            playback_only = false,
                            capture_stdout = false,
                            capture_stderr = false,
                        }, function(launch_success, launch_result, launch_error)
                            if not launch_success or (launch_result and launch_result.status ~= 0) then
                                Diagnostic.error("Failed to launch quiz utility: " .. tostring(launch_error or (launch_result and launch_result.stderr)))
                                osd_cards.show_osd("Quiz Sync: Launch Failed")
                            end
                        end)
                    else
                        Diagnostic.warn("Auto-launch not implemented for non-Windows platforms")
                        osd_cards.show_osd("Quiz Sync: Auto-launch only on Windows")
                    end
                else
                    Diagnostic.warn("Could not determine TSV path, cannot launch quiz")
                    osd_cards.show_osd("Quiz Sync: No TSV file found")
                end
            else
                local err_msg = error or (result and result.stderr) or "unknown error"
                Diagnostic.error("Failed to send sync command to quiz broker: " .. tostring(err_msg))
                osd_cards.show_osd("Quiz Sync: Failed (is the quiz running?)")
            end
        else
            Diagnostic.info("Successfully sent sync command to quiz broker")
            osd_cards.show_osd("Quiz Sync: OK")
        end
    end)
end

return M
