-- ============================================================================
-- dw_esc.lua — Drum Window ESC policy, neutral cursor, and selection reset
-- Contains the ESC-mode resolution family and selection lifecycle helpers
-- (reset, post-transition, neutral marker capture, ctrl pending list sync).
-- Reads FSM/Options/Tracks at call time via injected references.
-- ============================================================================

local mp = require 'mp'

local M = {}

local FSM, Options, Tracks
local _helpers

function M.init(fsm, opts, tracks, helpers)
    assert(fsm, "FATAL: fsm dependency missing")
    assert(opts, "FATAL: opts dependency missing")
    assert(tracks, "FATAL: tracks dependency missing")
    FSM = fsm
    Options = opts
    Tracks = tracks
    _helpers = setmetatable(helpers or {}, {
        __index = function(t, k)
            error("FATAL: Missing injected helper function: " .. tostring(k), 2)
        end
    })
end

function M.sync_ctrl_pending_list()
    local members = {}
    for _, line_tbl in pairs(FSM.DW_CTRL_PENDING_SET) do
        for _, m in pairs(line_tbl) do
            table.insert(members, m)
        end
    end
    if #members > 0 then
        table.sort(members, function(a, b)
            if a.line ~= b.line then return a.line < b.line end
            return a.word < b.word
        end)
    end
    FSM.DW_CTRL_PENDING_LIST = members
end

function M.capture_neutral_marker()
    if FSM.DW_CURSOR_LINE ~= -1 then
        FSM.DW_NEUTRAL_LINE = FSM.DW_CURSOR_LINE
    end
    if FSM.DW_CURSOR_WORD ~= -1 then
        FSM.DW_NEUTRAL_WORD = FSM.DW_CURSOR_WORD
    end
end

function M.get_esc_mode()
    local mode = tostring(Options.dw_esc_mode or ""):lower()
    if mode == "auto_follow_current" or mode == "neutral_last_selection" or mode == "neutral_current_subtitle" then
        return mode
    end

    -- Backward compatibility mapping from legacy 2-parameter design.
    local policy = tostring(Options.dw_esc_policy or ""):lower()
    local source = tostring(Options.dw_neutral_cursor_source or ""):lower()
    if policy == "auto_follow" then
        return "auto_follow_current"
    end
    if source == "current_subtitle" then
        return "neutral_current_subtitle"
    end
    return "neutral_last_selection"
end

function M.is_neutral_policy_enabled()
    local mode = M.get_esc_mode()
    return mode == "neutral_last_selection" or mode == "neutral_current_subtitle"
end

function M.resolve_neutral_cursor_line()
    if M.get_esc_mode() == "neutral_current_subtitle" then
        if FSM.DW_ACTIVE_LINE and FSM.DW_ACTIVE_LINE ~= -1 then
            return FSM.DW_ACTIVE_LINE
        end
        local time_pos = mp.get_property_number("time-pos") or 0
        local live_idx = _helpers.get_center_index(Tracks.pri.subs, time_pos)
        if live_idx and live_idx ~= -1 then
            return live_idx
        end
    end
    if FSM.DW_NEUTRAL_LINE and FSM.DW_NEUTRAL_LINE ~= -1 then
        return FSM.DW_NEUTRAL_LINE
    end
    return FSM.DW_CURSOR_LINE
end

local function resolve_null_activation_line(ctx, dir, subs)
    -- Neutral-source policy applies ONLY while neutral mode is armed.
    -- Outside neutral mode, keep legacy free-mode activation behavior.
    if M.is_neutral_policy_enabled() and FSM.DW_ESC_NEUTRAL_ARMED then
        if M.get_esc_mode() == "neutral_last_selection" then
            if FSM.DW_NEUTRAL_LINE and FSM.DW_NEUTRAL_LINE ~= -1 then
                return FSM.DW_NEUTRAL_LINE
            end
        elseif M.get_esc_mode() == "neutral_current_subtitle" then
            if ctx and ctx.active_line and ctx.active_line ~= -1 then
                return ctx.active_line
            end
        end
    end

    -- Boundary hardening: on first activation, prefer synchronized active subtitle
    -- ownership over navigation-time lookahead context.
    local stable_active_line = (FSM.DW_ACTIVE_LINE ~= -1) and FSM.DW_ACTIVE_LINE or FSM.ACTIVE_IDX
    if stable_active_line and stable_active_line ~= -1 then
        return stable_active_line
    end

    if ctx and ctx.active_line and ctx.active_line ~= -1 then
        return ctx.active_line
    end
    if FSM.DW_CURSOR_LINE and FSM.DW_CURSOR_LINE ~= -1 then
        return FSM.DW_CURSOR_LINE
    end
    return (dir > 0 and 1 or #subs)
end

local function reset_selection()
    M.capture_neutral_marker()
    FSM.DW_ESC_NEUTRAL_ARMED = M.is_neutral_policy_enabled()
    -- Synchronize active line to live playback to prevent stale jumps during reset
    local time_pos = mp.get_property_number("time-pos") or 0
    local live_active_idx = _helpers.get_center_index(Tracks.pri.subs, time_pos)
    if live_active_idx and live_active_idx ~= -1 then
        FSM.DW_ACTIVE_LINE = live_active_idx
    end

    FSM.DW_CTRL_PENDING_SET = {}
    FSM.DW_CTRL_PENDING_LIST = {}
    FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
    FSM.DW_ANCHOR_LINE = -1
    FSM.DW_ANCHOR_WORD = -1
    FSM.DW_CURSOR_WORD = -1
    FSM.DW_CURSOR_X = nil
    if FSM.DW_ACTIVE_LINE ~= -1 then
        FSM.DW_CURSOR_LINE = FSM.DW_ACTIVE_LINE
    end

    -- Esc follow policy:
    -- auto_follow: restore immediately; neutral: stay manual and require extra Esc.
    if not M.is_neutral_policy_enabled() then
        FSM.DW_FOLLOW_PLAYER = true
    end
    FSM.DW_SEEKING_MANUALLY = false
    FSM.DW_SEEK_TARGET = -1

    if FSM.DRUM_WINDOW ~= "OFF" then
        if _helpers.dw_osd then _helpers.dw_osd:update() end
    elseif FSM.DRUM == "ON" then
        if _helpers.drum_osd then _helpers.drum_osd:update() end
    end
end

function M.apply_post_transition_selection(target_word)
    -- Transition should always start a fresh Esc cycle state.
    FSM.DW_ESC_NEUTRAL_ARMED = false
    local follow_after_transition = not M.is_neutral_policy_enabled()
    if Options.dw_clear_selection_after_transition then
        FSM.DW_CTRL_PENDING_SET = {}
        FSM.DW_CTRL_PENDING_LIST = {}
        FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
        FSM.DW_CURSOR_WORD = -1
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        -- Mirror Esc policy expectations after hard transition:
        -- auto_follow_current => resume follow, neutral_* => stay manual.
        FSM.DW_FOLLOW_PLAYER = follow_after_transition
    else
        FSM.DW_CURSOR_WORD = (target_word and target_word > 0) and target_word or FSM.DW_CURSOR_WORD
        FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
        FSM.DW_ANCHOR_WORD = FSM.DW_CURSOR_WORD
        -- When pointer remains after transition, keep manual mode until Esc clears selection.
        local pointer_active = (FSM.DW_CURSOR_WORD and FSM.DW_CURSOR_WORD ~= -1)
        FSM.DW_FOLLOW_PLAYER = follow_after_transition and not pointer_active
    end
end
M.resolve_null_activation_line = resolve_null_activation_line
M.reset_selection = reset_selection

return M