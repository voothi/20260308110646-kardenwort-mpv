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

function M.cmd_sync_to_quiz()
    if Options.quiz_integration == false then
        Diagnostic.info("Quiz integration is disabled (quiz_integration = false)")
        return
    end

    local path = mp.get_property("path")
    if not path or path == "" then
        Diagnostic.warn("No file loaded, cannot sync to quiz")
        return
    end

    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then
        Diagnostic.warn("No playback time available, cannot sync to quiz")
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
        py_code = string.format(
            "from multiprocessing.connection import Client; c=Client(r'%s', family='%s'); c.send({'zid': '%s', 'time': %f, 'postfix': '%s'}); c.close()",
            pipe_path,
            family,
            zid,
            time_pos,
            current_postfix or ""
        )
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

    mp.command_native_async({
        name = "subprocess",
        args = { python_path, "-c", py_code },
        playback_only = false,
        capture_stdout = false,
        capture_stderr = false,
    }, function(success, result, error)
        if not success or (result and result.status ~= 0) then
            local err_msg = error or (result and result.stderr) or "unknown error"
            Diagnostic.error("Failed to send sync command to quiz broker: " .. tostring(err_msg))
        else
            Diagnostic.info("Successfully sent sync command to quiz broker")
        end
    end)
end

return M
