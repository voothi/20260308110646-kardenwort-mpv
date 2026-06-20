-- ===============================================================================
-- KARDENWORT Language Acquisition Suite (LAS) Core
-- Purpose: Language Acquisition through Subtitle-Driven Immersion
-- Features: Autopause, Karaoke Drill, Flashback Replay, Sticky Hold.
-- ===============================================================================
--
-- Module map (scripts/kardenwort/):
--   main.lua            — orchestrator: requires, boot, init, binding registration,
--                        event observers, and subsystem wiring.
--   config.lua           — Options table + configuration validation.
--   state.lua            — FSM (finite state machine) + Tracks (subtitle track state).
--   text_utils.lua       — UTF-8/tokenization/copy-preview helpers.
--   subtitle_parser.lua  — subtitle loading, parsing, time/index resolution.
--   keybinding_utils.lua— mpv key validation + Cyrillic layout expansion.
--   osd_cards.lua        — transient OSD popups (status/seek notices).
--   render_utils.lua     — shared ASS rendering: measurement, layout, highlight.
--   subtitle_window.lua  — draw_drum / draw_dw / draw_dw_tooltip renderers.
--   tsv_export.lua       — Anki/TSV mining, highlight grounding, context extraction.
--   companion.lua        — companion audio/subtitle/video track discovery.
--   search.lua          — Universal Subtitle Search HUD.
--   help_hud.lua         — Dynamic Help HUD (F1).
--   resume.lua           — session resumption on blank launch.
--
-- Alias block invariant: the `alias()` locals below MUST stay in sync with each
-- module's public `M.*` exports. Init order matters — modules read injected
-- singletons at call time, but helper tables are populated after their defs.
-- ===============================================================================

local mp = require("mp")
local script_dir = mp.get_script_directory()
if script_dir then
    package.path = script_dir .. "/?.lua;" .. package.path
end

local text_utils = require("text_utils")
local subtitle_parser = require("subtitle_parser")
local keybinding_utils = require("keybinding_utils")
local osd_cards = require("osd_cards")
local tsv_export = require("tsv_export")
local companion = require("companion")
local search = require("search")
local help_hud = require("help_hud")
local render_utils = require("render_utils")
local subtitle_window = require("subtitle_window")
local test_hooks = require("test_hooks")
local dw_esc = require("dw_esc")
local tooltip = require("tooltip")
local mouse_input = require("mouse_input")
local dw_navigation = require("dw_navigation")
local tick_loop_module = require("tick_loop")
local config = require("config")
local state = require("state")
local utils = require("mp.utils")
local options = require("mp.options")
local msg = require("mp.msg")

-- Callback registration hardening (must run before loading auxiliary modules).
do
    local raw_add_key_binding = mp.add_key_binding
    local raw_add_forced_key_binding = mp.add_forced_key_binding
    local raw_add_timeout = mp.add_timeout
    local raw_add_periodic_timer = mp.add_periodic_timer
    local raw_register_event = mp.register_event
    local raw_observe_property = mp.observe_property
    local raw_register_script_message = mp.register_script_message
    local raw_get_property_number = mp.get_property_number
    local raw_get_property = mp.get_property
    local raw_commandv = mp.commandv
    local raw_command = mp.command

    -- Subtitle delay adjustment wrappers.
    -- Intercept time-pos queries and seek commands to respect mpv's sub-delay offset
    -- so that kardenwort's custom subtitle immersion features sync perfectly.
    mp.get_property_number = function(name, def)
        if name == "time-pos" then
            local val = raw_get_property_number(name)
            if not val then
                return def
            end
            local sub_delay = raw_get_property_number("sub-delay") or 0.0
            return val - sub_delay
        end
        return raw_get_property_number(name, def)
    end

    mp.get_property = function(name, def)
        if name == "time-pos" then
            local val = raw_get_property(name)
            if not val then
                return def
            end
            local val_num = tonumber(val)
            if not val_num then
                return val
            end
            local sub_delay = raw_get_property_number("sub-delay") or 0.0
            return tostring(val_num - sub_delay)
        end
        return raw_get_property(name, def)
    end

    mp.commandv = function(cmd, ...)
        if cmd == "seek" then
            local args = { ... }
            local target = args[1]
            local mode = args[2]
            if mode == "absolute+exact" or mode == "absolute" then
                local target_num = tonumber(target)
                if target_num then
                    local sub_delay = raw_get_property_number("sub-delay") or 0.0
                    target = target_num + sub_delay
                end
            end
            return raw_commandv(cmd, target, mode, select(3, ...))
        end
        return raw_commandv(cmd, ...)
    end

    mp.command = function(cmd_str)
        if type(cmd_str) == "string" and cmd_str:match("^seek%s+") then
            local target, mode = cmd_str:match("^seek%s+([%d%.%-]+)%s+([%a%+]+)")
            if target and (mode == "absolute" or mode == "absolute+exact") then
                local target_num = tonumber(target)
                if target_num then
                    local sub_delay = raw_get_property_number("sub-delay") or 0.0
                    return raw_command(string.format("seek %f %s", target_num + sub_delay, mode))
                end
            end
        end
        return raw_command(cmd_str)
    end

    local function validate_callback(kind, name, fn)
        if type(fn) == "function" then
            return true
        end
        msg.error(
            string.format(
                "[kardenwort] Skipping invalid %s '%s': callback is %s",
                tostring(kind),
                tostring(name),
                type(fn)
            )
        )
        return false
    end

    mp.add_key_binding = function(key, name, fn, flags)
        if not validate_callback("binding", name or key, fn) then
            return false
        end
        raw_add_key_binding(key, name, fn, flags)
        return true
    end

    mp.add_forced_key_binding = function(key, name, fn, flags)
        if not validate_callback("forced binding", name or key, fn) then
            return false
        end
        raw_add_forced_key_binding(key, name, fn, flags)
        return true
    end

    ---@class MpvTimer
    ---@field kill fun(self: MpvTimer)
    ---@field is_active fun(self: MpvTimer): boolean
    ---@field resume fun(self: MpvTimer)

    ---@param seconds number
    ---@param fn function
    ---@return MpvTimer?
    mp.add_timeout = function(seconds, fn)
        if not validate_callback("timeout", seconds, fn) then
            return nil
        end
        return raw_add_timeout(seconds, fn)
    end

    ---@param seconds number
    ---@param fn function
    ---@return MpvTimer?
    mp.add_periodic_timer = function(seconds, fn)
        if not validate_callback("periodic timer", seconds, fn) then
            return nil
        end
        return raw_add_periodic_timer(seconds, fn)
    end

    mp.register_event = function(name, fn)
        if not validate_callback("event handler", name, fn) then
            return false
        end
        raw_register_event(name, fn)
        return true
    end

    mp.observe_property = function(name, ty, fn)
        if not validate_callback("property observer", name, fn) then
            return false
        end
        raw_observe_property(name, ty, fn)
        return true
    end

    mp.register_script_message = function(name, fn)
        if not validate_callback("script message", name, fn) then
            return false
        end
        raw_register_script_message(name, fn)
        return true
    end
end

require("resume")

-- Fallback for older mpv versions missing utils.read_file
local function safe_read_file(path)
    if not path or path == "" then
        return nil
    end
    if utils and utils.read_file then
        return utils.read_file(path)
    end
    local f = io.open(path, "rb")
    if f then
        local content = f:read("*a")
        f:close()
        return content
    end
    return nil
end

-- ===============================================================================
-- KARDENWORT CORE CONFIGURATION
-- ===============================================================================

-- Forward declarations for interactive logic
local Options = config.Options
local get_first_valid_word_idx
local manage_ui_border_override
local DRUM_DRAW_CACHE, DW_DRAW_CACHE, DW_TOOLTIP_DRAW_CACHE
DW_TOOLTIP_DRAW_CACHE = { target_idx = -1, osd_y = -1, version = -1, cl = -1, cw = -1, av = -1 }
local set_clipboard
local dw_get_mouse_osd, kardenwort_hit_test_all, dw_sync_cursor_to_mouse

local function alias(mod, names)
    local vals = {}
    for _, name in ipairs(names) do
        assert(
            mod[name] ~= nil,
            "FATAL: function '" .. tostring(name) .. "' is missing from module!"
        )
        vals[#vals + 1] = mod[name]
    end
    return table.unpack(vals)
end

-- text_utils aliases
local utf8_to_table, utf8_to_lower, utf8_truncate, is_word_char, is_abbrev, logical_cmp, build_word_list_internal, build_word_list, get_sub_tokens, is_word_token, clean_text_srt, normalize_inline_break_markers, calculate_ass_alpha, build_copy_preview, has_cyrillic =
    alias(text_utils, {
        "utf8_to_table",
        "utf8_to_lower",
        "utf8_truncate",
        "is_word_char",
        "is_abbrev",
        "logical_cmp",
        "build_word_list_internal",
        "build_word_list",
        "get_sub_tokens",
        "is_word_token",
        "clean_text_srt",
        "normalize_inline_break_markers",
        "calculate_ass_alpha",
        "build_copy_preview",
        "has_cyrillic",
    })
---@cast utf8_to_table fun(str: string): string[]
---@cast utf8_to_lower fun(str: string): string
---@cast utf8_truncate fun(str: string, max_chars: number): string
---@cast is_word_char fun(c: string): boolean
---@cast is_abbrev fun(w: string, lookahead: string|nil): boolean
---@cast logical_cmp fun(a: number, b: number): boolean
---@cast build_word_list_internal fun(text: string|nil, keep_spaces: boolean): table[]
---@cast build_word_list fun(text: string|nil): string[]
---@cast get_sub_tokens fun(s: table|nil, force_rich: boolean|nil): table[]|nil
---@cast is_word_token fun(t: any): boolean
---@cast clean_text_srt fun(line: string|nil): string
---@cast normalize_inline_break_markers fun(text: string|nil): string
---@cast calculate_ass_alpha fun(val: any): string
---@cast build_copy_preview fun(label: string|nil, text: string|nil, max_chars: number|nil): string
---@cast has_cyrillic fun(str: string|nil): boolean

local L_EPSILON = text_utils.L_EPSILON

-- subtitle_parser aliases
local parse_time, load_sub, find_sub_containing_start, get_center_index, get_center_index_static, get_effective_boundaries =
    alias(subtitle_parser, {
        "parse_time",
        "load_sub",
        "find_sub_containing_start",
        "get_center_index",
        "get_center_index_static",
        "get_effective_boundaries",
    })

-- keybinding_utils aliases
local is_valid_mpv_key, expand_ru_keys =
    alias(keybinding_utils, { "is_valid_mpv_key", "expand_ru_keys" })

-- osd_cards aliases
local show_osd, show_seek_osd = alias(osd_cards, { "show_osd", "show_seek_osd" })
local seek_osd -- forward-declared; assigned from osd_cards.seek_osd after setup()
local tsv_helpers -- populated at tsv_export init; flush_rendering_caches added later
local apply_tooltip_ass
local is_inside_dw_selection
local ctrl_commit_set
local dw_anki_export_selection

-- tsv_export aliases
local get_copy_context_text, prepare_export_text, extract_anki_context, load_anki_tsv, save_anki_tsv_row, find_source_url, get_tsv_path =
    alias(tsv_export, {
        "get_copy_context_text",
        "prepare_export_text",
        "extract_anki_context",
        "load_anki_tsv",
        "save_anki_tsv_row",
        "find_source_url",
        "get_tsv_path",
    })

-- companion aliases
local split_base_and_language_postfix, extract_lang_from_title_or_path, ensure_companion_audio_tracks, ensure_companion_subtitle_tracks, ensure_companion_video_track =
    alias(companion, {
        "split_base_and_language_postfix",
        "extract_lang_from_title_or_path",
        "ensure_companion_audio_tracks",
        "ensure_companion_subtitle_tracks",
        "ensure_companion_video_track",
    })

-- search aliases (forward-declared)
local search_helpers
local cmd_toggle_search
local update_search_results

-- help_hud aliases
local normalize_key_display = help_hud.normalize_key_display
local cmd_toggle_help -- forward-declared
local help_helpers

-- render_utils aliases
local compose_term_smart, calculate_highlight_stack, populate_token_meta, format_highlighted_word, dw_get_str_width_proportional, dw_get_str_width, calculate_sub_gap, wrap_tokens, calculate_osd_line_meta, dw_vline_height, dw_build_layout, dw_calculate_block_top, format_tooltip_card_event, format_tooltip_text_event =
    alias(render_utils, {
        "compose_term_smart",
        "calculate_highlight_stack",
        "populate_token_meta",
        "format_highlighted_word",
        "dw_get_str_width_proportional",
        "dw_get_str_width",
        "calculate_sub_gap",
        "wrap_tokens",
        "calculate_osd_line_meta",
        "dw_vline_height",
        "dw_build_layout",
        "dw_calculate_block_top",
        "format_tooltip_card_event",
        "format_tooltip_text_event",
    })
local render_helpers

-- subtitle_window aliases (forward-declared)
local draw_drum
local draw_dw
local draw_dw_tooltip
local sw_helpers

-- ===============================================================================
-- DIAGNOSTIC & LOGGING SYSTEM
-- ===============================================================================
local Diagnostic = {
    ERROR = 0,
    WARN = 1,
    INFO = 2,
    DEBUG = 3,
    TRACE = 4,
    LEVEL_MAP = { ["error"] = 0, ["warn"] = 1, ["info"] = 2, ["debug"] = 3, ["trace"] = 4 },
    SEEN = {},
}

Diagnostic.log = function(level, text, dedupe_key)
    local log_level_str = (Options and Options.log_level) or "info"
    local current_level = Diagnostic.LEVEL_MAP[log_level_str:lower()] or Diagnostic.INFO
    if level > current_level then
        return
    end

    if dedupe_key then
        if Diagnostic.SEEN[dedupe_key] then
            return
        end
        Diagnostic.SEEN[dedupe_key] = true
    end

    local prefix = "[kardenwort]"
    if level == Diagnostic.ERROR then
        msg.error(prefix .. " " .. text)
    elseif level == Diagnostic.WARN then
        msg.warn(prefix .. " " .. text)
    elseif level == Diagnostic.INFO then
        msg.info(prefix .. " " .. text)
    elseif level == Diagnostic.DEBUG then
        msg.verbose(prefix .. " " .. text)
    elseif level == Diagnostic.TRACE then
        msg.debug(prefix .. " " .. text)
    end
end

Diagnostic.error = function(text, key)
    Diagnostic.log(Diagnostic.ERROR, text, key)
end
Diagnostic.warn = function(text, key)
    Diagnostic.log(Diagnostic.WARN, text, key)
end
Diagnostic.info = function(text, key)
    Diagnostic.log(Diagnostic.INFO, text, key)
end
Diagnostic.debug = function(text, key)
    Diagnostic.log(Diagnostic.DEBUG, text, key)
end
Diagnostic.trace = function(text, key)
    Diagnostic.log(Diagnostic.TRACE, text, key)
end

Diagnostic.info("SCRIPT INITIALIZING: " .. (script_dir or mp.get_script_name() or "kardenwort"))

-- Initialize user-data properties for IPC querying
mp.set_property("user-data/kardenwort/last_clipboard", "")
mp.set_property("user-data/kardenwort/last_export", "")
mp.set_property("user-data/kardenwort/last_osd", "")
mp.set_property("user-data/kardenwort/state", "{}")
mp.set_property("user-data/kardenwort/render", "")

function validate_config()
    config.validate_config(Options, Diagnostic, is_valid_mpv_key)
end

options.read_options(Options, "kardenwort")
state.init(Options)

-- ===============================================================================
-- STATE MACHINE
-- ===============================================================================

local FSM = state.FSM
local Tracks = state.Tracks

FSM.notice_osd = mp.create_osd_overlay("ass-events")
FSM.notice_osd.res_y = Options.font_base_height
FSM.notice_osd.res_x = math.floor(FSM.notice_osd.res_y * 16 / 9)
FSM.notice_osd.z = Options.notice_osd_layer
FSM.notice_timer = nil

-- Init order matters: modules read injected singletons at call time, but some
-- helper tables are populated after their definitions (see notes below).

-- text_utils — pure text/tokenization helpers (reads Options at call time).
text_utils.init(FSM, Options)

-- subtitle_parser — subtitle loading/parsing (needs safe_read_file).
subtitle_parser.init(FSM, Options, Tracks, Diagnostic, safe_read_file)

-- keybinding_utils — key validation (reads Options at call time).
keybinding_utils.init(Options)

-- osd_cards — transient OSD popups; setup() creates the seek_osd overlay
-- (reads Options at creation time) and exposes it to main.lua.
osd_cards.init(FSM, Options, Tracks, Diagnostic)
osd_cards.setup()
seek_osd = osd_cards.seek_osd

-- tsv_export — Anki/TSV mining. safe_read_file is injected now;
-- flush_rendering_caches is a main.lua local defined later, so it is
-- populated into the helpers table after that definition
-- (see tsv_helpers.flush_rendering_caches assignment below).
tsv_helpers = { safe_read_file = safe_read_file }
tsv_export.init(FSM, Options, Tracks, Diagnostic, tsv_helpers)

-- companion — companion track discovery.
companion.init(FSM, Options, Diagnostic)

-- search — Universal Subtitle Search HUD.
-- Helpers (wrap_tokens, dw_get_mouse_osd, manage_ui_border_override,
-- manage_dw_bindings, update_interactive_bindings, render_search, show_osd)
-- are populated into search_helpers after their definitions in main.lua.
search_helpers = {}
search.init(FSM, Options, Tracks, Diagnostic, search_helpers)
cmd_toggle_search = search.cmd_toggle_search
update_search_results = search.update_search_results

-- help_hud — Dynamic Help HUD (F1).
-- help_helpers (help_osd_* overlays, render_search) populated after their defs.
help_helpers = {}
help_hud.init(FSM, Options, help_helpers)
cmd_toggle_help = help_hud.cmd_toggle_help
-- Load @help overrides from input.conf into HELP_SCHEMA (module-internal).
help_hud.load_overrides()

-- render_utils — shared ASS rendering helpers.
-- is_inside_dw_selection stays in main.lua (DW nav) — injected via render_helpers.
render_helpers = {}
render_utils.init(FSM, Options, Diagnostic, render_helpers)

-- dw_esc — ESC policy, neutral cursor, and selection reset helpers.
-- dw_osd/drum_osd are populated after overlay creation below.
local dw_esc_helpers = { get_center_index = get_center_index }
dw_esc.init(FSM, Options, Tracks, dw_esc_helpers)

local function sync_ctrl_pending_list()
    dw_esc.sync_ctrl_pending_list()
end

local function dw_capture_neutral_marker()
    dw_esc.capture_neutral_marker()
end

local function dw_get_esc_mode()
    return dw_esc.get_esc_mode()
end

local function dw_is_neutral_policy_enabled()
    return dw_esc.is_neutral_policy_enabled()
end

local function dw_resolve_neutral_cursor_line()
    return dw_esc.resolve_neutral_cursor_line()
end

local function dw_resolve_null_activation_line(ctx, dir, subs)
    return dw_esc.resolve_null_activation_line(ctx, dir, subs)
end

local function dw_reset_selection()
    dw_esc.reset_selection()
end

local function dw_apply_post_transition_selection(target_word)
    dw_esc.apply_post_transition_selection(target_word)
end

-- UI State pointers for Drum Mode OSD
drum_osd = mp.create_osd_overlay("ass-events")
drum_osd.res_y = Options.font_base_height
drum_osd.res_x = math.floor(drum_osd.res_y * 16 / 9)
drum_osd.z = 10

dw_osd = mp.create_osd_overlay("ass-events")
dw_osd.res_y = Options.font_base_height
dw_osd.res_x = math.floor(dw_osd.res_y * 16 / 9)
dw_osd.z = 20

-- Populate OSD overlays into dw_esc helpers (created above, read at call time).
dw_esc_helpers.drum_osd = drum_osd
dw_esc_helpers.dw_osd = dw_osd

search_osd = mp.create_osd_overlay("ass-events")
search_osd.res_y = Options.font_base_height
search_osd.res_x = math.floor(search_osd.res_y * 16 / 9)
search_osd.z = 30

dw_tooltip_osd = mp.create_osd_overlay("ass-events")
dw_tooltip_osd.res_y = Options.font_base_height
dw_tooltip_osd.res_x = math.floor(dw_tooltip_osd.res_y * 16 / 9)
dw_tooltip_osd.z = 25

-- tooltip — Drum/SRT/DW Tooltip styling and overlay helpers.
local tooltip_helpers = {
    dw_tooltip_osd = dw_tooltip_osd,
    manage_ui_border_override = function(enable)
        return manage_ui_border_override(enable)
    end,
    DW_TOOLTIP_DRAW_CACHE = DW_TOOLTIP_DRAW_CACHE,
}
tooltip.init(FSM, Options, Tracks, Diagnostic, tooltip_helpers)

-- mouse_input — Hit-testing and mouse tracking logic.
local mouse_input_helpers = {
    dw_osd = dw_osd,
    drum_osd = drum_osd,
    is_inside_dw_selection = function(l, w)
        return is_inside_dw_selection(l, w)
    end,
    ctrl_commit_set = function(line_idx, word_idx)
        return ctrl_commit_set(line_idx, word_idx)
    end,
    dw_anki_export_selection = function()
        return dw_anki_export_selection()
    end,
    show_osd = function(msg, dur)
        return show_osd(msg, dur)
    end,
}
mouse_input.init(FSM, Options, Tracks, Diagnostic, mouse_input_helpers)

-- dw_navigation — Subtitle Window navigation and selection commands.
local dw_navigation_helpers = {
    dw_osd = dw_osd,
    drum_osd = drum_osd,
    dw_tooltip_osd = dw_tooltip_osd,
    set_clipboard = function(text, mode)
        return set_clipboard(text, mode)
    end,
    show_osd = function(msg, dur)
        return show_osd(msg, dur)
    end,
    dw_get_mouse_osd = function()
        return dw_get_mouse_osd()
    end,
    kardenwort_hit_test_all = function(osd_x, osd_y)
        return kardenwort_hit_test_all(osd_x, osd_y)
    end,
    protect_internal_replay_seek = function()
        return protect_internal_replay_seek()
    end,
    dw_sync_cursor_to_mouse = function()
        return dw_sync_cursor_to_mouse()
    end,
}
dw_navigation.init(FSM, Options, Tracks, Diagnostic, dw_navigation_helpers)

local tick_loop_helpers = {
    dw_osd = dw_osd,
    drum_osd = drum_osd,
    protect_internal_replay_seek = function()
        return protect_internal_replay_seek()
    end,
    show_osd = function(msg, dur)
        return show_osd(msg, dur)
    end,
}
tick_loop_module.init(FSM, Options, Tracks, Diagnostic, tick_loop_helpers)

help_osd_bg = mp.create_osd_overlay("ass-events")
help_osd_bg.res_y = Options.font_base_height
help_osd_bg.res_x = math.floor(help_osd_bg.res_y * 16 / 9)
help_osd_bg.z = 100

help_osd_title = mp.create_osd_overlay("ass-events")
help_osd_title.res_y = Options.font_base_height
help_osd_title.res_x = math.floor(help_osd_title.res_y * 16 / 9)
help_osd_title.z = 101

help_osd_1 = mp.create_osd_overlay("ass-events")
help_osd_1.res_y = Options.font_base_height
help_osd_1.res_x = math.floor(help_osd_1.res_y * 16 / 9)
help_osd_1.z = 102

help_osd_2 = mp.create_osd_overlay("ass-events")
help_osd_2.res_y = Options.font_base_height
help_osd_2.res_x = math.floor(help_osd_2.res_y * 16 / 9)
help_osd_2.z = 103

-- Expose help overlays to the help_hud module.
help_helpers.help_osd_bg = help_osd_bg
help_helpers.help_osd_title = help_osd_title
help_helpers.help_osd_1 = help_osd_1
help_helpers.help_osd_2 = help_osd_2

function cmd_cycle_copy_mode()
    if FSM.MEDIA_STATE == "NO_SUBS" then
        show_osd("Copy Mode: No subtitles loaded")
        return
    end
    local has_sec = (Tracks.sec.id ~= 0 and Tracks.sec.subs and #Tracks.sec.subs > 0)
        or (FSM.DW_TOOLTIP_SEC_SUBS and #FSM.DW_TOOLTIP_SEC_SUBS > 0)
    if not has_sec then
        show_osd("Copy Mode: Fixed to Primary (Single Track)")
        return
    end
    FSM.COPY_MODE = (FSM.COPY_MODE == "A") and "B" or "A"

    local label = (FSM.COPY_MODE == "A") and "A (Primary/Target)" or "B (Secondary/Translation)"
    show_osd("Copy Subtitle Mode: " .. label)
end

function cmd_cycle_dw_esc_mode()
    local order = {
        "auto_follow_current",
        "neutral_last_selection",
        "neutral_current_subtitle",
    }
    local labels = {
        auto_follow_current = "AUTO FOLLOW CURRENT",
        neutral_last_selection = "NEUTRAL LAST SELECTION",
        neutral_current_subtitle = "NEUTRAL CURRENT SUBTITLE",
    }
    local current = dw_get_esc_mode()
    local next_idx = 1
    for i, mode in ipairs(order) do
        if mode == current then
            next_idx = (i % #order) + 1
            break
        end
    end
    Options.dw_esc_mode = order[next_idx]
    show_osd("DW Esc Mode: " .. (labels[Options.dw_esc_mode] or Options.dw_esc_mode))
end

function cmd_cycle_immersion_mode()
    if FSM.IMMERSION_MODE == "PHRASE" then
        FSM.IMMERSION_MODE = "MOVIE"
    else
        FSM.IMMERSION_MODE = "PHRASE"
        -- Synchronize ACTIVE_IDX to prevent phantom "Jerk Back" on mode switch
        local time_pos = mp.get_property_number("time-pos") or 0
        local subs = Tracks.pri.subs
        if subs and #subs > 0 then
            FSM.ACTIVE_IDX = get_center_index(subs, time_pos)
        end
        if Tracks.sec.subs and #Tracks.sec.subs > 0 then
            FSM.SEC_ACTIVE_IDX = get_center_index(Tracks.sec.subs, time_pos)
        end
    end
    show_osd("Immersion Mode: " .. FSM.IMMERSION_MODE)
end

function cmd_toggle_copy_ctx()
    if FSM.MEDIA_STATE == "NO_SUBS" then
        show_osd("Context Copy: No subtitles loaded")
        return
    end
    if not Tracks.pri.path and not Tracks.sec.path then
        show_osd("Context Copy: Requires external subtitle files")
        return
    end
    FSM.COPY_CONTEXT = (FSM.COPY_CONTEXT == "OFF") and "ON" or "OFF"
    show_osd("Context Copy: " .. FSM.COPY_CONTEXT)
end

local function cmd_open_record_file()
    local path = get_tsv_path()
    if not path then
        mp.msg.info("OPEN-RECORD: no media loaded")
        return
    end

    local f = io.open(path, "r")
    if not f then
        mp.msg.info("OPEN-RECORD: file not found: " .. tostring(path))
        show_osd("No record file found")
        return
    end
    f:close()

    local editor = Options.record_editor
    if not editor or editor == "" then
        mp.msg.info("OPEN-RECORD: record_editor not configured")
        show_osd("Set kardenwort-record_editor in mpv.conf")
        return
    end

    mp.msg.info("OPEN-RECORD: launching [" .. editor .. "] with [" .. path .. "]")
    mp.command_native_async({
        name = "subprocess",
        args = { editor, path },
        playback_only = false,
        detach = true,
    }, function(success, result, err)
        if err then
            mp.msg.warn("OPEN-RECORD error: " .. tostring(err))
        end
    end)
end
-- Centralized cache invalidation for all rendering layers.
-- INVARIANT: DRUM_DRAW_CACHE and DW_DRAW_CACHE are captured by upvalue.
-- They MUST be defined at module scope before this function is called at runtime,
-- otherwise the cache flushing will silently fail.
local function flush_rendering_caches()
    FSM.ANKI_VERSION = (FSM.ANKI_VERSION or 0) + 1
    FSM.LAYOUT_VERSION = (FSM.LAYOUT_VERSION or 0) + 1

    -- Invalidate top-level ASS result caches
    FSM.DW_LAYOUT_CACHE = nil

    -- Reset sentinel fields to force mismatch in draw high-level caches
    if DRUM_DRAW_CACHE then
        DRUM_DRAW_CACHE.center_idx = -1
        DRUM_DRAW_CACHE.is_drum = false
    end

    if DW_DRAW_CACHE then
        DW_DRAW_CACHE.view_center = -1
    end

    if DW_TOOLTIP_DRAW_CACHE then
        DW_TOOLTIP_DRAW_CACHE.target_idx = -1
        DW_TOOLTIP_DRAW_CACHE.osd_y = -1
        DW_TOOLTIP_DRAW_CACHE.version = -1
        DW_TOOLTIP_DRAW_CACHE.cl = -1
        DW_TOOLTIP_DRAW_CACHE.cw = -1
        DW_TOOLTIP_DRAW_CACHE.av = -1
        DW_TOOLTIP_DRAW_CACHE.result = ""
        DW_TOOLTIP_DRAW_CACHE.hit_zones = nil
    end
    -- Keep forced tooltip visible across cache flushes; next tick re-renders.
    if not FSM.DW_TOOLTIP_FORCE then
        apply_tooltip_ass("")
    end
end

-- tsv_export calls flush_rendering_caches after TSV load/save; expose
-- it via the helpers table (read at call time by the module).
tsv_helpers.flush_rendering_caches = flush_rendering_caches

local get_tooltip_line_y = tooltip.get_tooltip_line_y
local clear_tooltip_overlay = tooltip.clear_tooltip_overlay
local is_osd_tooltip_mode_eligible = tooltip.is_osd_tooltip_mode_eligible
local invalidate_dw_tooltip_cache = tooltip.invalidate_dw_tooltip_cache

normalize_tooltip_native_box_policy = tooltip.normalize_tooltip_native_box_policy
get_tooltip_parent_mode = tooltip.get_tooltip_parent_mode
build_tooltip_style_context = tooltip.build_tooltip_style_context
apply_tooltip_ass = tooltip.apply_tooltip_ass

-- ===============================================================================
-- FONT SCALING AND MEDIA STATE MANAGEMENT
-- ===============================================================================

-- Dynamic font scaling: adjusts sub-scale for SRT, bypasses for ASS
local function update_font_scale()
    local dim = mp.get_property_native("osd-dimensions")
    if not dim or dim.h == 0 then
        return
    end

    local is_ass = false
    local track_list = mp.get_property_native("track-list")

    if track_list then
        for _, track in ipairs(track_list) do
            if track.type == "sub" and track.selected then
                if track.codec == "ass" or track.codec == "ssa" then
                    is_ass = true
                end
                break
            end
        end
    end

    if is_ass then
        mp.set_property_number("sub-scale", 1.0)
    else
        local comp_scale = 1.0
        if dim.h < Options.font_base_height then
            local perfect_comp = Options.font_base_height / dim.h
            comp_scale = 1.0 + (perfect_comp - 1.0) * Options.font_scale_strength
        end
        mp.set_property_number("sub-scale", comp_scale * Options.font_base_scale)
    end
end

-- Media state: track discovery, subtitle loading, ASS gatekeeping, TSV sync
local function update_media_state()
    Tracks.pri.id = mp.get_property_number("sid", 0)
    Tracks.sec.id = mp.get_property_number("secondary-sid", 0)

    local old_pri_path = Tracks.pri.path
    local old_sec_path = Tracks.sec.path

    Tracks.pri.is_ass = false
    Tracks.sec.is_ass = false
    Tracks.pri.path = nil
    Tracks.sec.path = nil

    local track_list = mp.get_property_native("track-list") or {}

    for _, t in ipairs(track_list) do
        if t.type == "sub" then
            local is_ass = false
            local path = nil

            if t.external and t["external-filename"] then
                path = t["external-filename"]
                if path:lower():match("%.ass$") or path:lower():match("%.ssa$") then
                    is_ass = true
                else
                    is_ass = (t.codec == "ass" or t.codec == "ssa")
                end
            else
                is_ass = (t.codec == "ass" or t.codec == "ssa")
            end

            if t.id == Tracks.pri.id then
                Tracks.pri.is_ass = is_ass
                Tracks.pri.path = path
            end
            if t.id == Tracks.sec.id then
                Tracks.sec.is_ass = is_ass
                Tracks.sec.path = path
            end
        end
    end

    -- Flush stale drum subs and selection when track path changed or track was disabled
    if Tracks.pri.path ~= old_pri_path then
        Tracks.pri.subs = {}
        FSM.DW_CURSOR_LINE = -1
        FSM.DW_CURSOR_WORD = -1
        FSM.DW_CURSOR_X = nil
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
        FSM.DW_LAYOUT_CACHE = nil
    end
    if Tracks.sec.path ~= old_sec_path then
        if old_sec_path and Tracks.sec.subs and #Tracks.sec.subs > 0 then
            FSM.DW_TOOLTIP_SEC_SUBS = Tracks.sec.subs
            FSM.DW_TOOLTIP_SEC_PATH = old_sec_path
        end
        Tracks.sec.subs = {}
    end

    -- Load subtitles for logic memory if necessary (always eager to support global navigation)
    if Tracks.pri.path and #Tracks.pri.subs == 0 then
        Tracks.pri.subs = load_sub(Tracks.pri.path, Tracks.pri.is_ass)
    end
    if Tracks.sec.path and #Tracks.sec.subs == 0 then
        Tracks.sec.subs = load_sub(Tracks.sec.path, Tracks.sec.is_ass)
        if Tracks.sec.subs and #Tracks.sec.subs > 0 then
            FSM.DW_TOOLTIP_SEC_SUBS = Tracks.sec.subs
            FSM.DW_TOOLTIP_SEC_PATH = Tracks.sec.path
        end
    end

    -- Tooltip cache is empty and secondary track is disabled: pre-load the first eligible external
    -- subtitle as tooltip source so Drum Mode tooltip works without enabling secondary subs first.
    if Tracks.sec.id == 0 and #FSM.DW_TOOLTIP_SEC_SUBS == 0 then
        for _, t in ipairs(track_list) do
            if
                t.type == "sub"
                and t.external
                and t["external-filename"]
                and t.id ~= Tracks.pri.id
            then
                local cpath = t["external-filename"]
                local cis_ass = cpath:lower():match("%.ass$")
                    or cpath:lower():match("%.ssa$")
                    or (t.codec == "ass" or t.codec == "ssa")
                local loaded = load_sub(cpath, cis_ass)
                if loaded and #loaded > 0 then
                    FSM.DW_TOOLTIP_SEC_SUBS = loaded
                    FSM.DW_TOOLTIP_SEC_PATH = cpath
                end
                break
            end
        end
    end

    flush_rendering_caches()

    -- Determine State
    if Tracks.pri.id == 0 and Tracks.sec.id == 0 then
        FSM.MEDIA_STATE = "NO_SUBS"
    elseif Tracks.sec.id == 0 then
        FSM.MEDIA_STATE = Tracks.pri.is_ass and "SINGLE_ASS" or "SINGLE_SRT"
    elseif Tracks.pri.id == 0 then
        FSM.MEDIA_STATE = Tracks.sec.is_ass and "SINGLE_ASS" or "SINGLE_SRT"
    else
        if Tracks.pri.is_ass and Tracks.sec.id ~= 0 and Tracks.sec.is_ass then
            FSM.MEDIA_STATE = "DUAL_ASS"
        elseif not Tracks.pri.is_ass and (Tracks.sec.id == 0 or not Tracks.sec.is_ass) then
            FSM.MEDIA_STATE = "DUAL_SRT"
        else
            FSM.MEDIA_STATE = "DUAL_MIXED"
        end
    end
    -- Load TSV after MEDIA_STATE is resolved so the NO_SUBS guard works correctly.
    -- When no subtitles are found, auto-creation is skipped to avoid creating
    -- empty .tsv files next to media that has no associated subtitles.
    load_anki_tsv()
    update_interactive_bindings()

    -- ASS gatekeeping: disable custom OSD modes in the same transition cycle.
    if FSM.MEDIA_STATE:match("ASS") then
        local had_drum = (FSM.DRUM == "ON")
        local had_dw = (FSM.DRUM_WINDOW ~= "OFF")
        FSM.DRUM = "OFF"
        FSM.DRUM_WINDOW = "OFF"
        FSM.DW_TOOLTIP_FORCE = false

        -- Restore native subtitle presentation from FSM desired state.
        mp.set_property_bool("sub-visibility", FSM.native_sub_vis)
        mp.set_property_bool("secondary-sub-visibility", FSM.native_sec_sub_vis)
        mp.set_property_number("secondary-sub-pos", FSM.native_sec_sub_pos)

        drum_osd.data = ""
        drum_osd:update()
        dw_osd.data = ""
        dw_osd:update()
        clear_tooltip_overlay("ass-gatekeeping")
        update_interactive_bindings()

        if had_drum or had_dw then
            show_osd("Custom OSD: AUTO-DISABLED (ASS Track Loaded)", Options.osd_duration + 1.0)
        end
    end
end

-- Semantic pass helpers and DW selection predicate (injected into render_utils)
-- ===============================================================================

local function is_ignorable_for_semantic_pass(text)
    if not text then
        return true
    end
    if text:match("^%s*$") then
        return true
    end -- Whitespace
    if text:match("^{") then
        return true
    end -- ASS Tag
    if text == "\\N" or text == "\\n" or text == "\\h" then
        return true
    end -- Line breaks
    return false
end

-- local function is_inside_dw_selection
is_inside_dw_selection = dw_navigation.is_inside_dw_selection

-- Populate render_helpers now that is_inside_dw_selection is defined.
render_helpers.is_inside_dw_selection = is_inside_dw_selection

-- Result cache for draw_drum: skip full ASS rebuild when state is unchanged.
-- Mirrors the DW_DRAW_CACHE pattern used by draw_dw().
-- Must be defined BEFORE sw_helpers.caches captures it, so subtitle_window
-- receives the same table main.lua and flush_rendering_caches operate on.
DRUM_DRAW_CACHE = {
    subs_ptr = nil,
    center_idx = -1,
    highlight_count = 0,
    is_drum = false,
    al = -1,
    aw = -1,
    cl = -1,
    cw = -1,
    pending_version = 0,
    layout_version = 0,
    result = "",
    hit_zones = nil, -- Cached geometry
}

-- draw_dw: view_center = which line is in the center of the viewport
--          active_idx = which line is currently playing (colored blue, may be off-screen)
DW_DRAW_CACHE = {
    view_center = -1,
    active_idx = -1,
    highlight_count = 0,
    subs_ptr = nil,
    layout_version = 0,
    cl = -1,
    cw = -1,
    al = -1,
    aw = -1,
    pending_version = 0,
    result = "",
}

-- subtitle_window — draw_drum / draw_dw / draw_dw_tooltip renderers.
-- Draw caches stay in main.lua (referenced by flush_rendering_caches) and
-- are injected via sw_helpers.caches. build_tooltip_style_context and
-- get_tooltip_parent_mode are injected via sw_helpers.
sw_helpers = {
    caches = {
        DRUM_DRAW_CACHE = DRUM_DRAW_CACHE,
        DW_DRAW_CACHE = DW_DRAW_CACHE,
        DW_TOOLTIP_DRAW_CACHE = DW_TOOLTIP_DRAW_CACHE,
    },
    build_tooltip_style_context = build_tooltip_style_context,
    get_tooltip_parent_mode = get_tooltip_parent_mode,
}
subtitle_window.init(FSM, Options, Tracks, Diagnostic, sw_helpers)
subtitle_window.set_caches(sw_helpers.caches)
draw_drum = subtitle_window.draw_drum
draw_dw = subtitle_window.draw_dw
draw_dw_tooltip = subtitle_window.draw_dw_tooltip

-- ===============================================================================
-- DRUM WINDOW: HIT-TESTING, MOUSE, TOOLTIP, SELECTION, AND RENDER TICK
-- ===============================================================================
-- Hit-testing: OSD coordinate to subtitle line/word resolution
-- local function dw_get_mouse_osd
dw_get_mouse_osd = mouse_input.dw_get_mouse_osd
local dw_hit_test = mouse_input.dw_hit_test
local dw_tooltip_hit_test = mouse_input.dw_tooltip_hit_test
local drum_osd_hit_test = mouse_input.drum_osd_hit_test
local resolve_tooltip_target_line = mouse_input.resolve_tooltip_target_line
-- local function kardenwort_hit_test_all
kardenwort_hit_test_all = mouse_input.kardenwort_hit_test_all
-- local function dw_sync_cursor_to_mouse
dw_sync_cursor_to_mouse = mouse_input.dw_sync_cursor_to_mouse
local dw_mouse_update_selection = mouse_input.dw_mouse_update_selection
local dw_mouse_auto_scroll = mouse_input.dw_mouse_auto_scroll
local cmd_dw_tooltip_pin = mouse_input.cmd_dw_tooltip_pin
local cmd_toggle_dw_tooltip_hover = mouse_input.cmd_toggle_dw_tooltip_hover
local cmd_dw_tooltip_toggle = mouse_input.cmd_dw_tooltip_toggle
local dw_tooltip_mouse_update = mouse_input.dw_tooltip_mouse_update

dw_get_auto_scroll_block_zones = mouse_input.dw_get_auto_scroll_block_zones
dw_resolve_neighbor_word = mouse_input.dw_resolve_neighbor_word
get_dw_drag_threshold_px = mouse_input.get_dw_drag_threshold_px
get_dw_mouse_auto_scroll_interval = mouse_input.get_dw_mouse_auto_scroll_interval
dw_pointer_exceeded_drag_threshold = mouse_input.dw_pointer_exceeded_drag_threshold


-- Anki export, selection bounds, and Esc staged reset
-- local function dw_anki_export_selection
dw_anki_export_selection = dw_navigation.dw_anki_export_selection

-- local function ctrl_discard_set
local ctrl_discard_set = dw_navigation.ctrl_discard_set

-- local function get_dw_selection_bounds
local get_dw_selection_bounds = dw_navigation.get_dw_selection_bounds

-- Context-Aware Escape: Deterministic staged selection peel-back.
-- Stage 1: Clear Pink Set (ctrl pending set)
-- Stage 2: Clear Yellow Range (if anchor exists and is different from cursor)
-- Stage 3: Clear Yellow Pointer (hides the highlight) and syncs cursor to active line
-- No implicit window close occurs in cmd_dw_esc itself.

-- local function cmd_dw_esc
local cmd_dw_esc = dw_navigation.cmd_dw_esc

-- local function ctrl_toggle_word
local ctrl_toggle_word = dw_navigation.ctrl_toggle_word

-- local function ctrl_commit_set
ctrl_commit_set = dw_navigation.ctrl_commit_set

local make_mouse_handler = mouse_input.make_mouse_handler
local MOUSE_HANDLERS = mouse_input.MOUSE_HANDLERS
local cmd_dw_mouse_select = mouse_input.cmd_dw_mouse_select
local cmd_dw_mouse_select_shift = mouse_input.cmd_dw_mouse_select_shift
local cmd_dw_export_anki = mouse_input.cmd_dw_export_anki


-- local function cmd_dw_add_smart
local cmd_dw_add_smart = dw_navigation.cmd_dw_add_smart

-- local function cmd_dw_toggle_pink
local cmd_dw_toggle_pink = dw_navigation.cmd_dw_toggle_pink

-- local function dw_handle_double_click_target
local dw_handle_double_click_target = dw_navigation.dw_handle_double_click_target

-- local function cmd_dw_double_click
local cmd_dw_double_click = dw_navigation.cmd_dw_double_click

-- Tick renderers: Drum Window and Drum Mode per-frame rendering
-- local function tick_dw
local tick_dw = tick_loop_module.tick_dw

-- local function tick_drum
local tick_drum = tick_loop_module.tick_drum

-- ===============================================================================
-- AUTOPAUSE, LOOP, AND REPLAY TICK CONTROLLERS
-- ===============================================================================

-- local function tick_autopause
local tick_autopause = tick_loop_module.tick_autopause

function protect_internal_replay_seek()
    FSM.IGNORE_NEXT_JUMP = true
    local replay_seconds = (Options.replay_ms or 0) / 1000
    FSM.INTERNAL_REPLAY_UNTIL = mp.get_time()
        + math.max(1.0, replay_seconds + Options.nav_cooldown + 0.5)
end

-- local function tick_loop
local tick_loop = tick_loop_module.tick_loop

-- local function tick_scheduled_replay
local tick_scheduled_replay = tick_loop_module.tick_scheduled_replay

-- local function master_tick
local master_tick = tick_loop_module.master_tick
mp.add_periodic_timer(Options.tick_rate, master_tick)

-- ===============================================================================
-- COMMAND HANDLERS: TOGGLES, NAVIGATION, REPLAY, AND SEEK
-- ===============================================================================

-- Feature toggle commands
local function cmd_toggle_autopause()
    FSM.AUTOPAUSE = (FSM.AUTOPAUSE == "ON") and "OFF" or "ON"
    if FSM.AUTOPAUSE == "ON" then
        FSM.LOOP_MODE = "OFF"
    else
        FSM.SCHEDULED_REPLAY_START = nil
        FSM.SCHEDULED_REPLAY_END = nil
    end
    show_osd("Autopause: " .. FSM.AUTOPAUSE)
end

local function cmd_toggle_karaoke()
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
    if not FSM.MEDIA_STATE:match("ASS") then
        show_osd("X")
        return
    end
    FSM.KARAOKE = (FSM.KARAOKE == "WORD") and "PHRASE" or "WORD"
    if FSM.KARAOKE == "WORD" then
        show_osd("Pause Mode: EVERY WORD", Options.osd_duration + 0.5)
    else
        show_osd("Pause Mode: END OF PHRASE")
    end
end

local function cmd_smart_space(table)
    if table.event == "down" then
        FSM.GHOST_HOLD_EXPIRY = nil -- User is physically holding, clear ghost timer
        FSM.PHYSICAL_SPACE_HOLD = true
        if FSM.SPACEBAR == "IDLE" then
            FSM.SPACEBAR = "HOLDING"
            FSM.space_down_time = mp.get_time()
            FSM.initial_pause_state = mp.get_property_bool("pause", true)
            if FSM.initial_pause_state then
                mp.set_property_bool("pause", false)
            end
        end
    elseif table.event == "up" then
        FSM.SPACEBAR = "IDLE"
        FSM.PHYSICAL_SPACE_HOLD = false
        FSM.space_up_time = mp.get_time()
        if (mp.get_time() - FSM.space_down_time) <= Options.space_tap_delay then
            mp.set_property_bool("pause", not FSM.initial_pause_state)
        end
    end
end

local function cmd_toggle_anki_global()
    if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then
        show_osd("X")
        return
    end
    Options.anki_global_highlight = not Options.anki_global_highlight
    show_osd("Anki Global Highlight: " .. (Options.anki_global_highlight and "ON" or "OFF"))
    flush_rendering_caches()
    drum_osd:update()
    if dw_osd then
        dw_osd:update()
    end
end

local function cmd_toggle_drum()
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
    if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then
        show_osd("X")
        return
    end
    if FSM.MEDIA_STATE == "NO_SUBS" then
        show_osd("Drum Mode: No subtitles loaded")
        return
    end
    if FSM.MEDIA_STATE:match("ASS") then
        show_osd("Drum Mode: NOT SUPPORTED (ASS Track)", Options.osd_duration + 1.0)
        return
    end
    if not Tracks.pri.path then
        show_osd("Drum Mode: Requires external subtitle files (.srt)")
        return
    end

    if FSM.DRUM == "OFF" then
        FSM.DRUM = "ON"
        clear_tooltip_overlay("drum-on-transition")
        -- We no longer update FSM.native_sub_vis here because it's managed by cmd_toggle_sub_vis
        -- and would be overwritten by our own suppression logic.

        -- Boot subs for drum memory
        if Tracks.pri.path then
            Tracks.pri.subs = load_sub(Tracks.pri.path, false)
        end
        if Tracks.sec.path then
            Tracks.sec.subs = load_sub(Tracks.sec.path, false)
        end

        show_osd("Drum Mode: ON")
    else
        FSM.DRUM = "OFF"
        FSM.DW_TOOLTIP_FORCE = false
        clear_tooltip_overlay("drum-off-transition")
        show_osd("Drum Mode: OFF")
    end
    update_interactive_bindings()
    flush_rendering_caches()
    -- master_tick handles the sub-visibility property suppression
    drum_osd.data = ""
    drum_osd:update()
end

-- Drum Window scroll and subtitle layout helpers
-- local function cmd_dw_scroll
local cmd_dw_scroll = dw_navigation.cmd_dw_scroll

-- local function cmd_dw_wheel_scroll
local cmd_dw_wheel_scroll = dw_navigation.cmd_dw_wheel_scroll

-- local function ensure_sub_layout
local ensure_sub_layout = dw_navigation.ensure_sub_layout

-- local function dw_get_word_visual_line
local dw_get_word_visual_line = dw_navigation.dw_get_word_visual_line

-- local function dw_closest_word_at_x
local dw_closest_word_at_x = dw_navigation.dw_closest_word_at_x

-- local function dw_pick_middle_word_idx
local dw_pick_middle_word_idx = dw_navigation.dw_pick_middle_word_idx

-- local function get_first_valid_word_idx
local get_first_valid_word_idx = dw_navigation.get_first_valid_word_idx

-- local function dw_compute_word_center_x
local dw_compute_word_center_x = dw_navigation.dw_compute_word_center_x

-- local function dw_ensure_visible
dw_ensure_visible = dw_navigation.dw_ensure_visible

-- Navigation: event snapshots, intent context, line/word movement
-- local function dw_create_nav_event_snapshot
local dw_create_nav_event_snapshot = dw_navigation.dw_create_nav_event_snapshot

-- local function dw_resolve_nav_intent_context
local dw_resolve_nav_intent_context = dw_navigation.dw_resolve_nav_intent_context

-- local function cmd_dw_line_move
local cmd_dw_line_move = dw_navigation.cmd_dw_line_move

-- local function cmd_dw_word_move
local cmd_dw_word_move = dw_navigation.cmd_dw_word_move

-- Replay and seek commands
-- local function cmd_replay_sub
local cmd_replay_sub = dw_navigation.cmd_replay_sub

-- local function cmd_dw_seek_selected
local cmd_dw_seek_selected = dw_navigation.cmd_dw_seek_selected

-- local function cmd_dw_seek_delta
local cmd_dw_seek_delta = dw_navigation.cmd_dw_seek_delta

local function cmd_seek_time(dir)
    local now = mp.get_time()
    local delta = dir * Options.seek_time_delta

    -- YouTube-style Accumulator logic:
    -- Accumulate ONLY if within the time window AND the direction matches.
    -- Otherwise, start a new session.
    local same_dir = (dir > 0 and FSM.SEEK_ACCUMULATOR > 0)
        or (dir < 0 and FSM.SEEK_ACCUMULATOR < 0)
    -- [20260510193230] Extended accumulator window for backward seeks to allow more clicks to accumulate.
    local accumulator_window = (dir < 0) and (Options.seek_osd_duration * 2)
        or Options.seek_osd_duration
    local was_accumulating = (now < FSM.SEEK_LAST_TIME + accumulator_window and same_dir)
    if was_accumulating then
        FSM.SEEK_ACCUMULATOR = FSM.SEEK_ACCUMULATOR + delta
        FSM.SEEK_PRESS_COUNT = FSM.SEEK_PRESS_COUNT + 1
    else
        FSM.SEEK_ACCUMULATOR = delta
        FSM.SEEK_PRESS_COUNT = 1
    end
    FSM.SEEK_LAST_TIME = now

    FSM.IGNORE_NEXT_JUMP = true
    FSM.JUST_JERKED_TO = -1
    FSM.MANUAL_NAV_COOLDOWN = now + Options.nav_cooldown

    -- Time-based seek (Shift+A/D) overrides repeat/loop state.
    -- The user is manually scrubbing the tape; active loops/replays should not survive the seek.
    FSM.LOOP_MODE = "OFF"
    FSM.REPLAY_REMAINING = 0
    FSM.SCHEDULED_REPLAY_START = nil
    FSM.SCHEDULED_REPLAY_END = nil
    FSM.last_paused_sub_end = nil -- Allow autopause to re-arm at the correct boundary after rewind.

    -- Suppress autopause at subtitles encountered during backward rewind transit.
    -- Autopause is inhibited until playback naturally returns past the pre-seek position.
    -- [20260510193230] Track rewind start index to distinguish within-subtitle vs cross-subtitle rewind.
    local current_pos = mp.get_property_number("time-pos") or 0
    local target_pos = math.max(0, current_pos + delta)
    local subs = Tracks.pri.subs
    local current_idx = (subs and #subs > 0) and get_center_index(subs, current_pos) or -1
    local target_idx = (subs and #subs > 0) and get_center_index(subs, target_pos) or -1
    local sec_subs = Tracks.sec.subs
    local sec_target_idx = (sec_subs and #sec_subs > 0) and get_center_index(sec_subs, target_pos)
        or -1
    local is_cross_card_seek = (
        current_idx ~= -1
        and target_idx ~= -1
        and current_idx ~= target_idx
    )

    -- Forward seek clears transit inhibit immediately.
    if delta > 0 then
        FSM.TIMESEEK_INHIBIT_UNTIL = nil
        FSM.REWIND_START_IDX = nil
        FSM.REWIND_TRANSIT_CROSS_CARD = false
    else
        -- Backward seek always contributes to sentinel (legacy contract + tests).
        -- Cross-card classification is tracked separately for suppression gating.
        FSM.TIMESEEK_INHIBIT_UNTIL =
            math.max(FSM.TIMESEEK_INHIBIT_UNTIL or current_pos, current_pos)
        FSM.REWIND_START_IDX = was_accumulating and (FSM.REWIND_START_IDX or current_idx)
            or current_idx
        FSM.REWIND_TRANSIT_CROSS_CARD = (
            was_accumulating and (FSM.REWIND_TRANSIT_CROSS_CARD or is_cross_card_seek)
        ) or is_cross_card_seek
    end

    -- Immediate anchor during Shift+A/D to minimize upper-track perceived lag
    -- before natural sentinel scan catches up after cooldown.
    if target_idx ~= -1 then
        FSM.ACTIVE_IDX = target_idx
        FSM.MANUAL_NAV_TARGET_IDX = target_idx
    end
    if sec_target_idx ~= -1 then
        FSM.SEC_ACTIVE_IDX = sec_target_idx
        FSM.SEC_MANUAL_NAV_TARGET_IDX = sec_target_idx
    end

    mp.commandv("seek", delta, "relative+exact")

    -- Display logic:
    -- Use templates to format the OSD message.
    -- %p = instant prefix, %v = instant value
    -- %P = accumulator prefix, %V = accumulator value
    local prefix = (delta > 0) and "+" or "-"
    local delta_val = math.abs(delta)
    local delta_str = (delta_val % 1 == 0) and tostring(math.floor(delta_val))
        or string.format("%.1f", delta_val)

    local acc_prefix = (FSM.SEEK_ACCUMULATOR > 0) and "+" or "-"
    local acc_val = math.abs(FSM.SEEK_ACCUMULATOR)
    if acc_val < 0.001 then
        acc_val = 0
        acc_prefix = ""
    end
    local acc_str = (acc_val % 1 == 0) and tostring(math.floor(acc_val))
        or string.format("%.1f", acc_val)

    local template = (Options.seek_show_accumulator and FSM.SEEK_PRESS_COUNT >= 1)
            and Options.seek_msg_cumulative_format
        or Options.seek_msg_format

    -- On first press of an accumulator session, we might want to use the standard template
    -- but the user specified +2 -> +4 logic, so we use cumulative_format if accumulator is enabled.
    -- To allow "%p%v (%P%V)" style, we provide all variables to both.
    local msg = template
        :gsub("%%p", prefix)
        :gsub("%%v", delta_str)
        :gsub("%%P", acc_prefix)
        :gsub("%%V", acc_str)

    local alignment = (delta > 0) and 6 or 4
    show_seek_osd(msg, alignment)
end

local function cmd_seek_with_repeat(dir, table)
    if not table or not table.event then
        -- Fallback for simple calls if any
        cmd_dw_seek_delta(dir)
        return
    end

    if table.event == "press" then
        -- Synthetic event from script-binding or input.conf trigger (no down/up pair).
        cmd_dw_seek_delta(dir)
    elseif table.event == "down" then
        -- Initial press
        FSM.DW_SEEKING_MANUALLY = true
        cmd_dw_seek_delta(dir)

        -- Setup repeat timer
        if FSM.SEEK_REPEAT_TIMER then
            FSM.SEEK_REPEAT_TIMER:kill()
        end
        FSM.SEEK_REPEAT_TIMER = mp.add_timeout(Options.seek_hold_delay, function()
            FSM.SEEK_REPEAT_TIMER = mp.add_periodic_timer(1.0 / Options.seek_hold_rate, function()
                cmd_dw_seek_delta(dir)
            end)
        end)
    elseif table.event == "up" then
        FSM.DW_SEEKING_MANUALLY = false
        FSM.DW_SEEK_TARGET = -1
        if FSM.SEEK_REPEAT_TIMER then
            FSM.SEEK_REPEAT_TIMER:kill()
            FSM.SEEK_REPEAT_TIMER = nil
        end
    end
end

manage_dw_bindings = function(enable_mouse, enable_kb)
    local function nav(fn, key_name)
        return function(t)
            local key = (t and t.key) or key_name or ""
            if not (key == "Ctrl" or key == "Shift" or key == "Alt" or key == "Meta") then
                FSM.DW_MOUSE_LOCK_UNTIL = mp.get_time() + (Options.dw_mouse_shield_ms / 1000)
            end
            return fn(t)
        end
    end

    local keys = {}

    -- 1. Definitive Keyboard Navigation Group
    local kb_keys = {
        {
            key = "LEFT",
            name = "dw-word-left",
            fn = nav(function(t)
                cmd_dw_word_move(-1, false, false, t)
            end, "LEFT"),
        },
        {
            key = "RIGHT",
            name = "dw-word-right",
            fn = nav(function(t)
                cmd_dw_word_move(1, false, false, t)
            end, "RIGHT"),
        },
        {
            key = "UP",
            name = "dw-line-up",
            fn = nav(function(t)
                cmd_dw_line_move(-1, false, t)
            end, "UP"),
        },
        {
            key = "DOWN",
            name = "dw-line-down",
            fn = nav(function(t)
                cmd_dw_line_move(1, false, t)
            end, "DOWN"),
        },
        {
            key = "WHEEL_UP",
            name = "dw-scroll-up",
            fn = function()
                cmd_dw_wheel_scroll(-1)
            end,
        },
        {
            key = "WHEEL_DOWN",
            name = "dw-scroll-down",
            fn = function()
                cmd_dw_wheel_scroll(1)
            end,
        },
        {
            key = Options.dw_key_pair_mod,
            name = "dw-pair-mod-track",
            fn = nav(function(t)
                FSM.DW_CTRL_HELD = (t.event == "down" or t.event == "repeat")
            end, Options.dw_key_pair_mod),
            complex = true,
        },
        {
            key = "ЛЕВЫЙ",
            name = "dw-word-left-ru",
            fn = nav(function(t)
                cmd_dw_word_move(-1, false, false, t)
            end, "ЛЕВЫЙ"),
        },
        {
            key = "ПРАВЫЙ",
            name = "dw-word-right-ru",
            fn = nav(function(t)
                cmd_dw_word_move(1, false, false, t)
            end, "ПРАВЫЙ"),
        },
        {
            key = "ВВЕРХ",
            name = "dw-line-up-ru",
            fn = nav(function(t)
                cmd_dw_line_move(-1, false, t)
            end, "ВВЕРХ"),
        },
        {
            key = "ВНИЗ",
            name = "dw-line-down-ru",
            fn = nav(function(t)
                cmd_dw_line_move(1, false, t)
            end, "ВНИЗ"),
        },
    }

    for _, k in ipairs(kb_keys) do
        k.is_kb = true
        table.insert(keys, k)
    end

    -- 2. Definitive Mouse Interaction Group
    local mouse_keys = {
        {
            key = Options.dw_key_select_extend,
            name = "dw-mouse-select-shift",
            fn = cmd_dw_mouse_select_shift,
            complex = true,
        },
        { key = Options.dw_key_mouse_seek, name = "dw-mouse-dblclick", fn = cmd_dw_double_click },
    }
    for _, k in ipairs(mouse_keys) do
        k.is_mouse = true
        table.insert(keys, k)
    end

    local function parse_and_collect(
        key_string,
        base_name,
        mouse_fn,
        key_fn,
        updates_selection,
        complex
    )
        if not key_string or key_string == "" then
            return
        end
        local i = 1
        local expanded_keys = expand_ru_keys(key_string, base_name)
        for _, key in ipairs(expanded_keys) do
            if key ~= "" then
                local is_mouse = key:find("MBTN_") or key:find("WHEEL")
                if is_mouse then
                    local m_fn = nil
                    if type(mouse_fn) == "function" and MOUSE_HANDLERS[mouse_fn] then
                        -- Reuse prebuilt mouse handlers directly (legacy behavior).
                        -- Wrapping them again changes drag/follow semantics.
                        m_fn = mouse_fn
                    elseif mouse_fn then
                        m_fn = make_mouse_handler(false, function(t)
                            mouse_fn(t, true)
                        end, function(t)
                            mouse_fn(t, true)
                        end, updates_selection)
                    elseif key_fn then
                        -- Fallback for mouse-bound actions that only define keyboard handlers.
                        -- Trigger on release to mimic click semantics and avoid nil callbacks.
                        m_fn = function(t)
                            if t and t.event == "up" then
                                key_fn(t, true)
                            end
                        end
                    end

                    if m_fn then
                        table.insert(keys, {
                            key = key,
                            name = base_name .. "-" .. i,
                            fn = m_fn,
                            complex = true,
                            is_mouse = true,
                        })
                    end
                else
                    table.insert(keys, {
                        key = key,
                        name = base_name .. "-" .. i,
                        fn = function(t)
                            local k = (t and t.key) or ""
                            if not (k == "Ctrl" or k == "Shift" or k == "Alt" or k == "Meta") then
                                FSM.DW_MOUSE_LOCK_UNTIL = mp.get_time()
                                    + (Options.dw_mouse_shield_ms / 1000)
                            end
                            key_fn(t, false)
                        end,
                        complex = complex or false,
                        is_kb = true,
                    })
                end
                i = i + 1
            end
        end
    end

    -- DW dynamic binding schema. Each row maps one option-string to a binding:
    --   opt              : Options[opt] is the user-configurable key spec (e.g. "MBTN_LEFT")
    --   name             : base binding name (suffixed with "-<i>" for multi-key specs)
    --   mouse_fn/key_fn  : callbacks for mouse vs keyboard variants of the key spec
    --   updates_selection: only meaningful for mouse handlers; controls anchor/drag wiring
    --   complex          : forces the binding into mpv's complex (event-table) mode
    -- Note: replay is handled via the global "replay-subtitle" binding (no DW-local duplicate).
    local dw_jump_words = Options.dw_jump_words
    local dw_jump_lines = Options.dw_jump_lines
    local binding_defs = {
        {
            opt = "dw_key_add",
            name = "dw-add",
            mouse_fn = cmd_dw_export_anki,
            key_fn = cmd_dw_add_smart,
            updates_selection = true,
        },
        {
            opt = "dw_key_pair",
            name = "dw-pair",
            mouse_fn = cmd_dw_toggle_pink,
            key_fn = cmd_dw_toggle_pink,
            updates_selection = true,
        },
        {
            opt = "dw_key_select",
            name = "dw-select",
            mouse_fn = cmd_dw_mouse_select,
            key_fn = function() end,
            updates_selection = true,
        },
        {
            opt = "dw_key_tooltip_pin",
            name = "dw-tooltip-pin",
            mouse_fn = cmd_dw_tooltip_pin,
            key_fn = cmd_dw_tooltip_pin,
        },
        {
            opt = "dw_key_tooltip_hover",
            name = "dw-tooltip-hover",
            mouse_fn = cmd_toggle_dw_tooltip_hover,
            key_fn = cmd_toggle_dw_tooltip_hover,
        },
        {
            opt = "dw_key_tooltip_toggle",
            name = "dw-tooltip-toggle",
            mouse_fn = cmd_dw_tooltip_toggle,
            key_fn = cmd_dw_tooltip_toggle,
        },
        {
            opt = "dw_key_seek_prev",
            name = "dw-seek-prev",
            key_fn = function(t)
                cmd_seek_with_repeat(-1, t)
            end,
            complex = true,
        },
        {
            opt = "dw_key_seek_next",
            name = "dw-seek-next",
            key_fn = function(t)
                cmd_seek_with_repeat(1, t)
            end,
            complex = true,
        },
        {
            opt = "dw_key_search",
            name = "dw-search",
            key_fn = function()
                cmd_toggle_search()
            end,
        },
        {
            opt = "dw_key_copy",
            name = "dw-copy",
            key_fn = function()
                cmd_dw_copy("none")
            end,
        },
        {
            opt = "key_copy_popup",
            name = "dw-copy-popup",
            key_fn = function()
                cmd_dw_copy("side")
            end,
        },
        {
            opt = "key_copy_main",
            name = "dw-copy-main",
            key_fn = function()
                cmd_dw_copy("main")
            end,
        },
        {
            opt = "dw_key_seek",
            name = "dw-seek",
            key_fn = function()
                cmd_dw_seek_selected()
            end,
        },
        {
            opt = "dw_key_esc",
            name = "dw-esc",
            key_fn = function()
                cmd_dw_esc()
            end,
        },
        {
            opt = "dw_key_jump_left",
            name = "dw-jump-left",
            key_fn = function()
                cmd_dw_word_move(-dw_jump_words, false)
            end,
        },
        {
            opt = "dw_key_jump_right",
            name = "dw-jump-right",
            key_fn = function()
                cmd_dw_word_move(dw_jump_words, false)
            end,
        },
        {
            opt = "dw_key_jump_select_left",
            name = "dw-jump-select-left",
            key_fn = function()
                cmd_dw_word_move(-dw_jump_words, true)
            end,
        },
        {
            opt = "dw_key_jump_select_right",
            name = "dw-jump-select-right",
            key_fn = function()
                cmd_dw_word_move(dw_jump_words, true)
            end,
        },
        {
            opt = "dw_key_scroll_up",
            name = "dw-scroll-up-ctrl",
            key_fn = function()
                cmd_dw_scroll(-1)
            end,
        },
        {
            opt = "dw_key_scroll_down",
            name = "dw-scroll-down-ctrl",
            key_fn = function()
                cmd_dw_scroll(1)
            end,
        },
        {
            opt = "dw_key_jump_select_up",
            name = "dw-jump-select-up",
            key_fn = function()
                cmd_dw_line_move(-dw_jump_lines, true)
            end,
        },
        {
            opt = "dw_key_jump_select_down",
            name = "dw-jump-select-down",
            key_fn = function()
                cmd_dw_line_move(dw_jump_lines, true)
            end,
        },
        {
            opt = "dw_key_select_left",
            name = "dw-select-left",
            key_fn = function()
                cmd_dw_word_move(-1, true)
            end,
        },
        {
            opt = "dw_key_select_right",
            name = "dw-select-right",
            key_fn = function()
                cmd_dw_word_move(1, true)
            end,
        },
        {
            opt = "dw_key_select_up",
            name = "dw-select-up",
            key_fn = function()
                cmd_dw_line_move(-1, true)
            end,
        },
        {
            opt = "dw_key_select_down",
            name = "dw-select-down",
            key_fn = function()
                cmd_dw_line_move(1, true)
            end,
        },
        {
            opt = "dw_key_open_record",
            name = "dw-open-record",
            key_fn = cmd_open_record_file,
        },
        {
            opt = "dw_key_cycle_esc_mode",
            name = "dw-cycle-esc-mode",
            key_fn = cmd_cycle_dw_esc_mode,
        },
        {
            opt = "dw_key_cycle_copy_mode",
            name = "dw-cycle-copy-mode",
            key_fn = cmd_cycle_copy_mode,
        },
        {
            opt = "dw_key_toggle_copy_context",
            name = "dw-toggle-copy-context",
            key_fn = cmd_toggle_copy_ctx,
        },
    }

    for _, d in ipairs(binding_defs) do
        parse_and_collect(
            Options[d.opt],
            d.name,
            d.mouse_fn,
            d.key_fn,
            d.updates_selection,
            d.complex
        )
    end

    for _, k in ipairs(keys) do
        local active = (k.is_mouse and enable_mouse) or (k.is_kb and enable_kb)
        if active and k.key and is_valid_mpv_key(k.key) and type(k.fn) == "function" then
            if not (k.key == "Ctrl" or k.key == "Shift" or k.key == "Alt" or k.key == "Meta") then
                local wrapped_fn = function(t)
                    return k.fn(t)
                end

                if k.complex then
                    mp.add_forced_key_binding(k.key, k.name, wrapped_fn, { complex = true })
                else
                    local settings = nil
                    if
                        k.key:match("LEFT")
                        or k.key:match("RIGHT")
                        or k.key:match("UP")
                        or k.key:match("DOWN")
                        or k.key:match("ЛЕВЫЙ")
                        or k.key:match("ПРАВЫЙ")
                        or k.key:match("ВВЕРХ")
                        or k.key:match("ВНИЗ")
                        or k.key == "ENTER"
                        or k.key == "KP_ENTER"
                    then
                        settings = "repeatable"
                    end
                    mp.add_forced_key_binding(k.key, k.name, wrapped_fn, settings)
                end
            end
        else
            mp.remove_key_binding(k.name)
        end
    end

    -- Cleanup Dragging & Window state
    if not enable_mouse then
        FSM.DW_MOUSE_DRAGGING = false
        FSM.DW_MOUSE_PENDING_DRAG = false
        mp.remove_key_binding("dw-mouse-drag")
        if FSM.DW_MOUSE_SCROLL_TIMER then
            ---@diagnostic disable-next-line: undefined-field
            FSM.DW_MOUSE_SCROLL_TIMER:kill()
            FSM.DW_MOUSE_SCROLL_TIMER = nil
        end
        if FSM.DW_NATIVE_WINDOW_DRAGGING ~= nil then
            mp.set_property_bool("window-dragging", FSM.DW_NATIVE_WINDOW_DRAGGING)
        end
        -- Flush tooltip if interaction was lost
        if not enable_kb then
            clear_tooltip_overlay("bindings-disabled")
        end
    else
        if FSM.DW_NATIVE_WINDOW_DRAGGING == nil then
            FSM.DW_NATIVE_WINDOW_DRAGGING = mp.get_property_bool("window-dragging", true)
        end
        mp.set_property_bool("window-dragging", false)
    end
    FSM.DW_KEY_OVERRIDE = enable_kb
end

function update_interactive_bindings()
    local dw_on = (FSM.DRUM_WINDOW ~= "OFF")
    local osd_on = (FSM.DRUM == "ON" or (not Tracks.pri.is_ass and #Tracks.pri.subs > 0))
        and Options.osd_interactivity

    local need_mouse = dw_on or osd_on
    local need_kb = dw_on or osd_on

    manage_dw_bindings(need_mouse, need_kb)
end

-- ===============================================================================
-- CLIPBOARD, OSD OVERRIDES, AND MODE TOGGLES
-- ===============================================================================

-- local function set_clipboard
set_clipboard = function(text, mode)
    if text and text ~= "" then
        mp.set_property("user-data/kardenwort/last_clipboard", text)
    end
    -- Native property is unreliable on some Windows MPV builds for system-wide sync.
    -- We skip it on Windows to ensure PowerShell (which handles retries/encoding) is used.
    local platform = package.config:sub(1, 1)
    if platform ~= "\\" then
        local success = pcall(function()
            mp.set_property("clipboard", text)
        end)
        if success then
            return
        end
    end
    if platform == "\\" then
        local safe_txt = text:gsub("'", "''")
        local cmd = string.format(
            "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; for ($i=0; $i -lt %d; $i++) { try { Set-Clipboard -Value '%s' -ErrorAction Stop; break } catch { Start-Sleep -Milliseconds %d } }",
            Options.win_clipboard_retries,
            safe_txt,
            Options.win_clipboard_retry_delay
        )
        utils.subprocess({
            args = { "powershell", "-NoProfile", "-Command", cmd },
            cancellable = false,
        })
    else
        local un = io.popen("uname -a")
        local uname_str = un and un:read("*a") or ""
        if un then
            un:close()
        end
        uname_str = uname_str:lower()

        local cmd = ""
        if uname_str:find("darwin") then
            cmd = "pbcopy"
        elseif
            uname_str:find("android")
            or (os.getenv("PREFIX") and os.getenv("PREFIX"):find("com.termux"))
        then
            cmd = "termux-clipboard-set"
        elseif os.getenv("WAYLAND_DISPLAY") then
            cmd = "wl-copy"
        else
            cmd =
                "xclip -selection clipboard -i 2>/dev/null || xsel --clipboard --input 2>/dev/null"
        end

        if cmd ~= "" then
            local f = io.popen(cmd, "w")
            if f then
                f:write(text)
                f:close()
            end
        end
    end

    -- Optional explicit trigger for GoldenDict scan popup.
    -- This bypasses AHK polling latency by directly notifying the dictionary tool.
    -- Robust GoldenDict trigger (Improved layout/modifier stability)
    -- Professional Layout-Independent Trigger (VK-based)
    local user_hotkey = nil
    if
        Options.gd_trigger_enabled == "yes"
        and platform == "\\"
        and (mode == "side" or mode == "main")
    then
        user_hotkey = (mode == "main") and Options.gd_hotkey_main or Options.gd_hotkey_popup
    elseif
        Options.tts_trigger_enabled == "yes"
        and platform == "\\"
        and mode
        and mode:match("^tts_[1-8]$")
    then
        user_hotkey = Options["tts_hotkey_" .. mode:match("([1-8])$")]
    end
    if user_hotkey and user_hotkey ~= "" then
        -- Expanded VK mapping for layout-independent triggers
        local vk_codes = {
            ctrl = 0x11,
            alt = 0x12,
            shift = 0x10,
            win = 0x5B,
            a = 0x41,
            b = 0x42,
            c = 0x43,
            d = 0x44,
            e = 0x45,
            f = 0x46,
            g = 0x47,
            h = 0x48,
            i = 0x49,
            j = 0x4A,
            k = 0x4B,
            l = 0x4C,
            m = 0x4D,
            n = 0x4E,
            o = 0x4F,
            p = 0x50,
            q = 0x51,
            r = 0x52,
            s = 0x53,
            t = 0x54,
            u = 0x55,
            v = 0x56,
            w = 0x57,
            x = 0x58,
            y = 0x59,
            z = 0x5A,
            ["0"] = 0x30,
            ["1"] = 0x31,
            ["2"] = 0x32,
            ["3"] = 0x33,
            ["4"] = 0x34,
            ["5"] = 0x35,
            ["6"] = 0x36,
            ["7"] = 0x37,
            ["8"] = 0x38,
            ["9"] = 0x39,
            f1 = 0x70,
            f2 = 0x71,
            f3 = 0x72,
            f4 = 0x73,
            f5 = 0x74,
            f6 = 0x75,
            f7 = 0x76,
            f8 = 0x77,
            f9 = 0x78,
            f10 = 0x79,
            f11 = 0x7A,
            f12 = 0x7B,
            -- Cyrillic equivalents (ЙЦУКЕН)
            ["й"] = 0x51,
            ["ц"] = 0x57,
            ["у"] = 0x45,
            ["к"] = 0x52,
            ["е"] = 0x54,
            ["н"] = 0x59,
            ["г"] = 0x55,
            ["ш"] = 0x49,
            ["щ"] = 0x4F,
            ["з"] = 0x50,
            ["ф"] = 0x41,
            ["ы"] = 0x53,
            ["в"] = 0x44,
            ["а"] = 0x46,
            ["п"] = 0x47,
            ["р"] = 0x48,
            ["о"] = 0x4A,
            ["л"] = 0x4B,
            ["д"] = 0x4C,
            ["я"] = 0x5A,
            ["ч"] = 0x58,
            ["с"] = 0x43,
            ["м"] = 0x56,
            ["и"] = 0x42,
            ["т"] = 0x4E,
            ["ь"] = 0x4D,
            ["б"] = 0xBC,
            ["ю"] = 0xBE,
        }

        local all_events = {}
        for hotkey in user_hotkey:gmatch("[^%s,;]+") do
            local primary = hotkey:lower()
            local events = {}
            local modifiers = { "ctrl", "alt", "shift", "win" }

            -- Handle implicit shift from uppercase keys (e.g. "Ctrl+Alt+Q")
            local main_key = hotkey:match("[^+]+$")
            local needs_shift = (main_key and #main_key == 1 and main_key:match("%u"))
                or primary:find("shift")

            for _, mod in ipairs(modifiers) do
                if mod ~= "shift" and primary:find(mod) then
                    table.insert(events, { vk_codes[mod], 0 })
                end
            end
            if needs_shift then
                table.insert(events, { vk_codes.shift, 0 })
            end

            -- Get the main key (the last part)
            local key = main_key:lower()
            if key and vk_codes[key] then
                table.insert(events, { vk_codes[key], 0 }) -- Down
                table.insert(events, { vk_codes[key], 2 }) -- Up
            end

            -- Release modifiers in reverse order
            for i = #events - 1, 1, -1 do
                if events[i][2] == 0 then
                    table.insert(events, { events[i][1], 2 })
                end
            end

            for _, ev in ipairs(events) do
                table.insert(all_events, ev)
            end
        end

        if #all_events == 0 then
            return
        end

        -- Configurable Trigger Lock (Prevent AHK Recursion)
        local now = mp.get_time()
        if (now - (FSM.LAST_TRIGGER_TIME or 0)) < Options.gd_trigger_lock_duration then
            -- A trigger was recently fired, likely by the user.
            -- Any subsequent ^c from AHK should just update the clipboard without re-triggering.
            return
        end
        FSM.LAST_TRIGGER_TIME = now

        -- Independent Mode Delays (Popup/Main)
        if Options.gd_trigger_method == "python" then
            local delay = (mode == "main") and Options.python_trigger_delay_main
                or Options.python_trigger_delay_popup
            local py_cmd = string.format(
                "import ctypes, time; time.sleep(%f); u=ctypes.windll.user32; ",
                delay
            )
            for _, ev in ipairs(all_events) do
                py_cmd = py_cmd .. string.format("u.keybd_event(0x%X,0,%d,0); ", ev[1], ev[2])
            end
            mp.command_native_async({
                name = "subprocess",
                args = { Options.python_path, "-c", py_cmd },
                playback_only = false,
                capture_stdout = false,
                capture_stderr = false,
            }, function() end)
        else
            -- Robust VK Injector via PowerShell Add-Type (Default)
            local type_name = "Win32K" .. os.time()
            local signature =
                '[DllImport("user32.dll")] public static extern void keybd_event(byte b, byte s, uint f, uint e);'
            local script = string.format(
                "$t = Add-Type -MemberDefinition '%s' -Name '%s' -Namespace 'Win32' -PassThru;",
                signature,
                type_name
            )

            for _, ev in ipairs(all_events) do
                script = script .. string.format("$t::keybd_event(0x%X,0,%d,0);", ev[1], ev[2])
            end

            mp.command_native_async({
                name = "subprocess",
                args = { "powershell", "-NoProfile", "-Command", script },
                playback_only = false,
                capture_stdout = false,
                capture_stderr = false,
            }, function() end)
        end
    end
end

render_search = function()
    if not FSM.SEARCH_MODE then
        search_osd.data = ""
        search_osd:update()
        return
    end
    search_osd.data = search.draw_search_ui()
    search_osd:update()
end

-- Expose render_search to help_hud (help toggle clears search overlay).
help_helpers.render_search = render_search

-- UI border override and volume suspension helpers
function apply_border_override_state()
    local saved = FSM.saved_osd_border_style
        or mp.get_property("options/osd-border-style")
        or "background-box"
    if FSM.volume_suspension_active or FSM.console_active then
        -- Temporarily restore native style
        if saved and saved ~= "" then
            local cur = mp.get_property("osd-border-style")
            if cur ~= saved then
                mp.set_property("osd-border-style", saved)
                FSM.osd_border_style = saved
            end
        end
    else
        -- Apply the override to outline-and-shadow
        if (FSM.ui_border_override_depth or 0) > 0 then
            local cur = mp.get_property("osd-border-style")
            if cur == "background-box" then
                FSM.saved_osd_border_style = "background-box"
                mp.set_property("osd-border-style", "outline-and-shadow")
                FSM.osd_border_style = "outline-and-shadow"
            end
        else
            -- Restore saved
            if saved and saved ~= "" then
                local cur = mp.get_property("osd-border-style")
                if cur ~= saved then
                    mp.set_property("osd-border-style", saved)
                    FSM.osd_border_style = saved
                end
            end
            FSM.saved_osd_border_style = nil
        end
    end
end

function manage_ui_border_override(enable)
    if enable then
        FSM.ui_border_override_depth = (FSM.ui_border_override_depth or 0) + 1
        if FSM.ui_border_override_depth > 1 then
            return
        end
        apply_border_override_state()
    else
        FSM.ui_border_override_depth = math.max(0, (FSM.ui_border_override_depth or 0) - 1)
        if FSM.ui_border_override_depth > 0 then
            return
        end
        apply_border_override_state()
    end
end

local function trigger_volume_suspension()
    if not FSM.saved_osd_border_style then
        return
    end
    FSM.volume_suspension_active = true
    apply_border_override_state()

    if FSM.volume_suspension_timer then
        FSM.volume_suspension_timer:kill()
    end
    FSM.volume_suspension_timer = mp.add_timeout(2.0, function()
        FSM.volume_suspension_active = false
        apply_border_override_state()
    end)
end

-- Populate search_helpers now that all injected functions are defined.
search_helpers.wrap_tokens = wrap_tokens
search_helpers.dw_get_mouse_osd = dw_get_mouse_osd
search_helpers.manage_ui_border_override = manage_ui_border_override
search_helpers.manage_dw_bindings = manage_dw_bindings
search_helpers.update_interactive_bindings = update_interactive_bindings
search_helpers.render_search = render_search
search_helpers.show_osd = show_osd

-- Drum Window, Book Mode, and copy commands
function cmd_toggle_drum_window()
    -- Snapshot FSM state before any mutation so we can roll back on error
    local prev_drum_window = FSM.DRUM_WINDOW
    local ok, err = xpcall(function()
        if FSM.MEDIA_STATE == "NO_SUBS" then
            show_osd("Drum Window: No subtitles loaded")
            return
        end
        -- Support both external (path-based) and internal (loaded into memory) tracks.
        -- If no subs are in memory and no path exists, we truly can't open.
        if not Tracks.pri.path and #Tracks.pri.subs == 0 then
            show_osd("Drum Window: requires loaded subtitles")
            return
        end

        if FSM.DRUM_WINDOW == "OFF" then
            -- Update state immediately for responsiveness
            FSM.DRUM_WINDOW = "DOCKED"
            flush_rendering_caches()
            clear_tooltip_overlay("drum-window-open-transition")
            manage_ui_border_override(true)

            -- Refresh TSV before opening: catches any mid-session file deletion or clearing.
            load_anki_tsv(true)

            -- Snapshot and hide all subtitle overlays to prevent overlap
            FSM.DW_SAVED_SUB_VIS = FSM.native_sub_vis
            FSM.DW_SAVED_DRUM_STATE = FSM.DRUM

            -- Hide native subs (for compatibility and to ensure they are off)
            mp.set_property_bool("sub-visibility", false)
            mp.set_property_bool("secondary-sub-visibility", false)

            -- Always hide drum_osd, as it now renders both Drum and Regular SRT modes
            drum_osd.data = ""
            drum_osd:update()

            local time_pos = mp.get_property_number("time-pos") or 0
            local active_idx = get_center_index(Tracks.pri.subs, time_pos)
            if not active_idx or active_idx == -1 then
                active_idx = 1
            end

            local has_pointer = (FSM.DW_CURSOR_WORD and FSM.DW_CURSOR_WORD ~= -1)
            local has_range = (
                FSM.DW_ANCHOR_LINE
                and FSM.DW_ANCHOR_LINE ~= -1
                and FSM.DW_ANCHOR_WORD
                and FSM.DW_ANCHOR_WORD ~= -1
            )
            local has_pending = (FSM.DW_CTRL_PENDING_LIST and #FSM.DW_CTRL_PENDING_LIST > 0)

            if has_pointer or has_range or has_pending then
                if FSM.DW_CURSOR_LINE == -1 then
                    FSM.DW_CURSOR_LINE = active_idx
                end
            else
                -- Opening without an explicit pointer/selection should anchor to playback,
                -- not a stale historical cursor line.
                FSM.DW_CURSOR_LINE = active_idx
                FSM.DW_CURSOR_WORD = -1
                FSM.DW_ANCHOR_LINE = -1
                FSM.DW_ANCHOR_WORD = -1
                FSM.DW_CURSOR_X = nil
            end

            -- Always sync view center to the resolved opening cursor line
            FSM.DW_VIEW_CENTER = (FSM.DW_CURSOR_LINE and FSM.DW_CURSOR_LINE ~= -1)
                    and FSM.DW_CURSOR_LINE
                or active_idx

            FSM.DW_SEEKING_MANUALLY = false
            FSM.DW_SEEK_TARGET = -1
            FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
            -- [20260501163905] DO NOT reset CURSOR_WORD/ANCHOR here to allow cross-mode synchronization
            FSM.DW_FOLLOW_PLAYER = true

            if not FSM.SEARCH_MODE then
                update_interactive_bindings()
            end

            -- Explicitly trigger first render for instant appearance
            if FSM.DRUM_WINDOW == "DOCKED" then
                tick_dw(time_pos, active_idx)
                show_osd("Drum Window: ON")
            end
        else
            -- Update state immediately
            FSM.DRUM_WINDOW = "OFF"
            FSM.DW_TOOLTIP_FORCE = false
            flush_rendering_caches()
            clear_tooltip_overlay("drum-window-close-transition")
            manage_ui_border_override(false)

            if not FSM.SEARCH_MODE then
                update_interactive_bindings()
            end
            dw_osd.data = ""
            dw_osd:update()

            -- Force synchronization of all cursor and viewport states to the current playhead
            local time_pos = mp.get_property_number("time-pos") or 0
            local active_idx = get_center_index(Tracks.pri.subs, time_pos)
            if active_idx and active_idx ~= -1 then
                FSM.DW_CURSOR_LINE = active_idx
                FSM.DW_VIEW_CENTER = active_idx
                FSM.ACTIVE_IDX = active_idx
                FSM.DW_ACTIVE_LINE = active_idx
            end
            FSM.DW_CURSOR_WORD = -1
            FSM.DW_ANCHOR_LINE = -1
            FSM.DW_ANCHOR_WORD = -1
            FSM.DW_CURSOR_X = nil
            FSM.DW_FOLLOW_PLAYER = true

            -- Restore subtitle visibility
            FSM.native_sub_vis = FSM.DW_SAVED_SUB_VIS
            show_osd("Drum Window: OFF")
        end
    end, debug.traceback)
    if not ok then
        -- Roll back FSM state to prevent phantom window open/close on next toggle
        FSM.DRUM_WINDOW = prev_drum_window
        Diagnostic.error("Drum Window Toggle: " .. tostring(err))
        show_osd("kardenwort ERROR: " .. tostring(err):sub(1, 100))
    end
end

function toggle_book_mode()
    FSM.BOOK_MODE = not FSM.BOOK_MODE
    if FSM.BOOK_MODE then
        -- Keep DM workflows in-place: only auto-open DW when neither DM nor DW is active.
        if FSM.DRUM_WINDOW == "OFF" and FSM.DRUM ~= "ON" then
            cmd_toggle_drum_window()
        end
        show_osd("Book Mode: ON")
    else
        show_osd("Book Mode: OFF")
    end
end

-- local function get_clipboard_text_smart
local get_clipboard_text_smart = dw_navigation.get_clipboard_text_smart

-- local function cmd_dw_copy
function cmd_dw_copy(mode)
    return dw_navigation.cmd_dw_copy(mode)
end

-- Subtitle visibility, track cycling, and position adjustment
local function cmd_toggle_sub_vis()
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
    local function capture_sub_vis_combo()
        if FSM.SEC_ONLY_MODE then
            return "top"
        end
        if FSM.native_sub_vis and FSM.native_sec_sub_vis then
            return "both"
        end
        if FSM.native_sub_vis and not FSM.native_sec_sub_vis then
            return "bottom"
        end
        return "both"
    end

    local function apply_sub_vis_combo(combo)
        local mode = combo or "both"
        if mode == "top" then
            FSM.SEC_ONLY_MODE = true
            FSM.native_sub_vis = true
            FSM.native_sec_sub_vis = true
        elseif mode == "bottom" then
            FSM.SEC_ONLY_MODE = false
            FSM.native_sub_vis = true
            FSM.native_sec_sub_vis = false
        else
            FSM.SEC_ONLY_MODE = false
            FSM.native_sub_vis = true
            FSM.native_sec_sub_vis = true
        end
    end

    local turning_off = FSM.native_sub_vis

    -- We don't set mpv's sub-visibility to 'true' here because master_tick
    -- would immediately set it back to 'false' to render our styled OSD.
    -- If user wants to DISABLE subs, we set it to false for safety.
    if turning_off then
        FSM.SUB_VIS_COMBO_BEFORE_OFF = capture_sub_vis_combo()
        FSM.SEC_ONLY_MODE = false
        FSM.native_sub_vis = false
        FSM.native_sec_sub_vis = false
        mp.set_property_bool("sub-visibility", false)
        mp.set_property_bool("secondary-sub-visibility", false)
        -- [20260509192327] Dismiss tooltip immediately when subs are hidden.
        -- is_osd_tooltip_mode_eligible() checks native_sub_vis, so the tooltip
        -- is no longer eligible. Clear it defensively here rather than waiting
        -- for the next dw_tooltip_mouse_update() tick to do it.
        FSM.DW_TOOLTIP_FORCE = false
        clear_tooltip_overlay("sub-vis-off")
    else
        apply_sub_vis_combo(FSM.SUB_VIS_COMBO_BEFORE_OFF)
    end

    show_osd("Subtitles: " .. (turning_off and "OFF" or "ON"))
    master_tick()
end

local function has_available_secondary_track()
    local tracks = mp.get_property_native("track-list") or {}
    local primary_sid = tonumber(mp.get_property("sid") or 0) or 0
    for _, t in ipairs(tracks) do
        if t.type == "sub" and t.external then
            local tid = tonumber(t.id)
            if tid and tid ~= 0 and tid ~= primary_sid then
                return true
            end
        end
    end
    return false
end

local function ensure_secondary_track_selected()
    local current_sid = tonumber(mp.get_property("secondary-sid") or 0) or 0
    if current_sid ~= 0 then
        return true
    end

    local tracks = mp.get_property_native("track-list") or {}
    local primary_sid = tonumber(mp.get_property("sid") or 0) or 0
    local fallback_sid = nil
    for _, t in ipairs(tracks) do
        if t.type == "sub" and t.external then
            local tid = tonumber(t.id)
            if tid and tid ~= 0 and tid ~= primary_sid then
                fallback_sid = tid
                break
            end
        end
    end

    if fallback_sid then
        mp.set_property_number("secondary-sid", fallback_sid)
        FSM.__auto_track_selected_sec = true
        return true
    end
    return false
end

local function cmd_toggle_secondary_only_mode()
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
    if not has_available_secondary_track() then
        show_osd("X")
        Diagnostic.info("Secondary Only requested, but no secondary subtitle track is available")
        return
    end

    FSM.SEC_ONLY_MODE = not FSM.SEC_ONLY_MODE
    if FSM.SEC_ONLY_MODE then
        ensure_secondary_track_selected()
        -- Force master subtitles ON, but render only secondary via SEC_ONLY_MODE.
        FSM.native_sub_vis = true
        FSM.native_sec_sub_vis = true
        show_osd("Secondary Sub Only: ON")
    else
        -- Exit to normal master-on state.
        FSM.native_sub_vis = true
        FSM.native_sec_sub_vis = true
        show_osd("Secondary Sub Only: OFF")
    end
    master_tick()
end

local function cmd_cycle_sec_pos()
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
    if not FSM.native_sub_vis then
        show_osd("X")
        return
    end
    if Tracks.sec.id == 0 then
        local has_available_secondary = has_available_secondary_track()
        show_osd("X")
        if not has_available_secondary then
            Diagnostic.info(
                "Secondary Sub Pos requested, but no secondary subtitle track is available"
            )
        end
        return
    end
    if Tracks.sec.is_ass then
        show_osd("Secondary Sub Pos: Not available (ASS controls positioning)")
        return
    end
    if FSM.DRUM == "ON" then
        FSM.native_sec_sub_pos = (FSM.native_sec_sub_pos < 50) and Options.sec_pos_bottom
            or Options.sec_pos_top
        mp.set_property_number("secondary-sub-pos", FSM.native_sec_sub_pos)
        show_osd("Secondary Sub Pos: " .. ((FSM.native_sec_sub_pos < 50) and "TOP" or "BOTTOM"))
    else
        local p = mp.get_property_number("secondary-sub-pos", Options.sec_pos_top)
        local n = (p < 50) and Options.sec_pos_bottom or Options.sec_pos_top
        mp.set_property_number("secondary-sub-pos", n)
        FSM.native_sec_sub_pos = n
        show_osd("Secondary Sub Pos: " .. ((n < 50) and "TOP" or "BOTTOM"))
    end
end

local function cmd_adjust_sub_pos(delta)
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
    if not FSM.native_sub_vis then
        show_osd("X")
        return
    end
    local p = mp.get_property_number("sub-pos", 95)
    mp.set_property_number("sub-pos", math.max(0, math.min(150, p + delta)))
end

local function cmd_adjust_sec_sub_pos(delta)
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
    if not FSM.native_sub_vis then
        show_osd("X")
        return
    end
    local p = mp.get_property_number("secondary-sub-pos", 10)
    local new_pos = math.max(0, math.min(150, p + delta))
    mp.set_property_number("secondary-sub-pos", new_pos)
    FSM.native_sec_sub_pos = new_pos
end

local function cmd_cycle_sec_sid()
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
    if not FSM.native_sub_vis then
        show_osd("X")
        return
    end
    -- Prevent contradictory state overlays: while Secondary Sub Only mode is active,
    -- blocking OFF/cycle on secondary sid keeps the mode deterministic.
    if FSM.SEC_ONLY_MODE then
        show_osd("X")
        return
    end
    FSM.native_sec_sub_vis = true
    -- [20260509180045] Synchronous Suppression: Prevent flash of native subs before next tick.
    local use_osd_for_srt = (
        Options.srt_font_name ~= ""
        or Options.srt_font_bold
        or Options.srt_font_size > 0
    )
    local sec_use_osd = (FSM.DRUM == "ON") or (not Tracks.sec.is_ass and use_osd_for_srt)
    if sec_use_osd then
        mp.set_property_bool("secondary-sub-visibility", false)
    else
        mp.set_property_bool("secondary-sub-visibility", true)
    end

    FSM.__auto_track_selected_sec = true

    local tracks = mp.get_property_native("track-list") or {}
    local current_sid = tonumber(mp.get_property("secondary-sid") or 0) or 0
    local primary_sid = tonumber(mp.get_property("sid") or 0) or 0

    -- Filter for supported tracks (External files only)
    local supported = { 0 } -- Always include OFF (0)
    local internal_count = 0
    for _, t in ipairs(tracks) do
        if t.type == "sub" then
            if t.external then
                local tid = tonumber(t.id)
                -- Skip the track that is already selected as primary to avoid conflicts
                if tid and tid ~= primary_sid then
                    table.insert(supported, tid)
                end
            else
                internal_count = internal_count + 1
            end
        end
    end
    table.sort(supported)

    if #supported <= 1 then
        local msg = "Secondary Subtitles: None available"
        if internal_count > 0 then
            msg = msg .. " [" .. internal_count .. " built-in unsupported]"
        end
        show_osd(msg)
        mp.set_property("secondary-sid", "no")
        return
    end

    -- Dynamically initialize last_sec_sid and prev_sec_sid history if not set
    if not FSM.last_sec_sid then
        local supported_active = {}
        for _, t in ipairs(tracks) do
            if t.type == "sub" and t.external then
                local tid = tonumber(t.id)
                if tid and tid ~= primary_sid then
                    table.insert(supported_active, tid)
                end
            end
        end
        table.sort(supported_active)
        FSM.last_sec_sid = supported_active[1] or 0
        FSM.prev_sec_sid = supported_active[2] or supported_active[1] or 0
    end

    -- Update history if current active track shifted outside of our script actions
    if current_sid ~= 0 and current_sid ~= FSM.last_sec_sid then
        FSM.prev_sec_sid = FSM.last_sec_sid
        FSM.last_sec_sid = current_sid
    end

    local now = mp.get_time()
    local elapsed = now - (FSM.last_sec_sub_cycle_time or 0)
    local threshold = tonumber(Options.sub_switch_threshold) or 1.0

    local next_sid = 0
    if elapsed > threshold then
        -- Slow tap: toggle behavior
        if FSM.prev_sec_sid == 0 or FSM.prev_sec_sid == FSM.last_sec_sid then
            -- Toggle between active and OFF
            if current_sid == 0 then
                next_sid = FSM.last_sec_sid
            else
                next_sid = 0
            end
        else
            -- Toggle between the last two active tracks
            if current_sid == FSM.last_sec_sid then
                next_sid = FSM.prev_sec_sid
            else
                next_sid = FSM.last_sec_sid
            end
        end
    else
        -- Rapid tap: cycle through all tracks sequentially
        local found = false
        for i = 1, #supported do
            if supported[i] == current_sid then
                next_sid = supported[i % #supported + 1]
                found = true
                break
            end
        end
        if not found then
            next_sid = supported[2] or 0
        end
    end

    FSM.last_sec_sub_cycle_time = now

    -- Validate that chosen next_sid exists in supported list, fallback to supported[2] if not
    local next_sid_valid = false
    for _, sid in ipairs(supported) do
        if sid == next_sid then
            next_sid_valid = true
            break
        end
    end
    if not next_sid_valid then
        next_sid = supported[2] or 0
    end

    if next_sid == 0 then
        mp.set_property("secondary-sid", "no")
    else
        mp.set_property_number("secondary-sid", next_sid)

        -- Update the last active tracks history
        if next_sid ~= FSM.last_sec_sid then
            FSM.prev_sec_sid = FSM.last_sec_sid
            FSM.last_sec_sid = next_sid
        end
    end

    local label = "OFF"
    if next_sid ~= 0 then
        for _, t in ipairs(tracks) do
            if t.type == "sub" and tonumber(t.id) == next_sid then
                local path = t["external-filename"] or t["external_filename"] or ""
                local lang_detected = nil

                if path ~= "" then
                    lang_detected = extract_lang_from_title_or_path(t.title, path)
                end
                if not lang_detected and t.title then
                    lang_detected = extract_lang_from_title_or_path(t.title, nil)
                end

                if lang_detected then
                    label = lang_detected
                else
                    local lang_lbl = (t.lang and t.lang ~= "und" and t.lang ~= "unknown")
                            and t.lang:upper()
                        or nil
                    if lang_lbl then
                        label = lang_lbl
                    else
                        label = t.title or "ON"
                        if label:find("%.") then
                            local base_label = label:match("([^%.]+)%.")
                            if base_label then
                                label = base_label
                            end
                        end
                    end
                end
                break
            end
        end
    end

    local final_msg = "Secondary Sub: " .. label
    if internal_count > 0 then
        final_msg = final_msg .. " [" .. internal_count .. " built-in hidden]"
    end
    show_osd(final_msg)
    drum_osd:update()
end

function cmd_cycle_audio()
    ensure_companion_audio_tracks(mp.get_property("path"))

    local tracks = mp.get_property_native("track-list") or {}
    local current_aid = tonumber(mp.get_property("aid") or 0) or 0
    if current_aid == 0 then
        local aid_str = mp.get_property("aid")
        if aid_str == "no" then
            current_aid = 0
        end
    end

    local supported = { 0 }
    local supported_active = {}
    for _, t in ipairs(tracks) do
        if t.type == "audio" then
            local tid = tonumber(t.id)
            if tid then
                table.insert(supported, tid)
                table.insert(supported_active, tid)
            end
        end
    end
    table.sort(supported)
    table.sort(supported_active)

    if #supported <= 1 then
        show_osd("Audio: None available")
        return
    end

    -- Dynamically initialize last_aid and prev_aid history if not set
    if not FSM.last_aid then
        FSM.last_aid = supported_active[1] or 0
        FSM.prev_aid = supported_active[2] or supported_active[1] or 0
    end

    -- Update history if current active track shifted outside of our script actions
    if current_aid ~= 0 and current_aid ~= FSM.last_aid then
        FSM.prev_aid = FSM.last_aid
        FSM.last_aid = current_aid
    end

    local now = mp.get_time()
    local elapsed = now - (FSM.last_audio_cycle_time or 0)
    local threshold = tonumber(Options.audio_switch_threshold) or 1.0

    local next_aid = 0
    if elapsed > threshold then
        -- Slow tap: toggle between last two active tracks
        if current_aid == FSM.last_aid then
            next_aid = FSM.prev_aid
        else
            next_aid = FSM.last_aid
        end
    else
        -- Rapid tap: cycle through all tracks sequentially
        local found = false
        for i = 1, #supported do
            if supported[i] == current_aid then
                next_aid = supported[i % #supported + 1]
                found = true
                break
            end
        end
        if not found then
            next_aid = supported[2] or 0
        end
    end

    if next_aid == 0 then
        mp.set_property("aid", "no")
    else
        mp.set_property_number("aid", next_aid)

        -- Update the last active tracks history
        if next_aid ~= FSM.last_aid then
            FSM.prev_aid = FSM.last_aid
            FSM.last_aid = next_aid
        end
    end

    FSM.last_audio_cycle_time = now

    local label = "OFF"
    if next_aid ~= 0 then
        for _, t in ipairs(tracks) do
            if tonumber(t.id) == next_aid then
                local lang_lbl = (t.lang and t.lang ~= "und" and t.lang ~= "unknown")
                        and t.lang:upper()
                    or nil
                local title_lbl = (t.title and t.title ~= "") and t.title or nil

                if lang_lbl and title_lbl and title_lbl:upper() == lang_lbl then
                    title_lbl = nil
                end

                if (not title_lbl) and t.external then
                    local ext_path = t["external-filename"] or t["external_filename"] or ""
                    if ext_path ~= "" then
                        local ext_file = ext_path:gsub("\\", "/"):match("([^/]+)$") or ""
                        local ext = ext_file:match("%.([^%.]+)$") or ""
                        local ext_stem = ext_file
                        if #ext > 0 then
                            ext_stem = ext_file:sub(1, #ext_file - #ext - 1)
                        end
                        local base_name, postfix = split_base_and_language_postfix(ext_stem)
                        if postfix and base_name and base_name ~= "" then
                            title_lbl = base_name
                        elseif ext_stem ~= "" then
                            title_lbl = ext_stem
                        end
                    end
                end

                if lang_lbl and title_lbl then
                    label = lang_lbl .. " - " .. title_lbl
                elseif lang_lbl then
                    label = lang_lbl
                elseif title_lbl then
                    label = title_lbl
                else
                    label = "TRACK " .. next_aid
                end
                break
            end
        end
    end

    show_osd("Audio: " .. label)
end

local function cmd_toggle_osc()
    FSM.OSC_VIS = (FSM.OSC_VIS + 1) % 3
    local lbl, cmd = "AUTO", "auto"
    if FSM.OSC_VIS == 1 then
        lbl, cmd = "ALWAYS", "always"
    elseif FSM.OSC_VIS == 2 then
        lbl, cmd = "NEVER", "never"
    end
    mp.commandv("script-message", "osc-visibility", cmd, "no-osd")
    show_osd("OSC Visibility: " .. lbl)
end

-- ===============================================================================
-- COPY COMMAND AND SYSTEM EVENT OBSERVERS
-- ===============================================================================

-- Copy subtitle to clipboard (mode: none/side/main/tts_N)
local function cmd_copy_sub(mode)
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then
        return
    end

    local final_text, is_context = get_clipboard_text_smart(time_pos)

    if final_text and final_text ~= "" then
        set_clipboard(final_text, mode)

        local now = mp.get_time()
        if (now - (FSM.LAST_OSD_TIME or 0)) > Options.copy_osd_cooldown then
            local words, wcount = {}, 0
            for w in final_text:gmatch("%S+") do
                if wcount < Options.copy_word_limit then
                    table.insert(words, w)
                end
                wcount = wcount + 1
            end
            local osd_t = table.concat(words, " ")
                .. (wcount > Options.copy_word_limit and "..." or "")
            show_osd("Copied " .. FSM.COPY_MODE .. ": " .. osd_t)
            FSM.LAST_OSD_TIME = now
        end
    else
        show_osd("No subtitle to copy")
    end
end

-- mpv property observers (sid/vid/secondary-sid/sub-visibility/track-list)
mp.observe_property("sid", "number", function(name, val)
    local ok, err = xpcall(update_media_state, debug.traceback)
    if not ok then
        Diagnostic.error("sid observer: " .. tostring(err))
    end
end)
mp.observe_property("vid", "string", function(name, val)
    local ok, err = xpcall(function()
        if val ~= FSM.last_vid then
            local old_vid = FSM.last_vid
            FSM.last_vid = val
            if (not old_vid or old_vid == "no") and (val and val ~= "no") then
                local current_sid = mp.get_property("sid")
                local current_sec_sid = mp.get_property("secondary-sid")
                if current_sid and current_sid ~= "no" then
                    mp.set_property("sid", "no")
                    mp.set_property("sid", current_sid)
                end
                if current_sec_sid and current_sec_sid ~= "no" then
                    mp.set_property("secondary-sid", "no")
                    mp.set_property("secondary-sid", current_sec_sid)
                end
            end
        end
    end, debug.traceback)
    if not ok then
        Diagnostic.error("vid observer: " .. tostring(err))
    end
end)
mp.observe_property("secondary-sid", "number", function(name, val)
    local ok, err = xpcall(update_media_state, debug.traceback)
    if not ok then
        Diagnostic.error("sec-sid observer: " .. tostring(err))
    end

    -- [20260509180045] Immediate Suppression (Window 2): Enforce visibility state after track-list update.
    local use_osd_for_srt = (
        Options.srt_font_name ~= ""
        or Options.srt_font_bold
        or Options.srt_font_size > 0
    )
    local sec_use_osd = FSM.native_sec_sub_vis
        and ((FSM.DRUM == "ON") or (not Tracks.sec.is_ass and use_osd_for_srt))
    if sec_use_osd then
        mp.set_property_bool("secondary-sub-visibility", false)
    end
    drum_osd:update()
end)
mp.observe_property("track-list", "native", function()
    local ok, err = xpcall(update_media_state, debug.traceback)
    if not ok then
        Diagnostic.error("track-list observer: " .. tostring(err))
    end
    if Options.font_scaling_enabled then
        local ok2, err2 = xpcall(update_font_scale, debug.traceback)
        if not ok2 then
            Diagnostic.error("font-scaling: " .. tostring(err2))
        end
    end
end)
mp.observe_property("osd-dimensions", "native", function()
    dw_tooltip_osd:update()
    if Options.font_scaling_enabled then
        local ok, err = xpcall(update_font_scale, debug.traceback)
        if not ok then
            Diagnostic.error("osd-dim observer: " .. tostring(err))
        end
    end
end)

mp.observe_property("pause", "bool", function(name, paused)
    if not paused then
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"
    end
end)

mp.observe_property("script-opts", "string", function()
    options.read_options(Options, "kardenwort")
    validate_config()
    FSM.notice_osd.z = Options.notice_osd_layer
    seek_osd.z = Options.seek_osd_layer
    flush_rendering_caches()
    drum_osd:update()
    if dw_osd then
        dw_osd:update()
    end
end)

mp.observe_property("osd-border-style", "string", function(name, val)
    FSM.osd_border_style = val
    flush_rendering_caches()
    drum_osd:update()
    if dw_osd then
        dw_osd:update()
    end
end)

mp.observe_property("volume", "number", trigger_volume_suspension)
mp.observe_property("mute", "bool", trigger_volume_suspension)

pcall(function()
    mp.observe_property("user-data/mpv/console/open", "bool", function(name, val)
        if FSM then
            FSM.console_active = val
            apply_border_override_state()
        end
    end)
end)

mp.register_event("shutdown", function()
    if FSM.DRUM == "ON" or FSM.DRUM_WINDOW == "DOCKED" then
        mp.set_property_bool("sub-visibility", FSM.native_sub_vis)
        mp.set_property_bool("secondary-sub-visibility", FSM.native_sec_sub_vis)
        mp.set_property_number("secondary-sub-pos", FSM.native_sec_sub_pos)
        manage_dw_bindings(false)
    end
    while (FSM.ui_border_override_depth or 0) > 0 do
        manage_ui_border_override(false)
    end
end)

mp.register_event("file-loaded", function()
    if Options.companion_audio_attach_on_load ~= false then
        ensure_companion_audio_tracks(mp.get_property("path"))
    end
    if Options.companion_subtitle_attach_on_load ~= false then
        ensure_companion_subtitle_tracks(mp.get_property("path"))
    end
    if Options.companion_video_attach_on_load ~= false then
        ensure_companion_video_track(mp.get_property("path"))
    end
end)

-- ===============================================================================
-- INITIALIZATION
-- ===============================================================================
options.read_options(Options, "kardenwort")
validate_config()

-- Key binding registration (names must match input.conf @ bindings)
mp.add_key_binding(nil, "toggle-autopause", cmd_toggle_autopause)

mp.add_key_binding(nil, "toggle-karaoke-mode", cmd_toggle_karaoke)
mp.add_key_binding(nil, "smart-space", cmd_smart_space, { complex = true })
mp.add_key_binding(nil, "toggle-drum-mode", cmd_toggle_drum)
mp.add_key_binding(nil, "toggle-sub-visibility", cmd_toggle_sub_vis)
mp.add_key_binding(nil, "toggle-secondary-only", cmd_toggle_secondary_only_mode)
mp.add_key_binding(nil, "cycle-secondary-pos", cmd_cycle_sec_pos)
mp.add_key_binding(nil, "cycle-sec-sid", cmd_cycle_sec_sid)
mp.add_key_binding(nil, "toggle-osc-visibility", cmd_toggle_osc)
mp.add_key_binding(nil, "copy-subtitle", function()
    cmd_copy_sub("none")
end)
mp.add_key_binding(nil, "copy-subtitle-popup", function()
    cmd_copy_sub("side")
end)
mp.add_key_binding(nil, "copy-subtitle-main", function()
    cmd_copy_sub("main")
end)
mp.add_key_binding(nil, "copy-subtitle-tts-1", function()
    cmd_copy_sub("tts_1")
end)
mp.add_key_binding(nil, "copy-subtitle-tts-2", function()
    cmd_copy_sub("tts_2")
end)
mp.add_key_binding(nil, "copy-subtitle-tts-3", function()
    cmd_copy_sub("tts_3")
end)
mp.add_key_binding(nil, "copy-subtitle-tts-4", function()
    cmd_copy_sub("tts_4")
end)
mp.add_key_binding(nil, "copy-subtitle-tts-5", function()
    cmd_copy_sub("tts_5")
end)
mp.add_key_binding(nil, "copy-subtitle-tts-6", function()
    cmd_copy_sub("tts_6")
end)
mp.add_key_binding(nil, "copy-subtitle-tts-7", function()
    cmd_copy_sub("tts_7")
end)
mp.add_key_binding(nil, "copy-subtitle-tts-8", function()
    cmd_copy_sub("tts_8")
end)

-- Global Ctrl+Alt+C binding for main GoldenDict window
local function register_global_copy_keys()
    local bind = keybinding_utils.bind
    bind(Options.key_copy_popup, "kardenwort-global-copy-side", function()
        cmd_copy_sub("side")
    end, { wrap = true })
    bind(Options.key_copy_main, "kardenwort-global-copy-main", function()
        cmd_copy_sub("main")
    end, { wrap = true })
    bind(Options.key_tts_1, "kardenwort-global-copy-tts-1", function()
        cmd_copy_sub("tts_1")
    end, { wrap = true })
    bind(Options.key_tts_2, "kardenwort-global-copy-tts-2", function()
        cmd_copy_sub("tts_2")
    end, { wrap = true })
    bind(Options.key_tts_3, "kardenwort-global-copy-tts-3", function()
        cmd_copy_sub("tts_3")
    end, { wrap = true })
    bind(Options.key_tts_4, "kardenwort-global-copy-tts-4", function()
        cmd_copy_sub("tts_4")
    end, { wrap = true })
    bind(Options.key_tts_5, "kardenwort-global-copy-tts-5", function()
        cmd_copy_sub("tts_5")
    end, { wrap = true })
    bind(Options.key_tts_6, "kardenwort-global-copy-tts-6", function()
        cmd_copy_sub("tts_6")
    end, { wrap = true })
    bind(Options.key_tts_7, "kardenwort-global-copy-tts-7", function()
        cmd_copy_sub("tts_7")
    end, { wrap = true })
    bind(Options.key_tts_8, "kardenwort-global-copy-tts-8", function()
        cmd_copy_sub("tts_8")
    end, { wrap = true })
end
register_global_copy_keys()
mp.add_key_binding(nil, "cycle-copy-mode", cmd_cycle_copy_mode)
mp.add_key_binding(nil, "toggle-copy-context", cmd_toggle_copy_ctx)
mp.add_key_binding(nil, "toggle-drum-window", cmd_toggle_drum_window)
mp.add_key_binding(nil, "toggle-drum-search", cmd_toggle_search)
mp.add_key_binding(nil, "toggle-book-mode", toggle_book_mode)
mp.add_key_binding(nil, "replay-subtitle", cmd_replay_sub)
mp.add_key_binding(nil, "seek_prev", function(t)
    cmd_seek_with_repeat(-1, t)
end, { complex = true })
mp.add_key_binding(nil, "seek_next", function(t)
    cmd_seek_with_repeat(1, t)
end, { complex = true })

mp.add_key_binding(nil, "seek_time_forward", function()
    cmd_seek_time(1)
end, { repeatable = true })
mp.add_key_binding(nil, "seek_time_backward", function()
    cmd_seek_time(-1)
end, { repeatable = true })
mp.add_key_binding(nil, "toggle-anki-global", cmd_toggle_anki_global)
mp.add_key_binding(nil, "toggle-record-file", cmd_open_record_file)
mp.add_key_binding(nil, "cycle-immersion-mode", cmd_cycle_immersion_mode)
mp.add_key_binding(nil, "toggle-help", cmd_toggle_help)
mp.add_key_binding(nil, "cycle-audio", cmd_cycle_audio)

local function register_global_position_keys()
    local bind = keybinding_utils.bind
    bind(Options.key_sub_pos_up, "kardenwort-sub-pos-up", function()
        cmd_adjust_sub_pos(-1)
    end, { forced = true, wrap = true })
    bind(Options.key_sub_pos_down, "kardenwort-sub-pos-down", function()
        cmd_adjust_sub_pos(1)
    end, { forced = true, wrap = true })
    bind(Options.key_sec_sub_pos_up, "kardenwort-sec-sub-pos-up", function()
        cmd_adjust_sec_sub_pos(-1)
    end, { forced = true, wrap = true })
    bind(Options.key_sec_sub_pos_down, "kardenwort-sec-sub-pos-down", function()
        cmd_adjust_sec_sub_pos(1)
    end, { forced = true, wrap = true })
end
register_global_position_keys()

local function register_global_playback_keys()
    local bind = keybinding_utils.bind
    -- Note: replay-subtitle is handled globally via the named binding in input.conf.
    -- No direct key binding needed here to avoid double-fire collision.
end
register_global_playback_keys()

-- Periodic TSV sync and OSD refresh
if Options.anki_sync_period > 0 then
    mp.add_periodic_timer(Options.anki_sync_period, function()
        local ok, err = xpcall(function()
            find_source_url()
            load_anki_tsv(false, true)
            drum_osd:update()
            if dw_osd then
                dw_osd:update()
            end
        end, debug.traceback)
        if not ok then
            Diagnostic.error("periodic sync: " .. tostring(err))
        end
    end)
end
Diagnostic.info("SCRIPT LOADED SUCCESSFULLY")

-- Safety Net: Recover stuck OSD properties from previous crashes
local function recover_native_osd_style()
    local opt_style = mp.get_property("options/osd-border-style")
    local cur_style = mp.get_property("osd-border-style")
    if opt_style and cur_style and opt_style ~= cur_style then
        mp.set_property("osd-border-style", opt_style)
    end
end
recover_native_osd_style()

-- Global Immersion Mode Toggle (Shift+o / O Щ)
-- Parameterized to allow user overrides via mpv.conf
for k in string.gmatch(Options.key_cycle_immersion_mode, "%S+") do
    mp.add_forced_key_binding(k, "kardenwort-cycle-immersion-" .. k, cmd_cycle_immersion_mode)
end

-- ===============================================================================
-- TEST INSTRUMENTATION (test_hooks.lua)
-- Dormant in production. Activated by IPC script-message-to kardenwort ...
-- ===============================================================================
test_hooks.init(FSM, Options, Tracks, Diagnostic, {
    drum_osd = drum_osd,
    dw_osd = dw_osd,
    dw_tooltip_osd = dw_tooltip_osd,
    search_osd = search_osd,
    seek_osd = seek_osd,
    master_tick = master_tick,
    cmd_adjust_sec_sub_pos = cmd_adjust_sec_sub_pos,
    cmd_toggle_sub_vis = cmd_toggle_sub_vis,
    cmd_toggle_drum_window = cmd_toggle_drum_window,
    cmd_seek_time = cmd_seek_time,
    cmd_dw_word_move = cmd_dw_word_move,
    ctrl_toggle_word = ctrl_toggle_word,
    cmd_dw_esc = cmd_dw_esc,
    cmd_dw_tooltip_toggle = cmd_dw_tooltip_toggle,
    cmd_dw_line_move = cmd_dw_line_move,
    cmd_dw_scroll = cmd_dw_scroll,
    cmd_replay_sub = cmd_replay_sub,
    cmd_dw_seek_delta = cmd_dw_seek_delta,
    cmd_seek_with_repeat = cmd_seek_with_repeat,
    cmd_cycle_sec_sid = cmd_cycle_sec_sid,
    ctrl_commit_set = ctrl_commit_set,
    dw_anki_export_selection = dw_anki_export_selection,
    prepare_export_text = prepare_export_text,
    cmd_dw_copy = cmd_dw_copy,
    utf8_to_table = utf8_to_table,
    update_search_results = update_search_results,
    render_search = render_search,
    build_word_list_internal = build_word_list_internal,
    get_sub_tokens = get_sub_tokens,
    logical_cmp = logical_cmp,
    calculate_highlight_stack = calculate_highlight_stack,
    flush_rendering_caches = flush_rendering_caches,
    load_anki_tsv = load_anki_tsv,
    cmd_dw_tooltip_pin = cmd_dw_tooltip_pin,
    is_osd_tooltip_mode_eligible = is_osd_tooltip_mode_eligible,
    resolve_tooltip_target_line = resolve_tooltip_target_line,
    get_tooltip_line_y = get_tooltip_line_y,
    draw_dw_tooltip = draw_dw_tooltip,
    apply_tooltip_ass = apply_tooltip_ass,
    cmd_dw_toggle_pink = cmd_dw_toggle_pink,
    cmd_open_record_file = cmd_open_record_file,
    dw_handle_double_click_target = dw_handle_double_click_target,
    utf8_truncate = utf8_truncate,
    build_copy_preview = build_copy_preview,
    drum_osd_hit_test = drum_osd_hit_test,
    build_tooltip_style_context = build_tooltip_style_context,
    format_tooltip_card_event = format_tooltip_card_event,
    format_tooltip_text_event = format_tooltip_text_event,
    expand_ru_keys = expand_ru_keys,
    load_sub = load_sub,
    sync_ctrl_pending_list = sync_ctrl_pending_list,
    normalize_key_display = normalize_key_display,
    cmd_toggle_help = cmd_toggle_help,
})
test_hooks.register_all()
