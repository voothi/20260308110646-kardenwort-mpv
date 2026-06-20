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

local mp = require 'mp'
local script_dir = mp.get_script_directory()
if script_dir then
    package.path = script_dir .. "/?.lua;" .. package.path
end

local text_utils = require 'text_utils'
local subtitle_parser = require 'subtitle_parser'
local keybinding_utils = require 'keybinding_utils'
local osd_cards = require 'osd_cards'
local tsv_export = require 'tsv_export'
local companion = require 'companion'
local search = require 'search'
local help_hud = require 'help_hud'
local render_utils = require 'render_utils'
local subtitle_window = require 'subtitle_window'
local test_hooks = require 'test_hooks'
local dw_esc = require 'dw_esc'
local config = require 'config'
local state = require 'state'
local utils = require 'mp.utils'
local options = require 'mp.options'
local msg = require 'mp.msg'

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
            if not val then return def end
            local sub_delay = raw_get_property_number("sub-delay") or 0.0
            return val - sub_delay
        end
        return raw_get_property_number(name, def)
    end

    mp.get_property = function(name, def)
        if name == "time-pos" then
            local val = raw_get_property(name)
            if not val then return def end
            local val_num = tonumber(val)
            if not val_num then return val end
            local sub_delay = raw_get_property_number("sub-delay") or 0.0
            return tostring(val_num - sub_delay)
        end
        return raw_get_property(name, def)
    end

    mp.commandv = function(cmd, ...)
        if cmd == "seek" then
            local args = {...}
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
        if type(fn) == "function" then return true end
        msg.error(string.format("[kardenwort] Skipping invalid %s '%s': callback is %s",
            tostring(kind), tostring(name), type(fn)))
        return false
    end

    mp.add_key_binding = function(key, name, fn, flags)
        if not validate_callback("binding", name or key, fn) then return false end
        raw_add_key_binding(key, name, fn, flags)
        return true
    end

    mp.add_forced_key_binding = function(key, name, fn, flags)
        if not validate_callback("forced binding", name or key, fn) then return false end
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
        if not validate_callback("timeout", seconds, fn) then return nil end
        return raw_add_timeout(seconds, fn)
    end

    ---@param seconds number
    ---@param fn function
    ---@return MpvTimer?
    mp.add_periodic_timer = function(seconds, fn)
        if not validate_callback("periodic timer", seconds, fn) then return nil end
        return raw_add_periodic_timer(seconds, fn)
    end

    mp.register_event = function(name, fn)
        if not validate_callback("event handler", name, fn) then return false end
        raw_register_event(name, fn)
        return true
    end

    mp.observe_property = function(name, ty, fn)
        if not validate_callback("property observer", name, fn) then return false end
        raw_observe_property(name, ty, fn)
        return true
    end

    mp.register_script_message = function(name, fn)
        if not validate_callback("script message", name, fn) then return false end
        raw_register_script_message(name, fn)
        return true
    end
end

require 'resume'

-- Fallback for older mpv versions missing utils.read_file
local function safe_read_file(path)
    if not path or path == "" then return nil end
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

local function alias(mod, names)
    local vals = {}
    for _, name in ipairs(names) do
        assert(mod[name] ~= nil, "FATAL: function '" .. tostring(name) .. "' is missing from module!")
        vals[#vals + 1] = mod[name]
    end
    return table.unpack(vals)
end

-- text_utils aliases
local utf8_to_table, utf8_to_lower, utf8_truncate, is_word_char, is_abbrev,
      logical_cmp, build_word_list_internal, build_word_list, get_sub_tokens,
      is_word_token, clean_text_srt, normalize_inline_break_markers,
      calculate_ass_alpha, build_copy_preview, has_cyrillic
    = alias(text_utils, {
        "utf8_to_table", "utf8_to_lower", "utf8_truncate", "is_word_char", "is_abbrev",
        "logical_cmp", "build_word_list_internal", "build_word_list", "get_sub_tokens",
        "is_word_token", "clean_text_srt", "normalize_inline_break_markers",
        "calculate_ass_alpha", "build_copy_preview", "has_cyrillic"
    })

local L_EPSILON = text_utils.L_EPSILON

-- subtitle_parser aliases
local parse_time, load_sub, find_sub_containing_start, get_center_index,
      get_center_index_static, get_effective_boundaries
    = alias(subtitle_parser, {
        "parse_time", "load_sub", "find_sub_containing_start", "get_center_index",
        "get_center_index_static", "get_effective_boundaries"
    })

-- keybinding_utils aliases
local is_valid_mpv_key, expand_ru_keys
    = alias(keybinding_utils, {"is_valid_mpv_key", "expand_ru_keys"})

-- osd_cards aliases
local show_osd, show_seek_osd
    = alias(osd_cards, {"show_osd", "show_seek_osd"})
local seek_osd  -- forward-declared; assigned from osd_cards.seek_osd after setup()
local tsv_helpers  -- populated at tsv_export init; flush_rendering_caches added later

-- tsv_export aliases
local get_copy_context_text, prepare_export_text, extract_anki_context,
      load_anki_tsv, save_anki_tsv_row, find_source_url, get_tsv_path
    = alias(tsv_export, {
        "get_copy_context_text", "prepare_export_text", "extract_anki_context",
        "load_anki_tsv", "save_anki_tsv_row", "find_source_url", "get_tsv_path"
    })

-- companion aliases
local split_base_and_language_postfix, extract_lang_from_title_or_path,
      ensure_companion_audio_tracks, ensure_companion_subtitle_tracks,
      ensure_companion_video_track
    = alias(companion, {
        "split_base_and_language_postfix", "extract_lang_from_title_or_path",
        "ensure_companion_audio_tracks", "ensure_companion_subtitle_tracks",
        "ensure_companion_video_track"
    })

-- search aliases (forward-declared)
local search_helpers
local cmd_toggle_search
local update_search_results

-- help_hud aliases
local normalize_key_display = help_hud.normalize_key_display
local cmd_toggle_help  -- forward-declared
local help_helpers

-- render_utils aliases
local compose_term_smart, calculate_highlight_stack, populate_token_meta,
      format_highlighted_word, dw_get_str_width_proportional, dw_get_str_width,
      calculate_sub_gap, wrap_tokens, calculate_osd_line_meta, dw_vline_height,
      dw_build_layout, dw_calculate_block_top, format_tooltip_card_event,
      format_tooltip_text_event
    = alias(render_utils, {
        "compose_term_smart", "calculate_highlight_stack", "populate_token_meta",
        "format_highlighted_word", "dw_get_str_width_proportional", "dw_get_str_width",
        "calculate_sub_gap", "wrap_tokens", "calculate_osd_line_meta", "dw_vline_height",
        "dw_build_layout", "dw_calculate_block_top", "format_tooltip_card_event",
        "format_tooltip_text_event"
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
    ERROR = 0, WARN = 1, INFO = 2, DEBUG = 3, TRACE = 4,
    LEVEL_MAP = { ["error"] = 0, ["warn"] = 1, ["info"] = 2, ["debug"] = 3, ["trace"] = 4 },
    SEEN = {}
}

Diagnostic.log = function(level, text, dedupe_key)
    local log_level_str = (Options and Options.log_level) or "info"
    local current_level = Diagnostic.LEVEL_MAP[log_level_str:lower()] or Diagnostic.INFO
    if level > current_level then return end

    if dedupe_key then
        if Diagnostic.SEEN[dedupe_key] then return end
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

Diagnostic.error = function(text, key) Diagnostic.log(Diagnostic.ERROR, text, key) end
Diagnostic.warn  = function(text, key) Diagnostic.log(Diagnostic.WARN, text, key) end
Diagnostic.info  = function(text, key) Diagnostic.log(Diagnostic.INFO, text, key) end
Diagnostic.debug = function(text, key) Diagnostic.log(Diagnostic.DEBUG, text, key) end
Diagnostic.trace = function(text, key) Diagnostic.log(Diagnostic.TRACE, text, key) end

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
    local has_sec = (Tracks.sec.id ~= 0 and Tracks.sec.subs and #Tracks.sec.subs > 0) or
                    (FSM.DW_TOOLTIP_SEC_SUBS and #FSM.DW_TOOLTIP_SEC_SUBS > 0)
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
        args = {editor, path},
        playback_only = false,
        detach = true
    }, function(success, result, err)
        if err then mp.msg.warn("OPEN-RECORD error: " .. tostring(err)) end
    end)
end
-- Centralized cache invalidation for all rendering layers.
-- INVARIANT: DRUM_DRAW_CACHE and DW_DRAW_CACHE are captured by upvalue.
-- They MUST be defined at module scope before this function is called at runtime,
-- otherwise the cache flushing will silently fail.
local apply_tooltip_ass
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

local function invalidate_dw_tooltip_cache()
    if not DW_TOOLTIP_DRAW_CACHE then return end
    DW_TOOLTIP_DRAW_CACHE.target_idx = -1
    DW_TOOLTIP_DRAW_CACHE.osd_y = -1
    DW_TOOLTIP_DRAW_CACHE.version = -1
    DW_TOOLTIP_DRAW_CACHE.cl = -1
    DW_TOOLTIP_DRAW_CACHE.cw = -1
    DW_TOOLTIP_DRAW_CACHE.av = -1
    DW_TOOLTIP_DRAW_CACHE.result = ""
    DW_TOOLTIP_DRAW_CACHE.hit_zones = nil
end

function normalize_tooltip_native_box_policy()
    local policy = tostring(Options.tooltip_native_box_policy or "auto"):lower()
    if policy ~= "auto" and policy ~= "neutralize" and policy ~= "override" then
        return "auto"
    end
    return policy
end

function get_tooltip_parent_mode()
    if FSM.DRUM_WINDOW ~= "OFF" then return "dw" end
    if FSM.DRUM == "ON" then return "dm" end
    return "srt"
end

function build_tooltip_style_context(parent_mode)
    parent_mode = parent_mode or get_tooltip_parent_mode()
    local policy = normalize_tooltip_native_box_policy()
    local style_is_bgbox = (FSM.osd_border_style == "background-box")
    local needs_override = false
    local neutralize_inband = false

    if policy == "override" then
        needs_override = true
    elseif policy == "neutralize" then
        neutralize_inband = style_is_bgbox
    else
        if parent_mode == "dw" then
            needs_override = true
        elseif style_is_bgbox then
            neutralize_inband = true
        end
    end

    if needs_override then
        neutralize_inband = false
    end

    local base_alpha = Options.tooltip_bg_alpha
    if not base_alpha or base_alpha == "" then
        base_alpha = Options.tooltip_bg_opacity
    end

    local card_alpha = base_alpha
    if parent_mode == "dw" then
        card_alpha = (Options.tooltip_dw_bg_alpha and Options.tooltip_dw_bg_alpha ~= "" and Options.tooltip_dw_bg_alpha)
            or card_alpha
    elseif parent_mode == "dm" then
        card_alpha = (Options.tooltip_dm_bg_alpha and Options.tooltip_dm_bg_alpha ~= "" and Options.tooltip_dm_bg_alpha)
            or card_alpha
    elseif parent_mode == "srt" then
        card_alpha = (Options.tooltip_srt_bg_alpha and Options.tooltip_srt_bg_alpha ~= "" and Options.tooltip_srt_bg_alpha)
            or card_alpha
    end

    return {
        parent_mode = parent_mode,
        policy = policy,
        is_bgbox = style_is_bgbox,
        needs_override = needs_override,
        neutralize_inband = neutralize_inband,
        bg_color = Options.tooltip_bg_color,
        bg_alpha = calculate_ass_alpha(base_alpha),
        card_alpha = calculate_ass_alpha(card_alpha),
        bord = Options.tooltip_border_size,
        shad = Options.tooltip_shadow_offset,
    }
end

apply_tooltip_ass = function(ass)
    if not dw_tooltip_osd then return end
    ass = ass or ""
    local will_visible = (ass ~= "")
    local wants_override = false
    if will_visible then
        local style_ctx = build_tooltip_style_context(get_tooltip_parent_mode())
        wants_override = style_ctx.needs_override
    end
    local has_override = (FSM.DW_TOOLTIP_BORDER_OVERRIDE == true)
    if wants_override and not has_override then
        manage_ui_border_override(true)
        has_override = true
    elseif not wants_override and has_override then
        manage_ui_border_override(false)
        has_override = false
    end
    FSM.DW_TOOLTIP_BORDER_OVERRIDE = has_override
    if ass ~= dw_tooltip_osd.data then
        dw_tooltip_osd.data = ass
        dw_tooltip_osd:update()
    end
end

local function clear_tooltip_overlay(reason)
    if reason then
        Diagnostic.debug("TOOLTIP CLEAR: " .. reason)
    end
    FSM.DW_TOOLTIP_LINE = -1
    FSM.DW_TOOLTIP_HIT_ZONES = nil
    FSM.DW_TOOLTIP_LOCKED_LINE = -1
    invalidate_dw_tooltip_cache()
    apply_tooltip_ass("")
end

local function is_osd_tooltip_mode_eligible()
    local use_osd_for_srt = (Options.srt_font_name ~= "" or Options.srt_font_bold or Options.srt_font_size > 0)
    local srt_active = (FSM.DRUM == "OFF" and use_osd_for_srt)

    return (FSM.DRUM == "ON" or srt_active)
        and FSM.DRUM_WINDOW == "OFF"
        and FSM.native_sub_vis
        and not FSM.MEDIA_STATE:match("ASS")
        and Options.osd_interactivity
end

local function get_tooltip_line_y(line_idx, fallback_y)
    if not line_idx or line_idx == -1 then return nil end
    if FSM.DRUM_WINDOW ~= "OFF" then
        return FSM.DW_LINE_Y_MAP[line_idx] or fallback_y
    end
    local fallback_zone_y = nil
    for _, zone in ipairs(FSM.DRUM_HIT_ZONES or {}) do
        if zone.sub_idx == line_idx then
            local zone_center_y = (zone.y_top + zone.y_bottom) / 2
            if zone.is_pri then
                return zone_center_y
            end
            if fallback_zone_y == nil then
                fallback_zone_y = zone_center_y
            end
        end
    end
    return fallback_zone_y or fallback_y
end


-- ===============================================================================
-- FONT SCALING AND MEDIA STATE MANAGEMENT
-- ===============================================================================

-- Dynamic font scaling: adjusts sub-scale for SRT, bypasses for ASS
local function update_font_scale()
    local dim = mp.get_property_native("osd-dimensions")
    if not dim or dim.h == 0 then return end

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
            if t.type == "sub" and t.external and t["external-filename"] and t.id ~= Tracks.pri.id then
                local cpath = t["external-filename"]
                local cis_ass = cpath:lower():match("%.ass$") or cpath:lower():match("%.ssa$") or
                                (t.codec == "ass" or t.codec == "ssa")
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
    if not text then return true end
    if text:match("^%s*$") then return true end -- Whitespace
    if text:match("^{") then return true end    -- ASS Tag
    if text == "\\N" or text == "\\n" or text == "\\h" then return true end -- Line breaks
    return false
end

local function is_inside_dw_selection(l, w)
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
    if al == -1 or cl == -1 or aw == -1 or cw == -1 then return false end

    local p1_l, p1_w, p2_l, p2_w
    if al < cl or (al == cl and aw <= cw) then
        p1_l, p1_w, p2_l, p2_w = al, aw, cl, cw
    else
        p1_l, p1_w, p2_l, p2_w = cl, cw, al, aw
    end

    if l < p1_l or l > p2_l then return false end
    if l == p1_l and w < p1_w - L_EPSILON then return false end
    if l == p2_l and w > p2_w + L_EPSILON then return false end
    return true
end

-- Populate render_helpers now that is_inside_dw_selection is defined.
render_helpers.is_inside_dw_selection = is_inside_dw_selection

-- Result cache for draw_drum: skip full ASS rebuild when state is unchanged.
-- Mirrors the DW_DRAW_CACHE pattern used by draw_dw().
-- Must be defined BEFORE sw_helpers.caches captures it, so subtitle_window
-- receives the same table main.lua and flush_rendering_caches operate on.
DRUM_DRAW_CACHE = {
    subs_ptr = nil, center_idx = -1, highlight_count = 0, is_drum = false,
    al = -1, aw = -1, cl = -1, cw = -1,
    pending_version = 0, layout_version = 0, result = "",
    hit_zones = nil -- Cached geometry
}

-- draw_dw: view_center = which line is in the center of the viewport
--          active_idx = which line is currently playing (colored blue, may be off-screen)
DW_DRAW_CACHE = {
    view_center = -1, active_idx = -1, highlight_count = 0,
    subs_ptr = nil, layout_version = 0,
    cl = -1, cw = -1, al = -1, aw = -1,
    pending_version = 0, result = ""
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
local function dw_get_mouse_osd()
    local mouse = mp.get_property_native("mouse-pos")
    if not mouse then return 960, 540 end
    local mx = mouse.x or 0
    local my = mouse.y or 0
    local osd = mp.get_property_native("osd-dimensions")
    local ow = osd and osd.w or 1920
    local oh = osd and osd.h or 1080
    if ow == 0 then ow = 1920 end
    if oh == 0 then oh = 1080 end

    -- ASS text preserves its aspect ratio by scaling isotropically based on window height.
    -- X coordinate scaling must match the Y scaling (oh / 1080) rather than the window width (ow / 1920),
    -- otherwise horizontal click targets drift outwards when the window aspect ratio != 16:9.
    local scale_isotropic = oh / 1080
    local osd_y = my / scale_isotropic
    local osd_x = 960 + ((mx - (ow / 2)) / scale_isotropic)

    return osd_x, osd_y
end

local function dw_hit_test(osd_x, osd_y)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return nil, nil end

    -- Ensure hit zones are populated. If not, invoke draw_dw to build them.
    if not FSM.DW_HIT_ZONES or #FSM.DW_HIT_ZONES == 0 then
        draw_dw(subs, FSM.DW_VIEW_CENTER, FSM.ACTIVE_IDX)
    end
    if not FSM.DW_HIT_ZONES or #FSM.DW_HIT_ZONES == 0 then
        return nil, nil
    end

    local first_zone = FSM.DW_HIT_ZONES[1]
    local last_zone = FSM.DW_HIT_ZONES[#FSM.DW_HIT_ZONES]

    -- Clamp vertically to the first/last word if outside the entire block
    if osd_y <= first_zone.y_top then
        local word_idx = 1
        if #first_zone.words > 0 then
            word_idx = first_zone.words[1].logical_idx
        end
        return first_zone.sub_idx, word_idx
    end
    if osd_y >= last_zone.y_bottom then
        local word_idx = 1
        if #last_zone.words > 0 then
            word_idx = last_zone.words[#last_zone.words].logical_idx
        else
            local last_sub = subs[last_zone.sub_idx]
            if last_sub then
                local tokens = get_sub_tokens(last_sub) or {}
                local cnt = 0
                for _, t in ipairs(tokens) do
                    if is_word_token(t) then cnt = cnt + 1 end
                end
                word_idx = math.max(1, cnt)
            end
        end
        return last_zone.sub_idx, word_idx
    end

    -- Find the visual line containing osd_y (including inter-subtitle gaps)
    local best_zone = nil
    for idx, zone in ipairs(FSM.DW_HIT_ZONES) do
        if osd_y >= zone.y_top and osd_y <= zone.y_bottom then
            best_zone = zone
            break
        end
        local next_zone = FSM.DW_HIT_ZONES[idx + 1]
        if next_zone and osd_y > zone.y_bottom and osd_y < next_zone.y_top then
            best_zone = zone
            break
        end
    end

    if not best_zone then
        local mid_y = (first_zone.y_top + last_zone.y_bottom) / 2
        best_zone = osd_y < mid_y and first_zone or last_zone
    end

    -- Clamp horizontally if outside the line bounds
    local rel_x = osd_x - best_zone.x_start
    if rel_x <= 0 then
        local word_idx = 1
        if #best_zone.words > 0 then
            word_idx = best_zone.words[1].logical_idx
        end
        return best_zone.sub_idx, word_idx
    end
    if rel_x >= best_zone.total_width then
        local word_idx = 1
        if #best_zone.words > 0 then
            word_idx = best_zone.words[#best_zone.words].logical_idx
        else
            local sub = subs[best_zone.sub_idx]
            if sub then
                local tokens = get_sub_tokens(sub) or {}
                local cnt = 0
                for _, t in ipairs(tokens) do
                    if is_word_token(t) then cnt = cnt + 1 end
                end
                word_idx = math.max(1, cnt)
            end
        end
        return best_zone.sub_idx, word_idx
    end

    -- Find the word whose center is closest to the cursor
    local best_word = nil
    local min_dist = math.huge
    for _, word in ipairs(best_zone.words) do
        local center = word.x_offset + word.width / 2
        local dist = math.abs(rel_x - center)
        if dist < min_dist then
            min_dist = dist
            best_word = word
        end
    end

    if best_word then
        return best_zone.sub_idx, best_word.logical_idx
    end

    -- Fallback: best_zone has no selectable words (e.g. line of only spacers).
    -- Pick the closest word in the same subtitle by (vertical dist, horizontal dist).
    local neighbor = dw_resolve_neighbor_word(
        FSM.DW_HIT_ZONES, best_zone.sub_idx, best_zone.y_top, osd_x)
    return best_zone.sub_idx, neighbor or 1
end

local function dw_tooltip_hit_test(osd_x, osd_y)
    local tooltip_active = (FSM.DW_TOOLTIP_LINE ~= -1)
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local drum_mode = is_osd_tooltip_mode_eligible()
    if not tooltip_active or not FSM.DW_TOOLTIP_HIT_ZONES then return nil, nil end
    if not dw_mode and not drum_mode then return nil, nil end
    if dw_mode and not Options.dw_sec_interactivity then return nil, nil end
    if not dw_mode and not Options.drum_sec_interactivity then return nil, nil end

    for _, line in ipairs(FSM.DW_TOOLTIP_HIT_ZONES) do
        if osd_y >= line.y_top and osd_y <= line.y_bottom then
            local rel_x = osd_x - line.x_start
            if rel_x >= 0 and rel_x <= line.total_width then
                -- Find closest word in this line
                local best_logical_idx = nil
                local min_dist = math.huge
                for _, word in ipairs(line.words) do
                    local center = word.x_offset + word.width / 2
                    local dist = math.abs(rel_x - center)
                    if dist < min_dist then
                        min_dist = dist
                        best_logical_idx = word.logical_idx
                    end
                end
                return line.sub_idx, best_logical_idx
            end
        end
    end
    return nil, nil
end

local function drum_osd_hit_test(osd_x, osd_y)
    if not FSM.DRUM_HIT_ZONES or not Options.osd_interactivity then return nil, nil, nil end

    local best_line = nil
    local min_y_dist = 60 -- Snapping threshold (pixels)

    for _, line in ipairs(FSM.DRUM_HIT_ZONES) do
        -- Horizontal alignment check (strict text bounds)
        local rel_x = osd_x - line.x_start
        if rel_x >= 0 and rel_x <= line.total_width then
            -- Vertical proximity check
            local dist_y = 0
            if osd_y < line.y_top then
                dist_y = line.y_top - osd_y
            elseif osd_y > line.y_bottom then
                dist_y = osd_y - line.y_bottom
            end

            -- Prioritize direct hits (dist_y == 0) or the closest line within threshold
            if dist_y < min_y_dist then
                min_y_dist = dist_y
                best_line = line
                if dist_y == 0 then break end -- Early exit on direct hit
            end
        end
    end

    if best_line then
        local line = best_line
        local rel_x = osd_x - line.x_start
        -- Find closest word in this line
        local best_logical_idx = nil
        local min_dist = math.huge
        for _, word in ipairs(line.words) do
            local center = word.x_offset + word.width / 2
            local dist = math.abs(rel_x - center)
            if dist < min_dist then
                min_dist = dist
                best_logical_idx = word.logical_idx
            end
        end
        return line.sub_idx, best_logical_idx, line.is_pri
    end
    return nil, nil, nil
end

local function resolve_tooltip_target_line(subs, osd_x, osd_y, dw_mode)
    if dw_mode then
        return select(1, dw_hit_test(osd_x, osd_y))
    end

    local line_idx, _, hit_pri = drum_osd_hit_test(osd_x, osd_y)
    if not line_idx then return nil end
    if hit_pri then return line_idx end

    local sec_subs = (Tracks.sec.subs and #Tracks.sec.subs > 0) and Tracks.sec.subs or FSM.DW_TOOLTIP_SEC_SUBS
    local sec_sub = sec_subs and sec_subs[line_idx]
    if sec_sub then
        local midpoint = (sec_sub.start_time + sec_sub.end_time) / 2
        local pri_idx = get_center_index(subs, midpoint)
        if pri_idx and pri_idx ~= -1 then
            return pri_idx
        end
    end

    return line_idx
end

local function kardenwort_hit_test_all(osd_x, osd_y)
    if not Options.osd_interactivity then return nil, nil, nil end

    if FSM.DRUM_WINDOW ~= "OFF" then
        if Options.dw_sec_interactivity then
            local l, w = dw_tooltip_hit_test(osd_x, osd_y)
            if l then return l, w, false end
        end
        if Options.dw_pri_interactivity then
            local l, w = dw_hit_test(osd_x, osd_y)
            return l, w, true
        end
        return nil, nil, nil
    else
        local is_drum = (FSM.DRUM == "ON")
        local pri_enabled = is_drum and Options.drum_pri_interactivity or Options.srt_pri_interactivity
        local sec_enabled = is_drum and Options.drum_sec_interactivity or Options.srt_sec_interactivity

        if pri_enabled or sec_enabled then
            local line, word, hit_pri = drum_osd_hit_test(osd_x, osd_y)
            if not line then return nil, nil, nil end

            -- Simple, flat filtering based on which screen was hit
            if hit_pri and not pri_enabled then return nil, nil, nil end
            if not hit_pri and not sec_enabled then return nil, nil, nil end

            return line, word, hit_pri
        end
    end
    return nil, nil, nil
end


local function dw_sync_cursor_to_mouse()
    -- Shield logic: ignore mouse events if a keyboard command or double-click was just triggered
    if mp.get_time() < (FSM.DW_MOUSE_LOCK_UNTIL or 0) then return end

    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, word_idx

    if FSM.DRUM_WINDOW ~= "OFF" or Options.osd_interactivity then
        line_idx, word_idx = kardenwort_hit_test_all(osd_x, osd_y)
    end

    if line_idx and word_idx then
        -- Selection & Hover Protection: ONLY update logical cursor if we ARE dragging.
        -- This prevents the active highlight from snapping to the mouse while scrolling
        -- unless the user is consciously selecting something.
        if FSM.DW_MOUSE_DRAGGING and not FSM.DW_PROTECTED_SELECTION then
            FSM.DW_CURSOR_LINE = line_idx
            FSM.DW_CURSOR_WORD = word_idx
        end

        if FSM.DRUM_WINDOW ~= "OFF" then
            local active_idx = get_center_index(subs, mp.get_property_number("time-pos") or 0)
            dw_osd.data = draw_dw(subs, FSM.DW_VIEW_CENTER, active_idx)
            dw_osd:update()
        else
            drum_osd:update()
        end
    end

end

-- Mouse drag threshold, auto-scroll, and neighbor word resolution
function get_dw_drag_threshold_px()
    local threshold = tonumber(Options.dw_mouse_drag_threshold_px) or 5
    if threshold < 0 then return 0 end
    return threshold
end

function get_dw_mouse_auto_scroll_interval()
    local interval = tonumber(Options.dw_mouse_auto_scroll_interval) or 0.05
    if interval <= 0 then return 0.05 end
    return interval
end

function dw_pointer_exceeded_drag_threshold(osd_x, osd_y)
    local down_x = FSM.DW_MOUSE_DOWN_X or osd_x
    local down_y = FSM.DW_MOUSE_DOWN_Y or osd_y
    local dx = math.abs(osd_x - down_x)
    local dy = math.abs(osd_y - down_y)
    local threshold = get_dw_drag_threshold_px()
    return (dx > threshold or dy > threshold)
end

-- Fallback word resolution for dw_hit_test: when the visual line under the
-- cursor has no selectable words, pick the closest word in the same subtitle.
--   1) Among zones in target_sub_idx that have selectable words, pick the
--      one whose y_top is vertically closest to ref_y_top.
--   2) Within that zone, pick the word whose horizontal center is closest
--      to osd_x.
-- Returns the logical_idx of the chosen word, or nil if no candidate exists.
function dw_resolve_neighbor_word(zones, target_sub_idx, ref_y_top, osd_x)
    local best_zone = nil
    local best_dy = math.huge
    for _, z in ipairs(zones) do
        if z.sub_idx == target_sub_idx and z.words and #z.words > 0 then
            local dy = math.abs((z.y_top or 0) - ref_y_top)
            if dy < best_dy then
                best_dy = dy
                best_zone = z
            end
        end
    end
    if not best_zone then return nil end

    local rel_x = osd_x - (best_zone.x_start or 0)
    local best_word = nil
    local best_dx = math.huge
    for _, word in ipairs(best_zone.words) do
        local center = (word.x_offset or 0) + (word.width or 0) / 2
        local dx = math.abs(rel_x - center)
        if dx < best_dx then
            best_dx = dx
            best_word = word
        end
    end

    return best_word and best_word.logical_idx or nil
end

local function dw_mouse_update_selection()
    if not FSM.DW_MOUSE_DRAGGING then
        if not FSM.DW_MOUSE_PENDING_DRAG then return end

        local osd_x, osd_y = dw_get_mouse_osd()
        if not dw_pointer_exceeded_drag_threshold(osd_x, osd_y) then return end

        FSM.DW_MOUSE_PENDING_DRAG = false
        FSM.DW_MOUSE_DRAGGING = true
    end

    dw_sync_cursor_to_mouse()
end

function dw_get_auto_scroll_block_zones(hit_zones, dm_mode, is_pri)
    if not hit_zones or #hit_zones == 0 then return nil, nil end
    if not dm_mode then return hit_zones[1], hit_zones[#hit_zones] end

    local target_is_pri = (is_pri ~= false)
    local first_zone = nil
    local last_zone = nil
    for _, zone in ipairs(hit_zones) do
        if zone.is_pri == target_is_pri and zone.y_top and zone.y_bottom then
            if not first_zone or zone.y_top < first_zone.y_top then first_zone = zone end
            if not last_zone or zone.y_bottom > last_zone.y_bottom then last_zone = zone end
        end
    end
    return first_zone, last_zone
end


local function dw_mouse_auto_scroll()
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local dm_mode = (FSM.DRUM == "ON" and FSM.DRUM_WINDOW == "OFF")
    if not dw_mode and not dm_mode then return end

    -- Keep selection following the pointer even if OS/driver drops mouse_move events.
    -- This restores continuous drag behavior while preserving click-vs-drag thresholding.
    dw_mouse_update_selection()

    if not FSM.DW_MOUSE_DRAGGING then return end
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local _, osd_y = dw_get_mouse_osd()

    -- Top + bottom edge zones must leave a usable scroll-neutral band in the
    -- middle of the screen, so cap the per-side ratio just under 0.5.
    local DW_EDGE_SCROLL_RATIO_MAX = 0.49
    local base_h = Options.font_base_height or 1080
    local edge_ratio = tonumber(Options.dw_mouse_edge_scroll_ratio) or 0.15
    if edge_ratio < 0 then edge_ratio = 0 end
    if edge_ratio > DW_EDGE_SCROLL_RATIO_MAX then edge_ratio = DW_EDGE_SCROLL_RATIO_MAX end
    local edge_zone = base_h * edge_ratio
    local top_scroll_trigger = edge_zone
    local bottom_scroll_trigger = base_h - edge_zone
    local hit_zones = dw_mode and FSM.DW_HIT_ZONES or FSM.DRUM_HIT_ZONES
    local first_zone, last_zone = dw_get_auto_scroll_block_zones(hit_zones, dm_mode, FSM.DW_DRAG_IS_PRI)
    if not first_zone or not last_zone then return end
    local edge_activation_pad = math.max(2, math.floor(get_dw_drag_threshold_px() / 2))
    if dm_mode then
        if first_zone and first_zone.y_top then
            top_scroll_trigger = first_zone.y_top
        end
        if last_zone and last_zone.y_bottom then
            bottom_scroll_trigger = last_zone.y_bottom
        end
    else
        local dw_overflows_top = first_zone.y_top and first_zone.y_top <= edge_activation_pad
        local dw_overflows_bottom = last_zone.y_bottom and last_zone.y_bottom >= (base_h - edge_activation_pad)
        if dw_overflows_top then
            top_scroll_trigger = edge_zone
        elseif first_zone and first_zone.y_top then
            top_scroll_trigger = math.min(top_scroll_trigger, first_zone.y_top)
        end
        if dw_overflows_bottom then
            bottom_scroll_trigger = base_h - edge_zone
        elseif last_zone and last_zone.y_bottom then
            bottom_scroll_trigger = math.max(bottom_scroll_trigger, last_zone.y_bottom)
        end
    end
    local scrolled = false
    if osd_y < (top_scroll_trigger - edge_activation_pad) then
        if FSM.DW_VIEW_CENTER > 1 then
            FSM.DW_VIEW_CENTER = FSM.DW_VIEW_CENTER - 1
            if FSM.DW_CURSOR_LINE > 1 then FSM.DW_CURSOR_LINE = FSM.DW_CURSOR_LINE - 1 end
            scrolled = true
        end
    elseif osd_y > (bottom_scroll_trigger + edge_activation_pad) then
        if FSM.DW_VIEW_CENTER < #subs then
            FSM.DW_VIEW_CENTER = FSM.DW_VIEW_CENTER + 1
            if FSM.DW_CURSOR_LINE < #subs then FSM.DW_CURSOR_LINE = FSM.DW_CURSOR_LINE + 1 end
            scrolled = true
        end
    end

    if scrolled then
        -- Force re-evaluate mouse position on new scroll anchor.
        dw_mouse_update_selection()
    end
end

-- Tooltip pin / hover / toggle commands
local function cmd_dw_tooltip_pin(tbl)
    if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then
        show_osd("X")
        return
    end
    Diagnostic.debug("TOOLTIP PIN: event=" .. tostring(tbl.event))
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local drum_mode = is_osd_tooltip_mode_eligible()
    if not dw_mode and not drum_mode then return end

    if tbl.event == "down" then
        FSM.DW_TOOLTIP_FORCE = false
        FSM.DW_TOOLTIP_HOLDING = true
        local subs = Tracks.pri.subs
        if not subs or #subs == 0 then return end

        local osd_x, osd_y = dw_get_mouse_osd()
        local line_idx = resolve_tooltip_target_line(subs, osd_x, osd_y, dw_mode)

        if line_idx then
            FSM.DW_TOOLTIP_LOCKED_LINE = -1
            FSM.DW_TOOLTIP_LINE = line_idx
            local y = get_tooltip_line_y(line_idx, osd_y)
            if y then y = math.floor(y + 0.5) end
            local ass = draw_dw_tooltip(subs, line_idx, y)
            if ass ~= "" then
                apply_tooltip_ass(ass)
            end
            Diagnostic.debug("TOOLTIP ROUTE: PIN->" .. (dw_mode and "DW" or "DRUM") .. " line=" .. tostring(line_idx))
        end
    elseif tbl.event == "up" then
        FSM.DW_TOOLTIP_HOLDING = false
    end
end

local function cmd_toggle_dw_tooltip_hover()
    if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then
        show_osd("X")
        return
    end
    FSM.DW_TOOLTIP_MODE = (FSM.DW_TOOLTIP_MODE == "CLICK") and "HOVER" or "CLICK"
    show_osd("DW Translation: " .. FSM.DW_TOOLTIP_MODE)
    if FSM.DW_TOOLTIP_MODE == "CLICK" then
        FSM.DW_TOOLTIP_FORCE = false
        clear_tooltip_overlay("hover-mode-click")
    end
end

local function cmd_dw_tooltip_toggle()
    if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then
        show_osd("X")
        return
    end
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local drum_mode = is_osd_tooltip_mode_eligible()
    if not dw_mode and not drum_mode then return end

    -- If already forced ON, always toggle OFF regardless of current target match
    if FSM.DW_TOOLTIP_FORCE then
        Diagnostic.info("TOOLTIP TOGGLE: OFF (" .. (dw_mode and "DW" or "DRUM") .. ")")
        FSM.DW_TOOLTIP_FORCE = false
        clear_tooltip_overlay("toggle-off")
        return
    end

    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    -- Determine initial target based on playback/interaction state
    local is_paused = mp.get_property_bool("pause", true)
    local line_idx = -1

    if is_paused then
        line_idx = (FSM.DW_TOOLTIP_TARGET_MODE == "CURSOR") and FSM.DW_CURSOR_LINE or FSM.DW_ACTIVE_LINE
        -- Fallback if preferred target is invalid
        if line_idx == -1 then line_idx = FSM.DW_CURSOR_LINE end
    else
        line_idx = FSM.DW_ACTIVE_LINE
    end

    if line_idx ~= -1 then
        Diagnostic.info("TOOLTIP TOGGLE: ON (" .. (dw_mode and "DW" or "DRUM") .. ")")
        FSM.DW_TOOLTIP_FORCE = true
        FSM.DW_TOOLTIP_LINE = line_idx
        local y = get_tooltip_line_y(line_idx, nil)
        if not y then
            y = 540 -- center of 1080p OSD
        else
            y = math.floor(y + 0.5)
        end
        local ass = draw_dw_tooltip(subs, line_idx, y)
        if ass ~= "" then
            apply_tooltip_ass(ass)
        end
    end
end

local function dw_tooltip_mouse_update()
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local drum_mode = is_osd_tooltip_mode_eligible()
    if not dw_mode and not drum_mode then
        clear_tooltip_overlay("mode-ineligible")
        FSM.DW_TOOLTIP_FORCE = false
        return
    end
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local osd_x, osd_y = dw_get_mouse_osd()
    -- Use primary-track resolution in both DW and DM paths.
    -- In DM, secondary hit-zones are time-mapped back to primary indices.
    local line_idx = resolve_tooltip_target_line(subs, osd_x, osd_y, dw_mode)

    -- Keyboard Force takes priority and dynamically targets either the active subtitle or selection cursor based on interaction
    if FSM.DW_TOOLTIP_FORCE then
        local is_paused = mp.get_property_bool("pause", true)
        local target_l
        if not is_paused then
            target_l = FSM.DW_ACTIVE_LINE
        else
            target_l = (FSM.DW_TOOLTIP_TARGET_MODE == "ACTIVE") and FSM.DW_ACTIVE_LINE or FSM.DW_CURSOR_LINE
        end

        if target_l ~= -1 then
            FSM.DW_TOOLTIP_LINE = target_l
            local y = get_tooltip_line_y(target_l, nil)
            if y then
                y = math.floor(y + 0.5)
                local new_ass = draw_dw_tooltip(subs, target_l, y)
                if new_ass ~= "" then
                    apply_tooltip_ass(new_ass)
                elseif dw_mode then
                    clear_tooltip_overlay("forced-render-empty")
                end
            else
                -- DM sticky behavior: transient target misses should not hide a forced tooltip.
                if dw_mode then
                    clear_tooltip_overlay("forced-target-missing")
                end
            end
        end
        return
    end

    -- Selection-Aware Suppression: Hide tooltip during dragging or if currently locked to this line
    if FSM.DW_MOUSE_DRAGGING or (line_idx and line_idx == FSM.DW_TOOLTIP_LOCKED_LINE) then
        if FSM.DW_TOOLTIP_LINE ~= -1 then
            clear_tooltip_overlay("drag-or-locked")
        end
        return
    end

    -- Sticky Suppression Release: Release lock once focus moves to a different line or is lost
    if not FSM.DW_MOUSE_DRAGGING and line_idx ~= FSM.DW_TOOLTIP_LOCKED_LINE then
        FSM.DW_TOOLTIP_LOCKED_LINE = -1
    end

    -- Persistent Range Suppression: If line is in a selection range, it requires manual RMB (similar to CLICK mode)
    local in_selection = false
    if line_idx and FSM.DW_ANCHOR_LINE ~= -1 then
        local start_l = math.min(FSM.DW_CURSOR_LINE, FSM.DW_ANCHOR_LINE)
        local end_l = math.max(FSM.DW_CURSOR_LINE, FSM.DW_ANCHOR_LINE)
        if line_idx >= start_l and line_idx <= end_l then
            in_selection = true
        end
    end

    if (FSM.DW_TOOLTIP_MODE == "HOVER" and not in_selection) or FSM.DW_TOOLTIP_HOLDING then
        local target_l = line_idx
        if target_l and target_l ~= -1 then
            local target_y = get_tooltip_line_y(target_l, nil)
            if target_y then
                target_y = math.floor(target_y + 0.5)
                -- Update OSD data on every tick when line is visible to ensure smooth following during scroll
                local new_ass = draw_dw_tooltip(subs, target_l, target_y)
                FSM.DW_TOOLTIP_LINE = target_l
                if new_ass ~= "" then
                    apply_tooltip_ass(new_ass)
                elseif dw_mode then
                    clear_tooltip_overlay("hover-render-empty")
                end
            else
                -- Only dismiss if we are NOT holding RMB (prevents jitter in gaps)
                if not FSM.DW_TOOLTIP_HOLDING and FSM.DW_TOOLTIP_LINE ~= -1 then
                    -- DM sticky behavior: keep last tooltip on transient y-map misses.
                    if dw_mode then
                        clear_tooltip_overlay("target-y-missing")
                    end
                end
            end
        elseif not FSM.DW_TOOLTIP_HOLDING then
            -- Sticky Hover: Only dismiss on gaps if we are NOT holding RMB
            if FSM.DW_TOOLTIP_LINE ~= -1 then
                -- DM sticky behavior: keep last tooltip across short hover gaps.
                if dw_mode then
                    clear_tooltip_overlay("hover-gap")
                end
            end
        end
    else
        -- CLICK mode or Selection Protected: check if we left the pinned line focus
        if FSM.DW_TOOLTIP_LINE ~= -1 then
            -- Keep pinned tooltip stable through transient "no hit" ticks.
            -- Dismiss only when the cursor clearly focuses a different line.
            -- In DM mode keep pinned tooltip sticky to avoid playback-time blink.
            if dw_mode and line_idx and line_idx ~= FSM.DW_TOOLTIP_LINE then
                clear_tooltip_overlay("click-focus-left")
            end
        end
    end
end


-- Anki export, selection bounds, and Esc staged reset
local function dw_anki_export_selection()
    local ok, err = pcall(function()
        local subs = Tracks.pri.subs
        if not subs or #subs == 0 then return end

        local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
        local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
        -- [20260528132406] No-selection fallback: resolve line from live time-pos at keypress moment
        -- to bypass DW_CURSOR_LINE staleness (tick-race, Book Mode drift).
        if al == -1 and cw == -1 then
            local live_pos = mp.get_property_number("time-pos")
            local live_idx = live_pos and get_center_index(subs, live_pos) or -1
            cl = (live_idx ~= -1) and live_idx or (FSM.DW_ACTIVE_LINE ~= -1 and FSM.DW_ACTIVE_LINE or cl)
        end
        local params = {}
        local term = ""
        local context_line = ""
        local time_pos = 0
        local pivot_pos = 0
        local advanced_index = nil

        if al ~= -1 and aw ~= -1 and cl ~= -1 and cw ~= -1 then
            local p1_l, p1_w, p2_l, p2_w
            if al < cl or (al == cl and aw <= cw) then
                p1_l, p1_w, p2_l, p2_w = al, aw, cl, cw
            else
                p1_l, p1_w, p2_l, p2_w = cl, cw, al, aw
            end

            params = { type = "RANGE", p1_l = p1_l, p1_w = p1_w, p2_l = p2_l, p2_w = p2_w }
            term = prepare_export_text(params, { clean = true, restore_sentence = true })

            -- Requirement: Reconstruct advanced_index (word-based only)
            local indices = {}
            local pivot_idx = 1
            for i = p1_l, p2_l do
                local sub = subs[i]
                if sub then
                    local raw_text = normalize_inline_break_markers(sub.text):gsub("\n", " ")
                    local tokens = build_word_list_internal(raw_text, true)
                    for _, t in ipairs(tokens) do
                        if t.is_word then
                            local in_range = true
                            if i == p1_l and t.logical_idx < p1_w - L_EPSILON then in_range = false end
                            if i == p2_l and t.logical_idx > p2_w + L_EPSILON then in_range = false end
                            if in_range then
                                table.insert(indices, string.format("%d:%g:%d", i - p1_l, t.logical_idx, pivot_idx))
                                pivot_idx = pivot_idx + 1
                            end
                        end
                    end
                end
            end
            advanced_index = table.concat(indices, ",")

            -- Context Extraction Logic
            local ctx_parts = {}
            local char_offset = 0
            pivot_pos = -1
            local start_k = math.max(1, p1_l - Options.anki_context_lines)
            for k = start_k, math.min(#subs, p2_l + Options.anki_context_lines) do
                if subs[k] then
                    local text = normalize_inline_break_markers(subs[k].text):gsub("{[^}]+}", "")

                    if k == p1_l then
                        -- Precision Anchor
                        local first_word = term:match("%S+") or ""
                        local s = text:find(first_word, 1, true)
                        if s then
                            pivot_pos = char_offset + s + (#first_word / 2)
                        else
                            pivot_pos = char_offset + (#text / 2)
                        end
                    end

                    table.insert(ctx_parts, text)
                    char_offset = char_offset + #text + 1
                end
            end
            if pivot_pos == -1 then pivot_pos = char_offset / 2 end
            context_line = table.concat(ctx_parts, "\0")
            time_pos = subs[p1_l].start_time + 0.001
        elseif cl ~= -1 and subs[cl] then
            params = { type = "POINT", line = cl, word = cw }
            term = prepare_export_text(params, { clean = true, restore_sentence = true })

            if cw ~= -1 then
                advanced_index = string.format("0:%g:1", cw)
            end

            -- Context Extraction
            local ctx_parts = {}
            local char_offset = 0
            pivot_pos = -1
            local start_k = math.max(1, cl - Options.anki_context_lines)
            for k = start_k, math.min(#subs, cl + Options.anki_context_lines) do
                if subs[k] then
                    local text = normalize_inline_break_markers(subs[k].text):gsub("{[^}]+}", "")

                    if k == cl then
                        local s = text:find(term, 1, true)
                        if s then
                            pivot_pos = char_offset + s + (#term / 2)
                        else
                            pivot_pos = char_offset + (#text / 2)
                        end
                    end

                    table.insert(ctx_parts, text)
                    char_offset = char_offset + #text + 1
                end
            end
            if pivot_pos == -1 then pivot_pos = char_offset / 2 end
            context_line = table.concat(ctx_parts, "\0")
            time_pos = subs[cl].start_time + 0.001
        end


        if term and term ~= "" then
            -- Clean context: remove ASS tags
            context_line = context_line:gsub("{[^}]+}", "")
            local term_words = build_word_list(term)
            local effective_limit = math.max(Options.anki_context_max_words, #term_words + 20)
            local extracted_context = extract_anki_context(context_line, term, effective_limit, pivot_pos, advanced_index)
            -- Use the multi-index generated above
            save_anki_tsv_row(term, extracted_context, time_pos, advanced_index)
            show_osd("Anki Highlight Saved: " .. term)

            -- In-memory update was already performed by save_anki_tsv_row.
            -- Removing redundant full-file reload to prevent UI stuttering.
            dw_reset_selection()
            if dw_tooltip_osd then dw_tooltip_osd:update() end
        end
    end)

    if not ok then
        show_osd("Anki Export Error: " .. tostring(err), 5)
    end
end


local function ctrl_discard_set()
    -- Reset both the persistent pending set (Pink) and any active selection range anchors (Gold)
    FSM.DW_CTRL_PENDING_SET = {}
    FSM.DW_CTRL_PENDING_LIST = {}
    FSM.DW_ANCHOR_LINE = -1
    FSM.DW_ANCHOR_WORD = -1
    if FSM.DRUM_WINDOW ~= "OFF" then
        FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
        dw_osd:update()
    end
end

local function get_dw_selection_bounds()
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD

    if al == -1 or aw == -1 or cl == -1 or cw == -1 then return nil end
    if al == cl and logical_cmp(aw, cw) then return nil end -- Single word is not a "range selection" in this context

    if al < cl or (al == cl and aw < cw + L_EPSILON) then
        return al, aw, cl, cw
    else
        return cl, cw, al, aw
    end
end

-- Context-Aware Escape: Deterministic staged selection peel-back.
-- Stage 1: Clear Pink Set (ctrl pending set)
-- Stage 2: Clear Yellow Range (if anchor exists and is different from cursor)
-- Stage 3: Clear Yellow Pointer (hides the highlight) and syncs cursor to active line
-- No implicit window close occurs in cmd_dw_esc itself.

local function cmd_dw_esc()
    if FSM.HELP_MODE then
        cmd_toggle_help()
        return
    end
    -- Stage 1: Clear Pink Set (Purple highlights)
    if next(FSM.DW_CTRL_PENDING_SET) then
        FSM.DW_CTRL_PENDING_SET = {}
        FSM.DW_CTRL_PENDING_LIST = {}
        FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
        if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update()
        elseif FSM.DRUM == "ON" then drum_osd:update() end
        return
    end

    -- Stage 2: Clear Yellow Range (multi-word selection)
    -- get_dw_selection_bounds returns nil if it's a single-word pointer
    if get_dw_selection_bounds() then
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update()
        elseif FSM.DRUM == "ON" then drum_osd:update() end
        return
    end

    -- Stage 3: Clear Yellow Pointer & Full Reset
    if FSM.DW_CURSOR_WORD ~= -1 then
        dw_reset_selection()
        return
    end

    -- Stage 4: Neutral no-selection Esc flow for manual mode.
    -- 1st Esc arms neutral marker; 2nd Esc restores follow explicitly.
    if dw_is_neutral_policy_enabled() and FSM.DW_ESC_NEUTRAL_ARMED then
        FSM.DW_FOLLOW_PLAYER = true
        FSM.DW_ESC_NEUTRAL_ARMED = false
        if FSM.DW_CURSOR_LINE == -1 then
            local neutral_line = dw_resolve_neutral_cursor_line()
            if neutral_line and neutral_line ~= -1 then
                FSM.DW_CURSOR_LINE = neutral_line
            end
        end
        if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update()
        elseif FSM.DRUM == "ON" then drum_osd:update() end
        return
    end
    if dw_is_neutral_policy_enabled() and not FSM.DW_FOLLOW_PLAYER then
        dw_capture_neutral_marker()
        local neutral_line = dw_resolve_neutral_cursor_line()
        if neutral_line and neutral_line ~= -1 then
            FSM.DW_CURSOR_LINE = neutral_line
        end
        FSM.DW_ESC_NEUTRAL_ARMED = true
        if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update()
        elseif FSM.DRUM == "ON" then drum_osd:update() end
        return
    end

    -- Auto-follow mode: Esc with no active selection should still restore follow.
    if not dw_is_neutral_policy_enabled() and not FSM.DW_FOLLOW_PLAYER then
        local time_pos = mp.get_property_number("time-pos") or 0
        local live_idx = get_center_index(Tracks.pri.subs, time_pos)
        if live_idx and live_idx ~= -1 then
            FSM.DW_ACTIVE_LINE = live_idx
            FSM.DW_CURSOR_LINE = live_idx
        end
        FSM.DW_FOLLOW_PLAYER = true
        if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update()
        elseif FSM.DRUM == "ON" then drum_osd:update() end
        return
    end
end

-- Set operations: toggle/commit/discard, mouse handler factory, smart callbacks
local function ctrl_toggle_word(line_idx, word_idx, no_sync)
    if line_idx < 1 or word_idx < 0 then return end

    if not FSM.DW_CTRL_PENDING_SET[line_idx] then
        FSM.DW_CTRL_PENDING_SET[line_idx] = {}
    end

    local line_set = FSM.DW_CTRL_PENDING_SET[line_idx]
    if line_set[word_idx] then
        line_set[word_idx] = nil
        -- Clean up empty line tables to keep iteration fast
        local has_any = false
        for _ in pairs(line_set) do has_any = true break end
        if not has_any then FSM.DW_CTRL_PENDING_SET[line_idx] = nil end
    else
        line_set[word_idx] = {line = line_idx, word = word_idx}
    end
    if not no_sync then
        sync_ctrl_pending_list()
        FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
        if FSM.DRUM_WINDOW ~= "OFF" then
            dw_osd:update()
        elseif FSM.DRUM == "ON" then
            drum_osd:update()
        end
    end
end

local function ctrl_commit_set(line_idx, word_idx)
    Diagnostic.info(string.format("ctrl_commit_set(line=%s, word=%s)", tostring(line_idx), tostring(word_idx)))
    -- Check if cursor word is in set
    local line_set = FSM.DW_CTRL_PENDING_SET[line_idx]
    if not line_set or not line_set[word_idx] then
        Diagnostic.info("ctrl_commit_set: word NOT in set, falling back")
        -- Fallback to plain MMB single-click export
        dw_anki_export_selection()
        return
    end

    -- Use pre-sorted list from FSM
    local members = FSM.DW_CTRL_PENDING_LIST
    if #members == 0 then return end


    -- Requirement: Unified Paired Export
    local term = prepare_export_text({ type = "SET", members = members }, { clean = true, restore_sentence = true })

    local subs = Tracks.pri.subs
    local p1_l = members[1].line
    local p2_l = members[#members].line
    local time_pos = subs[p1_l].start_time + 0.001

    -- Context Extraction
    local ctx_parts = {}
    local char_offset = 0
    local pivot_pos = -1
    local start_k = math.max(1, p1_l - Options.anki_context_lines)
    for k = start_k, math.min(#subs, p2_l + Options.anki_context_lines) do
        if subs[k] then
            local text = normalize_inline_break_markers(subs[k].text):gsub("{[^}]+}", "")

            if k == p1_l then
                local first_word = term:match("%S+") or ""
                local s = text:find(first_word, 1, true)
                if s then
                    pivot_pos = char_offset + s + (#first_word / 2)
                else
                    pivot_pos = char_offset + (#text / 2)
                end
            end

            table.insert(ctx_parts, text)
            char_offset = char_offset + #text + 1
        end
    end
    if pivot_pos == -1 then pivot_pos = char_offset / 2 end
    local context_line = table.concat(ctx_parts, "\0")

    -- Build advanced index string
    local indices = {}
    for i, m in ipairs(members) do
        table.insert(indices, string.format("%d:%g:%d", m.line - p1_l, m.word, i))
    end
    local advanced_index = table.concat(indices, ",")

    save_anki_tsv_row(term, extract_anki_context(context_line, term, Options.anki_context_max_words, pivot_pos, advanced_index), subs[p1_l].start_time + 0.001, advanced_index)
    show_osd("Anki Paired Saved: " .. term)


    dw_reset_selection()

    dw_osd:update()
end


local MOUSE_HANDLERS = {}

local function make_mouse_handler(is_shift, on_up_callback, on_down_callback, updates_selection)
    if updates_selection == nil then updates_selection = true end
    local handler = function(tbl)
        -- Shield logic: ignore mouse events if a keyboard command was just triggered
        if mp.get_time() < (FSM.DW_MOUSE_LOCK_UNTIL or 0) then return end

        if tbl.event == "down" then
            FSM.DW_FOLLOW_PLAYER = false
            FSM.DW_MOUSE_DRAGGING = false
            FSM.DW_MOUSE_PENDING_DRAG = false
            if FSM.DW_MOUSE_SCROLL_TIMER then
                FSM.DW_MOUSE_SCROLL_TIMER:kill()
                FSM.DW_MOUSE_SCROLL_TIMER = nil
            end

            -- Store initial coordinates to detect movement/dragging
            local osd_x, osd_y = dw_get_mouse_osd()
            FSM.DW_MOUSE_DOWN_X, FSM.DW_MOUSE_DOWN_Y = osd_x, osd_y

            -- Dismiss tooltip on click and lock suppression for the current focus
            local is_tooltip_hit = dw_tooltip_hit_test(osd_x, osd_y)
            local line_idx, word_idx, is_pri = kardenwort_hit_test_all(osd_x, osd_y)

            if line_idx then
                FSM.DW_TOOLTIP_LOCKED_LINE = line_idx
                FSM.DW_DRAG_IS_PRI = is_pri

                if FSM.DW_TOOLTIP_LINE ~= -1 and not is_tooltip_hit then
                    FSM.DW_TOOLTIP_LINE = -1
                    apply_tooltip_ass("")
                end

                -- Custom Actions (Tooltips, Pins, etc.)
                if on_down_callback then on_down_callback(tbl) end

                -- Selection Logic (Only for words, if enabled)
                if word_idx and updates_selection then
                    local is_inside = on_up_callback and is_inside_dw_selection(line_idx, word_idx)
                    FSM.DW_PROTECTED_SELECTION = is_inside and not is_shift

                    -- Standard click (no Shift): reset anchor & cursor unless clicking inside existing range
                    if not is_shift and not is_inside then
                        FSM.DW_ANCHOR_LINE = line_idx
                        FSM.DW_ANCHOR_WORD = word_idx
                        FSM.DW_CURSOR_LINE = line_idx
                        FSM.DW_CURSOR_WORD = word_idx
                        FSM.DW_CURSOR_X = nil
                        FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
                    elseif is_shift then
                        if FSM.DW_ANCHOR_LINE == -1 then
                            FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
                            FSM.DW_ANCHOR_WORD = FSM.DW_CURSOR_WORD
                        end
                        FSM.DW_CURSOR_LINE = line_idx
                        FSM.DW_CURSOR_WORD = word_idx
                        FSM.DW_CURSOR_X = nil
                        FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
                    end

                    -- Start in pending state: plain click should not auto-scroll.
                    -- Drag/edge auto-scroll activates only after real mouse movement.
                    FSM.DW_MOUSE_PENDING_DRAG = true
                    FSM.DW_MOUSE_DRAGGING = false
                    mp.add_forced_key_binding("mouse_move", "dw-mouse-drag", dw_mouse_update_selection)
                    FSM.DW_MOUSE_SCROLL_TIMER = mp.add_periodic_timer(get_dw_mouse_auto_scroll_interval(), dw_mouse_auto_scroll)

                    drum_osd:update()
                    if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update() end
                end
            end
        elseif tbl.event == "up" then
            FSM.DW_MOUSE_DRAGGING = false
            FSM.DW_MOUSE_PENDING_DRAG = false

            -- POINTER JUMP SYNC: Perform a final hit-test on release ONLY if the mouse
            -- has moved significantly (dragging). This prevents stationary clicks
            -- from re-highlighting wrong words when the text shifts vertically
            -- (e.g. during re-centering or seeking).
            local osd_x, osd_y = dw_get_mouse_osd()
            if dw_pointer_exceeded_drag_threshold(osd_x, osd_y) and updates_selection then
                local line_idx, word_idx = kardenwort_hit_test_all(osd_x, osd_y)

                if line_idx and word_idx then
                    if not FSM.DW_PROTECTED_SELECTION then
                        FSM.DW_CURSOR_LINE = line_idx
                        FSM.DW_CURSOR_WORD = word_idx
                    end
                    FSM.DW_TOOLTIP_LOCKED_LINE = line_idx
                end
            end

            FSM.DW_PROTECTED_SELECTION = false

            mp.remove_key_binding("dw-mouse-drag")
            if FSM.DW_MOUSE_SCROLL_TIMER then
                FSM.DW_MOUSE_SCROLL_TIMER:kill()
                FSM.DW_MOUSE_SCROLL_TIMER = nil
            end

            if on_up_callback then on_up_callback(tbl) end
        end
    end
    MOUSE_HANDLERS[handler] = true
    return handler
end

local cmd_dw_mouse_select = make_mouse_handler(false)
local cmd_dw_mouse_select_shift = make_mouse_handler(true)
MOUSE_HANDLERS[cmd_dw_tooltip_pin] = true

local function dw_anki_export_smart_callback(tbl)
    -- Only trigger on release (Standard export behavior)
    if tbl and tbl.event ~= "up" then return end

    local starts_pink = false
    if FSM.DW_ANCHOR_LINE ~= -1 then
        local line_set = FSM.DW_CTRL_PENDING_SET[FSM.DW_ANCHOR_LINE]
        if line_set and line_set[FSM.DW_ANCHOR_WORD] then starts_pink = true end
    end

    if starts_pink then
        ctrl_commit_set(FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD)
    else
        dw_anki_export_selection()
    end
end

local cmd_dw_export_anki = make_mouse_handler(false, dw_anki_export_smart_callback)

local function cmd_dw_add_smart()
    if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then
        show_osd("X")
        return
    end
    ctrl_commit_set(FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD)
end

local function cmd_dw_toggle_pink(tbl, was_mouse)
    if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then
        show_osd("X")
        return
    end
    -- Only trigger mouse buttons on release to avoid double-toggle
    if was_mouse and tbl and tbl.event ~= "up" then return end

    local line, word
    -- Canonical context check
    local is_mouse = (was_mouse == true)

    local p1_l, p1_w, p2_l, p2_w = get_dw_selection_bounds()

    if p1_l then
        -- Toggle the entire yellow range into the pink set
        local subs = Tracks.pri.subs
        if not subs then return end

        for i = p1_l, p2_l do
            local sub = subs[i]
            if sub then
                local s_w = (i == p1_l) and p1_w or -1
                local e_w = (i == p2_l) and p2_w or 999999
                local in_range = (i > p1_l)

                local tokens = get_sub_tokens(sub)
                if tokens then
                    for _, t in ipairs(tokens) do
                        if logical_cmp(t.logical_idx, s_w) then in_range = true end
                        if in_range then
                            if not t.text:match("^%s*$") then
                                ctrl_toggle_word(i, t.logical_idx, true)
                            end
                        end
                        if logical_cmp(t.logical_idx, e_w) then in_range = false break end
                    end
                end
            end
        end
        sync_ctrl_pending_list()
        FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
        if FSM.DRUM_WINDOW ~= "OFF" then
            dw_osd:update()
        end
        -- Clear yellow selection after it "turns pink"
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        -- Only clear drag-binding if we were actually interacting with the mouse
        if is_mouse then
            mp.remove_key_binding("dw-mouse-drag")
        end
        drum_osd:update()
        if FSM.DRUM_WINDOW ~= "OFF" then dw_osd:update() end
    else
        -- Fallback to single word toggle (standard behavior)
        if was_mouse then
            local osd_x, osd_y = dw_get_mouse_osd()
            line, word = kardenwort_hit_test_all(osd_x, osd_y)
        else
            line, word = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
        end

        if line and line ~= -1 and word and word ~= -1 then
            -- NEVER update cursor/anchor during a toggle-pink action if it was triggered via mouse.
            -- This ensures that RMB (context) or toggle actions don't move the selector.
            ctrl_toggle_word(line, word)
        end
    end
end


local function dw_handle_double_click_target(subs, line_idx, word_idx)
    if not subs or #subs == 0 then return false end
    local sub = subs[line_idx]
    if sub and sub.start_time then
        -- Intentional Focus Handover
        FSM.IGNORE_NEXT_JUMP = true
        FSM.ACTIVE_IDX = line_idx
        FSM.MANUAL_NAV_TARGET_IDX = line_idx
        if #Tracks.sec.subs > 0 then
            local sec_idx = math.min(line_idx, #Tracks.sec.subs)
            FSM.SEC_ACTIVE_IDX = sec_idx
            FSM.SEC_MANUAL_NAV_TARGET_IDX = sec_idx
        end
        FSM.JUST_JERKED_TO = -1
        FSM.TIMESEEK_INHIBIT_UNTIL = nil
        FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown

        local s, _ = get_effective_boundaries(subs, sub, line_idx)
        mp.commandv("seek", s, "absolute+exact")
        FSM.last_paused_sub_end = nil
        -- which would otherwise be caught by MBTN_LEFT and trigger a new selection
        -- at the post-seek mouse position.
        FSM.DW_MOUSE_LOCK_UNTIL = mp.get_time() + (Options.dw_mouse_shield_ms / 1000)

        -- Explicitly terminate any dragging/scrolling state initiated by the first click
        FSM.DW_MOUSE_DRAGGING = false
        FSM.DW_MOUSE_PENDING_DRAG = false
        mp.remove_key_binding("dw-mouse-drag")
        if FSM.DW_MOUSE_SCROLL_TIMER then
            FSM.DW_MOUSE_SCROLL_TIMER:kill()
            FSM.DW_MOUSE_SCROLL_TIMER = nil
        end

        mp.commandv("seek", sub.start_time, "absolute+exact")
        dw_capture_neutral_marker()
        FSM.DW_CURSOR_LINE = line_idx
        FSM.DW_CURSOR_X = nil
        dw_apply_post_transition_selection(word_idx)
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"

        if not FSM.BOOK_MODE then
            FSM.DW_VIEW_CENTER = line_idx
        end

        -- Explicitly ensure we don't open the full Drum Window (Mode W)
        -- when interacting in OSD mode (Mode C).
        if FSM.DRUM == "ON" and FSM.DRUM_WINDOW == "OFF" then
            drum_osd:update()
        elseif FSM.DRUM_WINDOW ~= "OFF" then
            dw_osd:update()
        end
        return true
    end
    return false
end

local function cmd_dw_double_click()
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, word_idx = kardenwort_hit_test_all(osd_x, osd_y)
    if not line_idx then return end

    dw_handle_double_click_target(subs, line_idx, word_idx)
end

-- Tick renderers: Drum Window and Drum Mode per-frame rendering
local function tick_dw(time_pos, active_idx)
    if FSM.DRUM_WINDOW == "OFF" then
        if dw_osd.data ~= "" then
            dw_osd.data = ""
            dw_osd:update()
        end
        return
    end
    local subs = Tracks.pri.subs
    if #subs == 0 or not active_idx or active_idx == -1 then return end

    -- In follow mode: viewport tracks playback; cursor only tracks if no range selection is active
    if FSM.DW_FOLLOW_PLAYER then
        if FSM.BOOK_MODE and not FSM.DW_SEEKING_MANUALLY then
            -- Book Mode: Line-by-line scrolling during playback
            dw_ensure_visible(active_idx, true)
        elseif not FSM.BOOK_MODE then
            -- In standard DW follow mode keep active subtitle centered.
            FSM.DW_VIEW_CENTER = active_idx
        end
    end
    -- In manual mode: DW_VIEW_CENTER and DW_CURSOR_LINE are frozen,
    -- active_idx just controls the blue highlight color (may be off-screen)

    dw_osd.data = draw_dw(subs, FSM.DW_VIEW_CENTER, active_idx)
    dw_osd:update()

    dw_tooltip_mouse_update()
end

local function tick_drum(time_pos, pri_use_osd, sec_use_osd)
    -- Don't render Drum Mode OSD while Drum Window is open (they overlap)
    if FSM.DRUM_WINDOW ~= "OFF" then
        if drum_osd.data ~= "" then
            drum_osd.data = ""
            drum_osd:update()
        end
        return
    end

    local is_drum = (FSM.DRUM == "ON")

    -- If no tracks are requested for OSD, clear and return
    if not pri_use_osd and not sec_use_osd then
        if drum_osd.data ~= "" then
            drum_osd.data = ""
            drum_osd:update()
        end
        return
    end

    local ass_text = ""
    local font_size = is_drum
        and (Options.drum_font_size > 0 and Options.drum_font_size or mp.get_property_number("sub-font-size", 44))
        or (Options.srt_font_size > 0 and Options.srt_font_size or mp.get_property_number("sub-font-size", 44))

    local pri_pos = mp.get_property_number("sub-pos", 95)
    local sec_pos = mp.get_property_number("secondary-sub-pos", 10)

    local context_lines = is_drum and Options.drum_context_lines or 0

    if sec_pos > 50 then
        local max_lines = Options.drum_active_size_mul + (2 * context_lines * Options.drum_context_size_mul)
        local max_pixels = max_lines * font_size * Options.drum_line_height_mul
        -- Calculate safety position (2 blocks above primary + comfort gap)
        local min_safe_pos = pri_pos - (2 * (max_pixels / 1080) * 100) - Options.drum_track_gap
        -- Apply relative offset so user keys (r/t) still work responsively
        local auto_offset = min_safe_pos - Options.sec_pos_bottom
        sec_pos = sec_pos + auto_offset
    end

    FSM.DRUM_HIT_ZONES = {}

    -- Book Mode parity for DM mini (DRUM=ON, DW_WINDOW=OFF):
    -- keep follow enabled but page the viewport with dw_ensure_visible,
    -- matching the DW Book Mode behavior.
    if is_drum and FSM.DW_FOLLOW_PLAYER and FSM.BOOK_MODE and not FSM.DW_SEEKING_MANUALLY and #Tracks.pri.subs > 0 then
        local pri_active_idx = get_center_index(Tracks.pri.subs, time_pos)
        if pri_active_idx and pri_active_idx ~= -1 then
            if FSM.DW_VIEW_CENTER == -1 then
                FSM.DW_VIEW_CENTER = pri_active_idx
            end
            dw_ensure_visible(pri_active_idx, true)
        end
    end

    local pri_active_idx = (#Tracks.pri.subs > 0) and get_center_index(Tracks.pri.subs, time_pos) or -1
    local sec_active_idx = (#Tracks.sec.subs > 0) and get_center_index(Tracks.sec.subs, time_pos) or -1

    -- PAUSE GUARD: When the player is paused BY AUTOPAUSE, do NOT let the
    -- Sticky Sentinel advance to the next subtitle.  Freezing keeps the subtitle display
    -- and jump-back logic anchored to the subtitle we actually stopped on.  This mirrors
    -- the autopause + nav-delta gating used in master_tick so that manual pauses and
    -- initial startup (FSM.SEC_ACTIVE_IDX == -1) are NOT frozen.
    -- NOTE: With 15 fps black.mp4 (was 1 fps), the nav-delta guard (< 0.3 s) is a
    -- defensive safety net — normal tick deltas are ~67 ms, so false triggers are
    -- extremely unlikely.
    local is_autopause_paused_drum = mp.get_property_bool("pause", false)
        and FSM.last_paused_sub_end
        and math.abs(time_pos - FSM.last_paused_sub_end) < 0.5
        and math.abs(time_pos - (FSM.last_time_pos or time_pos)) < 0.3
    if is_autopause_paused_drum and FSM.ACTIVE_IDX ~= -1 then
        pri_active_idx = FSM.ACTIVE_IDX
    end
    if is_autopause_paused_drum and FSM.SEC_ACTIVE_IDX ~= -1 then
        sec_active_idx = FSM.SEC_ACTIVE_IDX
    end
    local pri_view_center = FSM.DW_VIEW_CENTER
    if FSM.DW_FOLLOW_PLAYER then
        pri_view_center = (is_drum and FSM.BOOK_MODE) and FSM.DW_VIEW_CENTER or pri_active_idx
    end
    if pri_view_center == -1 then pri_view_center = pri_active_idx end

    -- Draw Primary FIRST, Secondary SECOND (so Secondary is on top in Z-order)
    if pri_use_osd and #Tracks.pri.subs > 0 then
        local active_idx = pri_active_idx
        local view_center = pri_view_center

        local pri_plain = is_drum and (not Options.drum_pri_highlighting) or (not Options.srt_pri_highlighting)
        ass_text = ass_text .. draw_drum(Tracks.pri.subs, view_center, active_idx, pri_pos, time_pos, font_size, FSM.DRUM_HIT_ZONES, pri_plain, true)
    end

    if sec_use_osd and #Tracks.sec.subs > 0 then
        local active_idx = sec_active_idx
        -- Secondary track mirrors primary viewport offset in all follow modes.
        local view_center = active_idx
        if pri_active_idx ~= -1 and pri_view_center ~= -1 then
            local offset = pri_view_center - pri_active_idx
            view_center = math.max(1, math.min(#Tracks.sec.subs, active_idx + offset))
        end

        local sec_plain = is_drum and (not Options.drum_sec_highlighting) or (not Options.srt_sec_highlighting)
        ass_text = ass_text .. draw_drum(Tracks.sec.subs, view_center, active_idx, sec_pos, time_pos, font_size, FSM.DRUM_HIT_ZONES, sec_plain, false)
    end

    drum_osd.data = ass_text
    drum_osd:update()
end

-- ===============================================================================
-- AUTOPAUSE, LOOP, AND REPLAY TICK CONTROLLERS
-- ===============================================================================

local function tick_autopause(time_pos)
    if FSM.AUTOPAUSE ~= "ON" or FSM.SPACEBAR ~= "IDLE" then return end
    if FSM.SCHEDULED_REPLAY_START or FSM.LOOP_MODE == "ON" then return end
    if FSM.MEDIA_STATE == "NO_SUBS" then return end

    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    -- Hardened Autopause via Sticky Focus
    -- Use the Sentinel (ACTIVE_IDX) to determine exactly when the audible tail ends.
    local active_idx = FSM.ACTIVE_IDX
    if active_idx == -1 or not subs[active_idx] then
        -- Fallback if sentinel is lost
        active_idx = get_center_index(subs, time_pos)
    end
    if active_idx == -1 then return end

    -- Skip autopause while transiting through the rewind zone after Shift+A/D.
    -- Uses <= so the exact boundary tick is still suppressed; the inhibit is cleared
    -- only after jerk-back has also been evaluated (see end of main tick function).
    -- [20260510193230] Special case: within-subtitle rewind should still allow autopause at end.
    local in_rewind_transit = FSM.TIMESEEK_INHIBIT_UNTIL and time_pos <= FSM.TIMESEEK_INHIBIT_UNTIL
    local within_subtitle_rewind = in_rewind_transit and FSM.REWIND_START_IDX and active_idx == FSM.REWIND_START_IDX

    -- Suppress autopause only during cross-subtitle rewind transit
    if in_rewind_transit and FSM.REWIND_TRANSIT_CROSS_CARD and not within_subtitle_rewind then
        return
    end

    local _, sub_end = get_effective_boundaries(subs, subs[active_idx], active_idx)
    if not sub_end then return end

    -- Check if we've reached the end of the padded window
    -- Use an inclusive check to ensure we don't skip the pause frame.
    local diff = sub_end - time_pos
    if diff > Options.pause_padding then
        return
    end

    if diff < -Options.autopause_overshoot then
        if FSM._prev_time_pos and FSM._prev_time_pos < sub_end and mp.get_time() > FSM.MANUAL_NAV_COOLDOWN then
            -- Safety net: time_pos jumped past the autopause window in a single
            -- tick but the previous position was still before the boundary, so
            -- we just crossed it.  Allow autopause to fire instead of returning.
            -- With 15 fps black.mp4 this path is a defensive fallback — normal
            -- tick deltas (~67 ms) never exceed the overshoot threshold (100 ms).
        else
            return
        end
    end

    -- Prevent re-triggering for the same subtitle segment
    if FSM.last_paused_sub_end == sub_end then return end

    -- Ensure we are actually on a subtitle (using internal state rather than transient mpv visibility)
    -- This fixes the "Stops stopping" bug when text clears before the audio tail finishes.
    local raw_text_primary = subs[active_idx].text or ""
    local raw_text_secondary = (Tracks.sec.subs[active_idx] and Tracks.sec.subs[active_idx].text) or ""

    if raw_text_primary == "" and raw_text_secondary == "" then return end

    -- Karaoke Mode: Don't pause if we are in the middle of a phrase with highlights
    if FSM.KARAOKE == "PHRASE" then
        local has_karaoke = string.find(raw_text_primary, Options.karaoke_token, 1, true)
        if not has_karaoke then has_karaoke = string.find(raw_text_secondary, Options.karaoke_token, 1, true) end
        if has_karaoke then return end
    end

    mp.set_property_bool("pause", true)
    FSM.last_paused_sub_end = sub_end

end

function protect_internal_replay_seek()
    FSM.IGNORE_NEXT_JUMP = true
    local replay_seconds = (Options.replay_ms or 0) / 1000
    FSM.INTERNAL_REPLAY_UNTIL = mp.get_time() + math.max(1.0, replay_seconds + Options.nav_cooldown + 0.5)
end

local function tick_loop(time_pos)
    if FSM.LOOP_MODE ~= "ON" then return end
    if not FSM.LOOP_START or not FSM.LOOP_END then return end

    if time_pos >= FSM.LOOP_END - Options.pause_padding then
        if FSM.LOOP_ARMED then
            FSM.LOOP_ARMED = false
            protect_internal_replay_seek()

            if FSM.REPLAY_REMAINING > 1 then
                FSM.REPLAY_REMAINING = FSM.REPLAY_REMAINING - 1
                local pri_subs = Tracks.pri.subs
                if pri_subs and #pri_subs > 0 then
                    local idx = get_center_index(pri_subs, FSM.LOOP_START)
                    if idx ~= -1 then FSM.ACTIVE_IDX = idx end
                end
                local sec_subs = Tracks.sec.subs
                if sec_subs and #sec_subs > 0 then
                    local idx = get_center_index(sec_subs, FSM.LOOP_START)
                    if idx ~= -1 then FSM.SEC_ACTIVE_IDX = idx end
                end
                mp.commandv("seek", FSM.LOOP_START, "absolute+exact")
            else
                FSM.REPLAY_REMAINING = 0
                FSM.LOOP_MODE = "OFF"
            end

            -- Spacebar Override: If holding Space, break the loop
            -- so it repeats once and then continues over the subtitle border.
            if FSM.SPACEBAR == "HOLDING" then
                FSM.LOOP_MODE = "OFF"
                FSM.REPLAY_REMAINING = 0
            end
        end
    else
        FSM.LOOP_ARMED = true
    end
end

local function tick_scheduled_replay(time_pos)
    if not FSM.SCHEDULED_REPLAY_START or not FSM.SCHEDULED_REPLAY_END then return false end

    if time_pos >= FSM.SCHEDULED_REPLAY_END - Options.pause_padding then
        if FSM.REPLAY_REMAINING > 1 then
            FSM.REPLAY_REMAINING = FSM.REPLAY_REMAINING - 1
            protect_internal_replay_seek()
            FSM.last_paused_sub_end = nil
            local pri_subs = Tracks.pri.subs
            if pri_subs and #pri_subs > 0 then
                local idx = get_center_index(pri_subs, FSM.SCHEDULED_REPLAY_START)
                if idx ~= -1 then FSM.ACTIVE_IDX = idx end
            end
            local sec_subs = Tracks.sec.subs
            if sec_subs and #sec_subs > 0 then
                local idx = get_center_index(sec_subs, FSM.SCHEDULED_REPLAY_START)
                if idx ~= -1 then FSM.SEC_ACTIVE_IDX = idx end
            end
            mp.commandv("seek", FSM.SCHEDULED_REPLAY_START, "absolute+exact")
            return true
        else
            FSM.REPLAY_REMAINING = 0
            FSM.SCHEDULED_REPLAY_START = nil
            FSM.SCHEDULED_REPLAY_END = nil
            if FSM.SPACEBAR == "IDLE" and Options.replay_autostop then
                mp.set_property_bool("pause", true)
            end
            return true
        end
    end
    return false
end

-- ===============================================================================
-- INTERACTIVE BINDINGS AND MASTER TICK LOOP
-- ===============================================================================

-- Toggle mouse/keyboard bindings based on active OSD mode
update_interactive_bindings = function()
    local dw_on = (FSM.DRUM_WINDOW ~= "OFF")
    local osd_on = (FSM.DRUM == "ON" or (not Tracks.pri.is_ass and #Tracks.pri.subs > 0)) and Options.osd_interactivity

    local need_mouse = dw_on or osd_on
    local need_kb = dw_on or osd_on

    manage_dw_bindings(need_mouse, need_kb)
end

local function master_tick()
    local ok, err = xpcall(function()
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    -- Ghost Hold Recovery
    -- If Space is 'HOLDING' due to a suspected ghost event at 's' press,
    -- but no physical 'DOWN' event has refreshed it within 2 seconds, revert to IDLE.
    if FSM.SPACEBAR == "HOLDING" and FSM.GHOST_HOLD_EXPIRY and mp.get_time() > FSM.GHOST_HOLD_EXPIRY then
        FSM.SPACEBAR = "IDLE"
        FSM.GHOST_HOLD_EXPIRY = nil
        FSM.PHYSICAL_SPACE_HOLD = false

    end

    -- Universal Manual Seek Detection
    -- Detects any significant jump (native keys, script keys, or mouse)
    -- Coarse Time-Pos Filter: Distinguishes real seeks from natural
    -- time-pos jumps by checking wall-clock delta.  A real seek moves time-pos
    -- much faster than wall-clock time advances.  With 15 fps black.mp4 the
    -- >0.3 s threshold is rarely reached during normal playback (~67 ms ticks).
    if FSM.last_time_pos and math.abs(time_pos - FSM.last_time_pos) > 0.3 then
        local wall_delta = FSM.last_wall_time and (mp.get_time() - FSM.last_wall_time) or 0
        local is_coarse_reporting = wall_delta > 0 and (math.abs(time_pos - FSM.last_time_pos) / wall_delta) < 2.0
        local internal_replay_jump = FSM.INTERNAL_REPLAY_UNTIL and mp.get_time() < FSM.INTERNAL_REPLAY_UNTIL
        local ignore_jump = FSM.IGNORE_NEXT_JUMP or (FSM.IGNORE_NEXT_JUMP_UNTIL and mp.get_time() < FSM.IGNORE_NEXT_JUMP_UNTIL)
        if ignore_jump then
            FSM.IGNORE_NEXT_JUMP = false
            FSM.IGNORE_NEXT_JUMP_UNTIL = nil
        end
        if not ignore_jump and not internal_replay_jump and not is_coarse_reporting then
            -- Any manual navigation resets Autopause state so it fires again at the new location.
            FSM.last_paused_sub_end = nil
            FSM.SCHEDULED_REPLAY_START = nil
            FSM.SCHEDULED_REPLAY_END = nil
            -- TIMESEEK_INHIBIT_UNTIL is NOT cleared here — it is cleared only by
            -- the explicit inhibit gate (time_pos > TIMESEEK_INHIBIT_UNTIL) below.
            -- Clearing it in generic jump detection would allow autopause to fire at
            -- intermediate sub boundaries during rewind transit (ZID 20260509233440).
            FSM.MANUAL_NAV_TARGET_IDX = nil
            FSM.SEC_MANUAL_NAV_TARGET_IDX = nil
            FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown
            if FSM.LOOP_MODE == "ON" then
                -- Persistent Loop (Autopause OFF only): Re-anchor loop to the new subtitle.
                local subs = Tracks.pri.subs
                if subs and #subs > 0 then
                    local idx = get_center_index(subs, time_pos)
                    if idx ~= -1 then
                        FSM.LOOP_START = subs[idx].start_time
                        FSM.LOOP_END = subs[idx].end_time
                        FSM.LOOP_ARMED = true
                        show_osd("Loop: Line " .. idx)
                    end
                end
            end
        end
    end
    if FSM.IGNORE_NEXT_JUMP then
        FSM.IGNORE_NEXT_JUMP_UNTIL = mp.get_time() + 0.5
        FSM.IGNORE_NEXT_JUMP = false
    end
    FSM._prev_time_pos = FSM.last_time_pos
    FSM.last_time_pos = time_pos
    FSM.last_wall_time = mp.get_time()

    local did_scheduled_replay = tick_scheduled_replay(time_pos)

    -- Execute Autopause and Loop
    -- IMPORTANT: Loop Mode is only valid when Autopause is OFF.
    if FSM.AUTOPAUSE == "ON" and FSM.SPACEBAR == "IDLE" and not did_scheduled_replay then
        tick_autopause(time_pos)
    elseif FSM.AUTOPAUSE == "OFF" and FSM.LOOP_MODE == "ON" then
        tick_loop(time_pos)
    end

    -- Sync active line for Drum/DW logic
    local active_idx = -1
    if #Tracks.pri.subs > 0 then
        active_idx = get_center_index(Tracks.pri.subs, time_pos)

        -- PAUSE GUARD: When paused BY AUTOPAUSE, freeze the sentinel so it
        -- does not drift to the next subtitle due to time-pos jitter.
        -- We detect an autopause-induced pause by checking that last_paused_sub_end
        -- is set and time_pos is still near it.  With 15 fps black.mp4, tick deltas
        -- are ~67 ms so the 0.3 s nav-delta guard is a defensive safety net.
        local is_autopause_paused = mp.get_property_bool("pause", false)
            and FSM.last_paused_sub_end
            and math.abs(time_pos - FSM.last_paused_sub_end) < 0.5
        if is_autopause_paused and FSM.ACTIVE_IDX ~= -1 and active_idx ~= FSM.ACTIVE_IDX then
            local last_nav_delta = math.abs(time_pos - (FSM.last_time_pos or time_pos))
            if last_nav_delta < 0.3 then
                active_idx = FSM.ACTIVE_IDX
            end
        end

        if active_idx ~= -1 then
            -- Phrases Mode "Jerk Back" Logic
            -- Only trigger for NATURAL transitions. Skip during manual seek cooldown and during
            -- time-based rewind transit (TIMESEEK_INHIBIT_UNTIL), where MOVIE-like seamless flow
            -- is expected: no jerking, no overlap-driven snaps.
            local hold_elapsed = mp.get_time() - (FSM.space_down_time or 0)
            local phrase_space_movie_override = FSM.AUTOPAUSE == "ON"
                and FSM.IMMERSION_MODE == "PHRASE"
                and FSM.PHYSICAL_SPACE_HOLD
                and hold_elapsed > Options.space_tap_delay

            if FSM.IMMERSION_MODE == "PHRASE" and not phrase_space_movie_override and mp.get_time() > FSM.MANUAL_NAV_COOLDOWN
               and (not FSM.TIMESEEK_INHIBIT_UNTIL or not FSM.REWIND_TRANSIT_CROSS_CARD) then
                if FSM.ACTIVE_IDX ~= -1 and active_idx > FSM.ACTIVE_IDX and active_idx <= FSM.ACTIVE_IDX + 5 then
                    local s_next, _ = get_effective_boundaries(Tracks.pri.subs, Tracks.pri.subs[active_idx], active_idx)
                    if s_next and (time_pos - s_next) > Options.nav_tolerance then
                        mp.commandv("seek", s_next, "absolute+exact")
                        FSM.IGNORE_NEXT_JUMP = true
                        FSM.JUST_JERKED_TO = active_idx
                    end
                end
            end

            -- Clear rewind-transit inhibit AFTER jerk-back has been evaluated,
            -- using strict > so both autopause and jerk-back are suppressed on the boundary tick.
            -- [20260510193230] Also clear rewind start index when transit ends.
            if FSM.TIMESEEK_INHIBIT_UNTIL and time_pos > FSM.TIMESEEK_INHIBIT_UNTIL then
                FSM.TIMESEEK_INHIBIT_UNTIL = nil
                FSM.REWIND_START_IDX = nil
                FSM.REWIND_TRANSIT_CROSS_CARD = false
            end

            -- Clear jerk flag once we've moved past the previous sub's technical end
            if FSM.JUST_JERKED_TO ~= -1 and FSM.JUST_JERKED_TO == active_idx then
                local prev_idx = active_idx - 1
                if prev_idx >= 1 and Tracks.pri.subs[prev_idx] then
                    if time_pos > Tracks.pri.subs[prev_idx].end_time then
                        FSM.JUST_JERKED_TO = -1
                    end
                else
                    FSM.JUST_JERKED_TO = -1
                end
            end

            FSM.ACTIVE_IDX = active_idx
            FSM.DW_ACTIVE_LINE = active_idx

            -- Universal Cursor Synchronization
            -- Ensures that the "copy focus" always tracks playback when in follow mode,
            -- even if the Drum Window is closed (e.g., purely in Drum Mode on-screen).
            -- [20260528132406] Viewport update and cursor sync are now independent:
            -- cursor tracks on every tick in all modes (including Book Mode) when no selection.
            if FSM.DW_FOLLOW_PLAYER then
                if not FSM.BOOK_MODE and FSM.DW_VIEW_CENTER ~= active_idx then
                    FSM.DW_VIEW_CENTER = active_idx
                end
                if FSM.DW_ANCHOR_LINE == -1 and FSM.DW_CURSOR_WORD == -1 then
                    FSM.DW_CURSOR_LINE = active_idx
                    FSM.DW_CURSOR_X = nil
                end
            end
        end
    end

    -- [20260507154518] Maintain secondary Sticky Sentinel (mirrors primary ACTIVE_IDX pattern).
    -- [20260509233440] Gate with MANUAL_NAV_COOLDOWN so that cmd_dw_seek_delta's explicit
    -- SEC_ACTIVE_IDX assignment is not immediately overwritten by the natural sentinel scan.
    -- During the cooldown window, the secondary sentinel preserves the seek target.
    if #Tracks.sec.subs > 0 and mp.get_time() > FSM.MANUAL_NAV_COOLDOWN then
        local sec_idx = get_center_index(Tracks.sec.subs, time_pos)

        -- PAUSE GUARD: freeze secondary sentinel when paused by autopause.
        local is_autopause_paused_sec = mp.get_property_bool("pause", false)
            and FSM.last_paused_sub_end
            and math.abs(time_pos - FSM.last_paused_sub_end) < 0.5
        if is_autopause_paused_sec and FSM.SEC_ACTIVE_IDX ~= -1 and sec_idx ~= FSM.SEC_ACTIVE_IDX then
            local last_nav_delta = math.abs(time_pos - (FSM.last_time_pos or time_pos))
            if last_nav_delta < 0.3 then
                sec_idx = FSM.SEC_ACTIVE_IDX
            end
        end

        if sec_idx ~= -1 then
            FSM.SEC_ACTIVE_IDX = sec_idx
        end
    end

    -- Manage native subtitle suppression
    -- We hide native subs if OSD rendering is active OR Drum Window is open.
    local use_osd_for_srt = (Options.srt_font_name ~= "" or Options.srt_font_bold or Options.srt_font_size > 0)
    local dw_active = (FSM.DRUM_WINDOW ~= "OFF")

    -- Independent OSD render decisions:
    -- 1. Always use OSD if Drum Mode is ON.
    -- 2. Use OSD for SRT if custom fonts are configured.
    -- 3. [20260501163905] Force OSD if a highlight (Yellow Pointer or Pink Set) exists on the active line.
    -- 4. NEVER use OSD for ASS in Regular mode (to preserve styling/layout).
    local has_ptr = (FSM.DW_CURSOR_WORD ~= -1 and active_idx == FSM.DW_CURSOR_LINE)
    local has_pink = (next(FSM.DW_CTRL_PENDING_SET) ~= nil)
    local pri_effective_vis = FSM.native_sub_vis and not FSM.SEC_ONLY_MODE
    local sec_effective_vis = (FSM.native_sub_vis and FSM.native_sec_sub_vis) or FSM.SEC_ONLY_MODE
    local pri_use_osd = pri_effective_vis and ((FSM.DRUM == "ON") or (not Tracks.pri.is_ass and (use_osd_for_srt or has_ptr or has_pink)))
    local sec_use_osd = sec_effective_vis and ((FSM.DRUM == "ON") or (not Tracks.sec.is_ass and (use_osd_for_srt or has_ptr or has_pink)))

    if dw_active or pri_use_osd or sec_use_osd then
        -- Suppression Logic
        -- We hide native if DW is active OR if we are using OSD for that specific track.
        local target_pri_vis = not dw_active and not pri_use_osd and pri_effective_vis
        local target_sec_vis = not dw_active and not sec_use_osd and sec_effective_vis

        if mp.get_property_bool("sub-visibility") ~= target_pri_vis then
            mp.set_property_bool("sub-visibility", target_pri_vis)
        end
        if mp.get_property_bool("secondary-sub-visibility") ~= target_sec_vis then
            mp.set_property_bool("secondary-sub-visibility", target_sec_vis)
        end

        -- Only render one-line Drum/SRT OSD if Drum Window is not active
        if not dw_active and (pri_use_osd or sec_use_osd) then
            tick_drum(time_pos, pri_use_osd, sec_use_osd)
        else
            if drum_osd.data ~= "" then
                drum_osd.data = ""
                drum_osd:update()
            end
        end
    else
        -- Clear OSD if not rendering
        if drum_osd.data ~= "" then
            drum_osd.data = ""
            drum_osd:update()
        end
        -- Restore native if user wants subs and we aren't using OSD
        if FSM.native_sub_vis then
            if not mp.get_property_bool("sub-visibility") then
                mp.set_property_bool("sub-visibility", true)
            end
            -- Only restore secondary if it should be on
            if FSM.native_sec_sub_vis and not mp.get_property_bool("secondary-sub-visibility") then
                mp.set_property_bool("secondary-sub-visibility", true)
            elseif not FSM.native_sec_sub_vis and mp.get_property_bool("secondary-sub-visibility") then
                mp.set_property_bool("secondary-sub-visibility", false)
            end
        else
            if mp.get_property_bool("sub-visibility") or mp.get_property_bool("secondary-sub-visibility") then
                mp.set_property_bool("sub-visibility", false)
                mp.set_property_bool("secondary-sub-visibility", false)
            end
        end
    end

    -- Execute Drum Window
    if FSM.DRUM_WINDOW == "DOCKED" then
        tick_dw(time_pos, active_idx)
    elseif Options.osd_interactivity then
        dw_tooltip_mouse_update()
    end
    end, debug.traceback)
    if not ok then
        Diagnostic.error("master_tick crash: " .. tostring(err))
    end
end
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
            if FSM.initial_pause_state then mp.set_property_bool("pause", false) end
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
    if dw_osd then dw_osd:update() end
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
        if Tracks.pri.path then Tracks.pri.subs = load_sub(Tracks.pri.path, false) end
        if Tracks.sec.path then Tracks.sec.subs = load_sub(Tracks.sec.path, false) end

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
local function cmd_dw_scroll(dir)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    -- Bootstrap: If the viewport hasn't been explicitly set yet,
    -- anchor it to the current active index before applying the scroll delta.
    if FSM.DW_VIEW_CENTER == -1 then
        local time_pos = mp.get_property_number("time-pos") or 0
        FSM.DW_VIEW_CENTER = get_center_index(subs, time_pos)
        if FSM.DW_VIEW_CENTER == -1 then FSM.DW_VIEW_CENTER = 1 end
    end
    FSM.DW_FOLLOW_PLAYER = false
    FSM.DW_VIEW_CENTER = math.max(1, math.min(#subs, FSM.DW_VIEW_CENTER + dir))
    -- Keep null-pointer source in sync with manual viewport scroll to avoid stale entry line
    -- on the next UP/DOWN/LEFT/RIGHT activation after Esc.
    if FSM.DW_CURSOR_WORD == -1 and FSM.DW_ANCHOR_LINE == -1 then
        FSM.DW_CURSOR_LINE = FSM.DW_VIEW_CENTER
    end
    dw_sync_cursor_to_mouse()
end

local function cmd_dw_wheel_scroll(dir)
    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, _ = kardenwort_hit_test_all(osd_x, osd_y)

    -- In Drum Window (DOCKED), ALWAYS scroll.
    -- In Drum Mode (OSD), also ALWAYS scroll to match DW field behavior
    -- (not only when hovering exact subtitle hit-zones).
    if FSM.DRUM_WINDOW ~= "OFF" or FSM.DRUM == "ON" or line_idx then
        cmd_dw_scroll(dir)
    end
end



local function ensure_sub_layout(sub)
    if not sub then return nil end
    if sub.layout_cache and sub.layout_cache.version == FSM.LAYOUT_VERSION then
        return sub.layout_cache.entry
    end

    local tokens = get_sub_tokens(sub) or {}
    if #tokens == 0 then tokens = {{text=""}} end
    local font_size = Options.dw_font_size
    local font_name = Options.dw_font_name
    local max_w = 1860
    local space_w = dw_get_str_width(" ", font_size, font_name)

    local logical_to_visual = {}
    for j, t in ipairs(tokens) do
        if t.logical_idx then logical_to_visual[t.logical_idx] = j end
    end

    local vlines = {}
    local cur_indices = {}
    local cur_w = 0
    for j, w in ipairs(tokens) do
        local ww = dw_get_str_width(w, font_size, font_name)
        local space = (#cur_indices > 0 and not Options.dw_original_spacing) and space_w or 0
        if cur_w + space + ww > max_w and #cur_indices > 0 then
            table.insert(vlines, cur_indices)
            cur_indices = {j}
            cur_w = ww
        else
            table.insert(cur_indices, j)
            cur_w = cur_w + space + ww
        end
    end
    if #cur_indices > 0 then table.insert(vlines, cur_indices) end
    if #vlines == 0 then vlines = {{1}} end

    local entry_h = #vlines * dw_vline_height()

    sub.layout_cache = {
        version = FSM.LAYOUT_VERSION,
        entry = {
            sub_idx = -1, -- caller-specific; draw path will overwrite with real index
            vlines = vlines,
            logical_to_visual = logical_to_visual,
            words = tokens,
            height = entry_h
        }
    }
    return sub.layout_cache.entry
end

-- Word resolution helpers: visual line, closest word, center computation
local function dw_get_word_visual_line(sub, logical_idx)
    local entry = ensure_sub_layout(sub)
    if not entry then return 1, 1 end

    local v_idx = entry.logical_to_visual[logical_idx]
    if not v_idx then return 1, 1 end
    for i, vl in ipairs(entry.vlines) do
        for _, idx in ipairs(vl) do
            if idx == v_idx then return i, #entry.vlines end
        end
    end
    return 1, 1
end

-- Returns the logical word index on sub whose OSD x-center is closest to target_x.
-- Falls back to first word if nothing found.
local function dw_closest_word_at_x(sub, target_x, word_only, vl_filter)
    local entry = ensure_sub_layout(sub)
    if not entry then return -1 end

    local words = entry.words or {}
    local vlines = entry.vlines
    local visual_to_logical = {}
    for j, t in ipairs(words or {}) do
        if t.logical_idx then visual_to_logical[j] = t.logical_idx end
    end

    local space_w = dw_get_str_width(" ")

    local best_logical = nil
    local best_dist = math.huge

    -- For multi-vline subtitles, target_x may sit on any visual row.
    -- We search vlines (optionally filtered) and pick the globally closest word.
    for i, vl_indices in ipairs(vlines) do
        if not vl_filter or i == vl_filter then
            local vl_width = 0
            for k, wi in ipairs(vl_indices) do
                vl_width = vl_width + dw_get_str_width(words[wi])
                if k < #vl_indices and not Options.dw_original_spacing then vl_width = vl_width + space_w end
            end
            local vl_left = 960 - vl_width / 2
            local pos = 0
            for k, wi in ipairs(vl_indices) do
                local ww = dw_get_str_width(words[wi])
                local l_idx = visual_to_logical[wi]
                if l_idx then
                    local valid = false
                    if word_only then
                        valid = words[wi].is_word
                    else
                        valid = not words[wi].text:match("^%s*$")
                    end

                    if valid then
                        local cx = vl_left + pos + ww / 2
                        local dist = math.abs(cx - target_x)
                        if dist < best_dist then
                            best_dist = dist
                            best_logical = l_idx
                        end
                    end
                end
                pos = pos + ww + (Options.dw_original_spacing and 0 or space_w)
            end
        end
    end

    return best_logical or (not word_only and get_first_valid_word_idx(sub) or -1)
end

local function dw_pick_middle_word_idx(sub)
    local entry = ensure_sub_layout(sub)
    if not entry or not entry.vlines or #entry.vlines == 0 then
        return -1
    end

    local middle_vl_idx = math.floor((#entry.vlines + 1) / 2)
    local w = dw_closest_word_at_x(sub, 960, true, middle_vl_idx)
    if w ~= -1 then
        return w
    end
    return dw_closest_word_at_x(sub, 960, true, nil)
end

local function get_first_valid_word_idx(sub)

    if not sub then return -1 end
    local tokens = get_sub_tokens(sub)
    if not tokens then return -1 end
    for _, t in ipairs(tokens) do
        if t.is_word then return t.logical_idx end
    end
    return -1
end

-- Returns the OSD-space x-center of the word with the given logical_idx on sub.
-- Uses the same monospace/proportional width model as dw_hit_test.
-- Returns nil if the word cannot be located.
local function dw_compute_word_center_x(sub)
    if not sub or FSM.DW_CURSOR_WORD == -1 then return nil end
    local entry = ensure_sub_layout(sub)
    if not entry then return nil end

    local v_idx = entry.logical_to_visual[FSM.DW_CURSOR_WORD]
    if not v_idx then return nil end

    local vl_idx, _ = dw_get_word_visual_line(sub, FSM.DW_CURSOR_WORD)
    local vl_indices = entry.vlines[vl_idx]
    if not vl_indices then return nil end

    local space_w = dw_get_str_width(" ")
    local vl_width = 0
    for k, wi in ipairs(vl_indices) do
        vl_width = vl_width + dw_get_str_width(entry.words[wi])
        if k < #vl_indices and not Options.dw_original_spacing then vl_width = vl_width + space_w end
    end

    local vl_left = 960 - vl_width / 2
    local pos = 0
    for k, wi in ipairs(vl_indices) do
        local ww = dw_get_str_width(entry.words[wi])
        if wi == v_idx then
            return vl_left + pos + ww / 2
        end
        pos = pos + ww + (Options.dw_original_spacing and 0 or space_w)
    end
    return nil
end





dw_ensure_visible = function(line_idx, paged)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local is_drum_mini = (FSM.DRUM == "ON" and FSM.DRUM_WINDOW == "OFF")
    local is_srt = (FSM.DRUM == "OFF" and FSM.DRUM_WINDOW == "OFF")
    local win_lines = is_srt and 1 or (is_drum_mini and (Options.drum_context_lines * 2 + 1) or Options.dw_lines_visible)
    win_lines = math.max(1, math.floor(win_lines or 1))
    local half_win = math.floor(win_lines / 2)
    local configured_scrolloff = is_drum_mini and Options.drum_scrolloff or Options.dw_scrolloff
    local max_margin = math.max(0, math.floor(win_lines / 2) - 1)
    local margin = math.max(0, math.min(math.floor(configured_scrolloff or 0), max_margin))

    -- Do not enforce scroll margins during manual cursor navigation or manual scroll
    if not FSM.DW_FOLLOW_PLAYER then
        margin = 0
    end

    -- Calculate current viewport bounds
    local view_min = FSM.DW_VIEW_CENTER - half_win
    local view_max = view_min + win_lines - 1

    -- Adjust bounds to account for start/end of file (clamping logic in dw_build_layout)
    if view_min < 1 then
        view_max = view_max + (1 - view_min)
        view_min = 1
    end
    if view_max > #subs then
        view_min = view_min - (view_max - #subs)
        view_max = #subs
    end
    view_min = math.max(1, view_min)
    view_max = math.min(#subs, view_max)

    if paged then
        if line_idx < view_min + margin then
            -- Jump up: active line becomes aligned with bottom margin
            FSM.DW_VIEW_CENTER = math.max(1, line_idx + (win_lines - margin - 1) - half_win)
        elseif line_idx > view_max - margin then
            -- Jump down: active line becomes aligned with top margin
            FSM.DW_VIEW_CENTER = math.min(#subs, line_idx - margin + half_win)
        end
    else
        -- Push (line-by-line)
        if line_idx < view_min + margin then
            local diff = (view_min + margin) - line_idx
            FSM.DW_VIEW_CENTER = math.max(1, FSM.DW_VIEW_CENTER - diff)
        elseif line_idx > view_max - margin then
            local diff = line_idx - (view_max - margin)
            FSM.DW_VIEW_CENTER = math.min(#subs, FSM.DW_VIEW_CENTER + diff)
        end
    end
end

-- Navigation: event snapshots, intent context, line/word movement
local function dw_create_nav_event_snapshot(evt)
    local time_pos = mp.get_property_number("time-pos")
    return {
        time = time_pos or 0,
        paused = mp.get_property_bool("pause"),
        is_repeat = (type(evt) == "table" and evt.event == "repeat"),
        event = evt
    }
end

local function dw_resolve_nav_intent_context(subs, snapshot)
    local ctx = {
        active_line = -1,
        cursor_line = FSM.DW_CURSOR_LINE,
        pointer_fsm = FSM.DW_POINTER_FSM,
        paused = snapshot.paused,
        book_mode = FSM.BOOK_MODE,
    }

    local pad_s = (Options.audio_padding_start or 0) / 1000

    -- Deterministic live index resolution from snapshot time (with padding awareness)
    if snapshot.time > 0 and subs and #subs > 0 then
        local low, high = 1, #subs
        local best = -1
        while low <= high do
            local mid = math.floor((low + high) / 2)
            if (subs[mid].start_time - pad_s) <= snapshot.time then
                best = mid
                low = mid + 1
            else
                high = mid - 1
            end
        end

        -- Check 'best' boundaries
        if best ~= -1 then
            local s, e = get_effective_boundaries(subs, subs[best], best)
            if snapshot.time >= (s - Options.nav_tolerance) and snapshot.time <= (e + Options.nav_tolerance) then
                ctx.active_line = best
            end
        end

        -- Lookahead: check if next sub is already in its padding range
        -- This eliminates "lag" when the player hasn't fired the official event yet.
        local next_idx = (best ~= -1) and (best + 1) or 1
        if next_idx <= #subs then
            local ns, ne = get_effective_boundaries(subs, subs[next_idx], next_idx)
            if snapshot.time >= (ns - Options.nav_tolerance) and snapshot.time <= (ne + Options.nav_tolerance) then
                ctx.active_line = next_idx
            end
        end
    end

    -- Fallback priority: standing cursor context before active playback line.
    -- This preserves manual null-pointer context when snapshot time cannot resolve.
    if ctx.active_line == -1 and ctx.cursor_line and ctx.cursor_line ~= -1 then
        ctx.active_line = ctx.cursor_line
    end

    -- Final fallback to internal active state (e.g. startup/no standing cursor).
    if ctx.active_line == -1 then
        ctx.active_line = (FSM.DW_ACTIVE_LINE ~= -1) and FSM.DW_ACTIVE_LINE or FSM.ACTIVE_IDX
    end

    return ctx
end



local function cmd_dw_line_move(dir, shift, evt)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local snapshot = dw_create_nav_event_snapshot(evt)
    local ctx = dw_resolve_nav_intent_context(subs, snapshot)

    FSM.DW_FOLLOW_PLAYER = false

    -- Activation logic for NULL pointer
    if FSM.DW_CURSOR_WORD == -1 then
        -- Snap repeat during null activation to prevent immediate double-jump
        if snapshot.is_repeat then return end

        local line_idx = dw_resolve_null_activation_line(ctx, dir, subs)

        FSM.DW_CURSOR_LINE = line_idx

        if dir < 0 then
            -- Requirement: UP enters from middle of current subtitle
            FSM.DW_CURSOR_WORD = dw_pick_middle_word_idx(subs[line_idx])
        else
            -- Directional entry: DOWN starts at top
            local entry = ensure_sub_layout(subs[line_idx])
            local target_vl = 1
            local w = dw_closest_word_at_x(subs[line_idx], 960, true, target_vl)
            if w == -1 then
                w = dw_closest_word_at_x(subs[line_idx], 960, true, nil)
            end
            FSM.DW_CURSOR_WORD = w
        end

        -- Hard-lock: initial activation DOES NOT MOVE beyond the resolved line
        FSM.DW_CURSOR_X = dw_compute_word_center_x(subs[line_idx]) or 960
        FSM.DW_POINTER_FSM = "POINTER_ACTIVE_MANUAL"
        FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
        FSM.DW_ESC_NEUTRAL_ARMED = false
        dw_ensure_visible(FSM.DW_CURSOR_LINE, false)
        return
    end

    local line_idx = FSM.DW_CURSOR_LINE

    if shift and FSM.DW_ANCHOR_LINE == -1 then
        FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
        local start_word = get_first_valid_word_idx(subs[FSM.DW_CURSOR_LINE])
        FSM.DW_ANCHOR_WORD = (FSM.DW_CURSOR_WORD > 0) and FSM.DW_CURSOR_WORD or (start_word > 0 and start_word or 1)
    end

    if not FSM.DW_CURSOR_X then
        FSM.DW_CURSOR_X = dw_compute_word_center_x(subs[FSM.DW_CURSOR_LINE]) or 960
    end

    -- Intra-subtitle Vertical Navigation
    local cur_vl, total_vl = dw_get_word_visual_line(subs[line_idx], FSM.DW_CURSOR_WORD)
    local target_vl = cur_vl + dir
    if target_vl >= 1 and target_vl <= total_vl then
        local w = dw_closest_word_at_x(subs[line_idx], FSM.DW_CURSOR_X, true, target_vl)
        if w ~= -1 then
            FSM.DW_CURSOR_WORD = w
            return
        end
    end

    -- Cross-subtitle Vertical Navigation
    for l = line_idx + dir, (dir > 0 and #subs or 1), dir do
        local entry = ensure_sub_layout(subs[l])
        if entry then
            local target_vl = (dir > 0) and 1 or #entry.vlines
            local w = dw_closest_word_at_x(subs[l], FSM.DW_CURSOR_X, true, target_vl)
            if w ~= -1 then
                FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD = l, w
                break
            end
        end
    end

    if not shift then
        FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD = -1, -1
    end

    FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
    dw_ensure_visible(FSM.DW_CURSOR_LINE, false)
end

local function cmd_dw_word_move(dir, shift, ctrl, evt)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local snapshot = dw_create_nav_event_snapshot(evt)
    local ctx = dw_resolve_nav_intent_context(subs, snapshot)

    FSM.DW_FOLLOW_PLAYER = false

    -- Activation logic for NULL pointer
    if FSM.DW_CURSOR_WORD == -1 then
        if snapshot.is_repeat then return end

        local line_idx = dw_resolve_null_activation_line(ctx, dir, subs)

        FSM.DW_CURSOR_LINE = line_idx
        local raw_sub = subs[line_idx]
        local tokens = get_sub_tokens(raw_sub, true) or {}
        local logical_tokens = {}
        for _, t in ipairs(tokens) do
            if t.logical_idx and not t.text:match("^%s*$") then
                table.insert(logical_tokens, t)
            end
        end

        if #logical_tokens > 0 then
            -- LEFT enters at end, RIGHT enters at start
            local target_token = (dir > 0) and logical_tokens[1] or logical_tokens[#logical_tokens]
            FSM.DW_CURSOR_WORD = target_token.logical_idx
        else
            FSM.DW_CURSOR_WORD = 1
        end

        -- Hard-lock: initial activation DOES NOT MOVE beyond the resolved line
        FSM.DW_CURSOR_X = dw_compute_word_center_x(subs[line_idx])
        FSM.DW_POINTER_FSM = "POINTER_ACTIVE_MANUAL"
        FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
        FSM.DW_ESC_NEUTRAL_ARMED = false
        dw_ensure_visible(FSM.DW_CURSOR_LINE, false)
        return
    end

    local line_idx = FSM.DW_CURSOR_LINE
    local raw_sub = subs[line_idx]
    if not raw_sub then return end

    local tokens = get_sub_tokens(raw_sub, true) or {}
    local logical_tokens = {}
    for i, t in ipairs(tokens) do
        if t.logical_idx and not t.text:match("^%s*$") then
            table.insert(logical_tokens, t)
        end
    end

    if #logical_tokens == 0 then
        FSM.DW_CURSOR_LINE = math.max(1, math.min(#subs, line_idx + (dir > 0 and 1 or -1)))
        FSM.DW_CURSOR_WORD = 1
        FSM.DW_CURSOR_X = dw_compute_word_center_x(subs[FSM.DW_CURSOR_LINE])
        return
    end

    if shift and FSM.DW_ANCHOR_LINE == -1 then
        FSM.DW_ANCHOR_LINE = FSM.DW_CURSOR_LINE
        FSM.DW_ANCHOR_WORD = FSM.DW_CURSOR_WORD
    end

    local target_token = nil
    local current_idx = -1
    for i, t in ipairs(logical_tokens) do
        if logical_cmp(t.logical_idx, FSM.DW_CURSOR_WORD) then
            current_idx = i
            break
        end
    end

    if current_idx ~= -1 then
        local next_idx = current_idx + dir
        if next_idx >= 1 and next_idx <= #logical_tokens then
            target_token = logical_tokens[next_idx]
        end
    else
        -- Transition: We are on a symbol but moving in word mode
        if dir > 0 then
            for _, t in ipairs(logical_tokens) do
                if t.logical_idx > FSM.DW_CURSOR_WORD + L_EPSILON then
                    target_token = t
                    break
                end
            end
        else
            for i = #logical_tokens, 1, -1 do
                local t = logical_tokens[i]
                if t.logical_idx < FSM.DW_CURSOR_WORD - L_EPSILON then
                    target_token = t
                    break
                end
            end
        end
    end

    if target_token then
        FSM.DW_CURSOR_WORD = target_token.logical_idx
    else
        -- Line Jump
        local next_line = line_idx + (dir > 0 and 1 or -1)
        if next_line >= 1 and next_line <= #subs then
            FSM.DW_CURSOR_LINE = next_line
            local next_tokens = get_sub_tokens(subs[next_line], true) or {}
            local next_logical = {}
            for _, t in ipairs(next_tokens) do
                if t.logical_idx and not t.text:match("^%s*$") then
                    table.insert(next_logical, t)
                end
            end
            if #next_logical > 0 then
                FSM.DW_CURSOR_WORD = (dir > 0) and next_logical[1].logical_idx or next_logical[#next_logical].logical_idx
            else
                FSM.DW_CURSOR_WORD = 1
            end
        end
    end

    FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR"
    FSM.DW_CURSOR_X = dw_compute_word_center_x(subs[FSM.DW_CURSOR_LINE])
    dw_ensure_visible(FSM.DW_CURSOR_LINE, false)

    if not shift then
        FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD = -1, -1
    end
end

-- Replay and seek commands
local function cmd_replay_sub()
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    local is_paused = mp.get_property_bool("pause")

    -- Sticky Hold Workaround for Hardware Ghosting
    -- If 's' is pressed, the keyboard matrix might send a fake 'Space UP' event just before 's' DOWN.
    -- If Space was held, or released within the last 300ms, we assume they are still intending to hold it.
    local was_holding_space = (FSM.SPACEBAR == "HOLDING") or
                              (FSM.SPACEBAR == "IDLE" and FSM.space_up_time and (mp.get_time() - FSM.space_up_time) < 0.3)

    if was_holding_space then
        FSM.SPACEBAR = "HOLDING" -- Force restore state
        FSM.GHOST_HOLD_EXPIRY = mp.get_time() + 2.0 -- 2 second safety window for desync recovery
    end

    -- Fixed Window Replay (Subtitle Independent)
    -- As per user request: "get rid of the boundaries of subtitles altogether and leave only the range of the track"
    local replay_start = math.max(0, time_pos - Options.replay_ms/1000)
    local replay_end = time_pos
    local subs = Tracks.pri.subs
    local current_idx = -1
    local replay_start_idx = -1
    if subs and #subs > 0 then
        current_idx = get_center_index(subs, time_pos)
        replay_start_idx = get_center_index(subs, replay_start)
    end
    local is_cross_card_replay = (current_idx ~= -1 and replay_start_idx ~= -1 and current_idx ~= replay_start_idx)
    local sec_subs = Tracks.sec.subs
    local sec_replay_start_idx = (sec_subs and #sec_subs > 0) and get_center_index(sec_subs, replay_start) or -1

    if FSM.AUTOPAUSE == "OFF" then
        -- Autopause OFF: "Flashback" Replay (Finite Segment)
        -- No toggling: each press restarts the replay window
        FSM.LOOP_MODE = "ON"
        FSM.LOOP_START = replay_start
        FSM.LOOP_END = replay_end
        FSM.LOOP_ARMED = false
        protect_internal_replay_seek()
        FSM.REPLAY_REMAINING = Options.replay_count
        if replay_start_idx ~= -1 then
            FSM.ACTIVE_IDX = replay_start_idx
            FSM.MANUAL_NAV_TARGET_IDX = replay_start_idx
        end
        if sec_replay_start_idx ~= -1 then
            FSM.SEC_ACTIVE_IDX = sec_replay_start_idx
            FSM.SEC_MANUAL_NAV_TARGET_IDX = sec_replay_start_idx
        end

        mp.commandv("seek", replay_start, "absolute+exact")
        if is_paused then mp.set_property_bool("pause", false) end
        FSM.TIMESEEK_INHIBIT_UNTIL = nil
        FSM.REWIND_START_IDX = nil
        FSM.REWIND_TRANSIT_CROSS_CARD = false
        FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown
        local x_str = (Options.replay_count > 1) and (" x" .. Options.replay_count) or ""
        local template = Options.replay_msg_format
        local msg = template:gsub("%%m", tostring(Options.replay_ms))
                            :gsub("%%s", tostring(Options.replay_ms / 1000))
                            :gsub("%%c", tostring(Options.replay_count))
                            :gsub("%%x", x_str)
        show_osd(msg)
    else
        -- Autopause ON Mode: Immediate Replay (Fixed Segment)
        FSM.LOOP_MODE = "OFF"
        protect_internal_replay_seek()
        FSM.last_paused_sub_end = nil
        FSM.REPLAY_REMAINING = Options.replay_count
        FSM.SCHEDULED_REPLAY_START = replay_start
        FSM.SCHEDULED_REPLAY_END = replay_end
        if replay_start_idx ~= -1 then
            FSM.ACTIVE_IDX = replay_start_idx
            FSM.MANUAL_NAV_TARGET_IDX = replay_start_idx
        end
        if sec_replay_start_idx ~= -1 then
            FSM.SEC_ACTIVE_IDX = sec_replay_start_idx
            FSM.SEC_MANUAL_NAV_TARGET_IDX = sec_replay_start_idx
        end

        mp.commandv("seek", replay_start, "absolute+exact")
        if is_paused then mp.set_property_bool("pause", false) end
        if is_cross_card_replay then
            FSM.TIMESEEK_INHIBIT_UNTIL = time_pos
            FSM.REWIND_START_IDX = current_idx
            FSM.REWIND_TRANSIT_CROSS_CARD = true
        else
            FSM.TIMESEEK_INHIBIT_UNTIL = nil
            FSM.REWIND_START_IDX = nil
            FSM.REWIND_TRANSIT_CROSS_CARD = false
        end
        FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown
        local x_str = (Options.replay_count > 1) and (" (x" .. Options.replay_count .. ")") or ""
        local template = Options.replay_on_msg_format
        local msg = template:gsub("%%m", tostring(Options.replay_ms))
                            :gsub("%%s", tostring(Options.replay_ms / 1000))
                            :gsub("%%c", tostring(Options.replay_count))
                            :gsub("%%x", x_str)
        show_osd(msg)
    end
end

local function cmd_dw_seek_selected()
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end
    if FSM.DW_CURSOR_LINE > 0 and FSM.DW_CURSOR_LINE <= #subs then
        local sub = subs[FSM.DW_CURSOR_LINE]
        if sub and sub.start_time then
            -- Intentional Focus Handover
            FSM.IGNORE_NEXT_JUMP = true
            FSM.ACTIVE_IDX = FSM.DW_CURSOR_LINE
            FSM.MANUAL_NAV_TARGET_IDX = FSM.DW_CURSOR_LINE
            if #Tracks.sec.subs > 0 then
                local sec_idx = math.min(FSM.DW_CURSOR_LINE, #Tracks.sec.subs)
                FSM.SEC_ACTIVE_IDX = sec_idx
                FSM.SEC_MANUAL_NAV_TARGET_IDX = sec_idx
            end
            FSM.JUST_JERKED_TO = -1
            FSM.TIMESEEK_INHIBIT_UNTIL = nil
            FSM.REWIND_TRANSIT_CROSS_CARD = false
            FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown

            local s, _ = get_effective_boundaries(Tracks.pri.subs, sub, FSM.DW_CURSOR_LINE)
            mp.commandv("seek", s, "absolute+exact")
            FSM.last_paused_sub_end = nil
            dw_capture_neutral_marker()
            dw_apply_post_transition_selection(FSM.DW_CURSOR_WORD)
            FSM.DW_CURSOR_X = nil
            FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"

            if not FSM.BOOK_MODE then
                FSM.DW_VIEW_CENTER = FSM.DW_CURSOR_LINE
            end

            show_osd("Seeking to line: " .. FSM.DW_CURSOR_LINE)
        end
    end
end

local function cmd_dw_seek_delta(dir)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    -- Intentional Focus Handover
    -- When manually seeking, we MUST ignore the padding boundaries of the current index
    -- to prevent "Magnetic Snapping" back to the previous line.
    FSM.IGNORE_NEXT_JUMP = true
    FSM.JUST_JERKED_TO = -1
    FSM.TIMESEEK_INHIBIT_UNTIL = nil
    FSM.REWIND_TRANSIT_CROSS_CARD = false
    FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown -- Settle period for smart logic

    local current_idx = get_center_index(subs, time_pos)
    if current_idx == -1 and (not FSM.ACTIVE_IDX or FSM.ACTIVE_IDX == -1) then return end

    local base_idx = current_idx
    if FSM.ACTIVE_IDX and FSM.ACTIVE_IDX ~= -1 and subs[FSM.ACTIVE_IDX] then
        base_idx = FSM.ACTIVE_IDX
    end
    if FSM.DW_SEEKING_MANUALLY and FSM.DW_SEEK_TARGET ~= -1 then
        base_idx = FSM.DW_SEEK_TARGET
    end


    local target_idx = ((base_idx + dir - 1) % #subs) + 1
    local wrapped_msg = nil
    if dir > 0 and target_idx < base_idx then
        wrapped_msg = "Wrapped to START"
    elseif dir < 0 and target_idx > base_idx then
        wrapped_msg = "Wrapped to END"
    end

    FSM.DW_SEEK_TARGET = target_idx
    if wrapped_msg then show_osd(wrapped_msg) end
    local sub = subs[target_idx]
    if sub and sub.start_time then
        local s, _ = get_effective_boundaries(Tracks.pri.subs, sub, target_idx)
        mp.commandv("seek", math.max(0, s), "absolute+exact")
        FSM.ACTIVE_IDX = target_idx
        FSM.MANUAL_NAV_TARGET_IDX = target_idx
        if #Tracks.sec.subs > 0 then
            local sec_idx = math.min(target_idx, #Tracks.sec.subs)
            FSM.SEC_ACTIVE_IDX = sec_idx
            FSM.SEC_MANUAL_NAV_TARGET_IDX = sec_idx
        end
        FSM.last_paused_sub_end = nil
        FSM.DW_FOLLOW_PLAYER = true
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"

        if FSM.DW_ANCHOR_LINE == -1 then
            if not FSM.BOOK_MODE then
                dw_capture_neutral_marker()
                FSM.DW_ESC_NEUTRAL_ARMED = dw_is_neutral_policy_enabled()
                FSM.DW_CURSOR_LINE = target_idx
                FSM.DW_CURSOR_WORD = -1
                FSM.DW_CURSOR_X = nil
            elseif FSM.DW_CURSOR_WORD == -1 then
                -- In Book Mode, preserve intentional pointer selections, but when pointer is
                -- already cleared keep the standing line synchronized with manual a/d seeks.
                FSM.DW_CURSOR_LINE = target_idx
            end
        end

        -- Immediate visual feedback for the viewport
        if FSM.BOOK_MODE then
            dw_ensure_visible(target_idx, false)
        else
            FSM.DW_VIEW_CENTER = target_idx
        end
    end
end

local function cmd_seek_time(dir)
    local now = mp.get_time()
    local delta = dir * Options.seek_time_delta

    -- YouTube-style Accumulator logic:
    -- Accumulate ONLY if within the time window AND the direction matches.
    -- Otherwise, start a new session.
    local same_dir = (dir > 0 and FSM.SEEK_ACCUMULATOR > 0) or (dir < 0 and FSM.SEEK_ACCUMULATOR < 0)
    -- [20260510193230] Extended accumulator window for backward seeks to allow more clicks to accumulate.
    local accumulator_window = (dir < 0) and (Options.seek_osd_duration * 2) or Options.seek_osd_duration
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
    FSM.last_paused_sub_end = nil  -- Allow autopause to re-arm at the correct boundary after rewind.

    -- Suppress autopause at subtitles encountered during backward rewind transit.
    -- Autopause is inhibited until playback naturally returns past the pre-seek position.
    -- [20260510193230] Track rewind start index to distinguish within-subtitle vs cross-subtitle rewind.
    local current_pos = mp.get_property_number("time-pos") or 0
    local target_pos = math.max(0, current_pos + delta)
    local subs = Tracks.pri.subs
    local current_idx = (subs and #subs > 0) and get_center_index(subs, current_pos) or -1
    local target_idx = (subs and #subs > 0) and get_center_index(subs, target_pos) or -1
    local sec_subs = Tracks.sec.subs
    local sec_target_idx = (sec_subs and #sec_subs > 0) and get_center_index(sec_subs, target_pos) or -1
    local is_cross_card_seek = (current_idx ~= -1 and target_idx ~= -1 and current_idx ~= target_idx)

    -- Forward seek clears transit inhibit immediately.
    if delta > 0 then
        FSM.TIMESEEK_INHIBIT_UNTIL = nil
        FSM.REWIND_START_IDX = nil
        FSM.REWIND_TRANSIT_CROSS_CARD = false
    else
        -- Backward seek always contributes to sentinel (legacy contract + tests).
        -- Cross-card classification is tracked separately for suppression gating.
        FSM.TIMESEEK_INHIBIT_UNTIL = math.max(FSM.TIMESEEK_INHIBIT_UNTIL or current_pos, current_pos)
        FSM.REWIND_START_IDX = was_accumulating and (FSM.REWIND_START_IDX or current_idx) or current_idx
        FSM.REWIND_TRANSIT_CROSS_CARD = (was_accumulating and (FSM.REWIND_TRANSIT_CROSS_CARD or is_cross_card_seek)) or is_cross_card_seek
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
    local delta_str = (delta_val % 1 == 0) and tostring(math.floor(delta_val)) or string.format("%.1f", delta_val)

    local acc_prefix = (FSM.SEEK_ACCUMULATOR > 0) and "+" or "-"
    local acc_val = math.abs(FSM.SEEK_ACCUMULATOR)
    if acc_val < 0.001 then acc_val = 0; acc_prefix = "" end
    local acc_str = (acc_val % 1 == 0) and tostring(math.floor(acc_val)) or string.format("%.1f", acc_val)

    local template = (Options.seek_show_accumulator and FSM.SEEK_PRESS_COUNT >= 1)
        and Options.seek_msg_cumulative_format
        or Options.seek_msg_format

    -- On first press of an accumulator session, we might want to use the standard template
    -- but the user specified +2 -> +4 logic, so we use cumulative_format if accumulator is enabled.
    -- To allow "%p%v (%P%V)" style, we provide all variables to both.
    local msg = template:gsub("%%p", prefix):gsub("%%v", delta_str):gsub("%%P", acc_prefix):gsub("%%V", acc_str)

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
        if FSM.SEEK_REPEAT_TIMER then FSM.SEEK_REPEAT_TIMER:kill() end
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
        {key = "LEFT", name = "dw-word-left", fn = nav(function(t) cmd_dw_word_move(-1, false, false, t) end, "LEFT")},
        {key = "RIGHT", name = "dw-word-right", fn = nav(function(t) cmd_dw_word_move(1, false, false, t) end, "RIGHT")},
        {key = "UP", name = "dw-line-up", fn = nav(function(t) cmd_dw_line_move(-1, false, t) end, "UP")},
        {key = "DOWN", name = "dw-line-down", fn = nav(function(t) cmd_dw_line_move(1, false, t) end, "DOWN")},
        {key = "WHEEL_UP", name = "dw-scroll-up", fn = function() cmd_dw_wheel_scroll(-1) end},
        {key = "WHEEL_DOWN", name = "dw-scroll-down", fn = function() cmd_dw_wheel_scroll(1) end},
        {key = Options.dw_key_pair_mod, name = "dw-pair-mod-track", fn = nav(function(t)
            FSM.DW_CTRL_HELD = (t.event == "down" or t.event == "repeat")
        end, Options.dw_key_pair_mod), complex = true},
        {key = "ЛЕВЫЙ", name = "dw-word-left-ru", fn = nav(function(t) cmd_dw_word_move(-1, false, false, t) end, "ЛЕВЫЙ")},
        {key = "ПРАВЫЙ", name = "dw-word-right-ru", fn = nav(function(t) cmd_dw_word_move(1, false, false, t) end, "ПРАВЫЙ")},
        {key = "ВВЕРХ", name = "dw-line-up-ru", fn = nav(function(t) cmd_dw_line_move(-1, false, t) end, "ВВЕРХ")},
        {key = "ВНИЗ", name = "dw-line-down-ru", fn = nav(function(t) cmd_dw_line_move(1, false, t) end, "ВНИЗ")},
    }

    for _, k in ipairs(kb_keys) do
        k.is_kb = true
        table.insert(keys, k)
    end

    -- 2. Definitive Mouse Interaction Group
    local mouse_keys = {
        {key = Options.dw_key_select_extend, name = "dw-mouse-select-shift", fn = cmd_dw_mouse_select_shift, complex = true},
        {key = Options.dw_key_mouse_seek, name = "dw-mouse-dblclick", fn = cmd_dw_double_click},
    }
    for _, k in ipairs(mouse_keys) do
        k.is_mouse = true
        table.insert(keys, k)
    end

    local function parse_and_collect(key_string, base_name, mouse_fn, key_fn, updates_selection, complex)
        if not key_string or key_string == "" then return end
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
                        m_fn = make_mouse_handler(false,
                            function(t) mouse_fn(t, true) end,
                            function(t) mouse_fn(t, true) end,
                            updates_selection
                        )
                    elseif key_fn then
                        -- Fallback for mouse-bound actions that only define keyboard handlers.
                        -- Trigger on release to mimic click semantics and avoid nil callbacks.
                        m_fn = function(t)
                            if t and t.event == "up" then key_fn(t, true) end
                        end
                    end

                    if m_fn then
                        table.insert(keys, { key = key, name = base_name .. "-" .. i, fn = m_fn, complex = true, is_mouse = true })
                    end
                else
                    table.insert(keys, { key = key, name = base_name .. "-" .. i, fn = function(t)
                        local k = (t and t.key) or ""
                        if not (k == "Ctrl" or k == "Shift" or k == "Alt" or k == "Meta") then
                            FSM.DW_MOUSE_LOCK_UNTIL = mp.get_time() + (Options.dw_mouse_shield_ms / 1000)
                        end
                        key_fn(t, false)
                    end, complex = complex or false, is_kb = true })
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
        {opt = "dw_key_add",                  name = "dw-add",                  mouse_fn = cmd_dw_export_anki,           key_fn = cmd_dw_add_smart,                                    updates_selection = true},
        {opt = "dw_key_pair",                 name = "dw-pair",                 mouse_fn = cmd_dw_toggle_pink,           key_fn = cmd_dw_toggle_pink,                                  updates_selection = true},
        {opt = "dw_key_select",               name = "dw-select",               mouse_fn = cmd_dw_mouse_select,          key_fn = function() end,                                      updates_selection = true},
        {opt = "dw_key_tooltip_pin",          name = "dw-tooltip-pin",          mouse_fn = cmd_dw_tooltip_pin,           key_fn = cmd_dw_tooltip_pin},
        {opt = "dw_key_tooltip_hover",        name = "dw-tooltip-hover",        mouse_fn = cmd_toggle_dw_tooltip_hover,  key_fn = cmd_toggle_dw_tooltip_hover},
        {opt = "dw_key_tooltip_toggle",       name = "dw-tooltip-toggle",       mouse_fn = cmd_dw_tooltip_toggle,        key_fn = cmd_dw_tooltip_toggle},
        {opt = "dw_key_seek_prev",            name = "dw-seek-prev",            key_fn = function(t) cmd_seek_with_repeat(-1, t) end,                                                  complex = true},
        {opt = "dw_key_seek_next",            name = "dw-seek-next",            key_fn = function(t) cmd_seek_with_repeat(1, t) end,                                                   complex = true},
        {opt = "dw_key_search",               name = "dw-search",               key_fn = function() cmd_toggle_search() end},
        {opt = "dw_key_copy",                 name = "dw-copy",                 key_fn = function() cmd_dw_copy("none") end},
        {opt = "key_copy_popup",              name = "dw-copy-popup",           key_fn = function() cmd_dw_copy("side") end},
        {opt = "key_copy_main",               name = "dw-copy-main",            key_fn = function() cmd_dw_copy("main") end},
        {opt = "dw_key_seek",                 name = "dw-seek",                 key_fn = function() cmd_dw_seek_selected() end},
        {opt = "dw_key_esc",                  name = "dw-esc",                  key_fn = function() cmd_dw_esc() end},
        {opt = "dw_key_jump_left",            name = "dw-jump-left",            key_fn = function() cmd_dw_word_move(-dw_jump_words, false) end},
        {opt = "dw_key_jump_right",           name = "dw-jump-right",           key_fn = function() cmd_dw_word_move( dw_jump_words, false) end},
        {opt = "dw_key_jump_select_left",     name = "dw-jump-select-left",     key_fn = function() cmd_dw_word_move(-dw_jump_words, true)  end},
        {opt = "dw_key_jump_select_right",    name = "dw-jump-select-right",    key_fn = function() cmd_dw_word_move( dw_jump_words, true)  end},
        {opt = "dw_key_scroll_up",            name = "dw-scroll-up-ctrl",       key_fn = function() cmd_dw_scroll(-1) end},
        {opt = "dw_key_scroll_down",          name = "dw-scroll-down-ctrl",     key_fn = function() cmd_dw_scroll( 1) end},
        {opt = "dw_key_jump_select_up",       name = "dw-jump-select-up",       key_fn = function() cmd_dw_line_move(-dw_jump_lines, true) end},
        {opt = "dw_key_jump_select_down",     name = "dw-jump-select-down",     key_fn = function() cmd_dw_line_move( dw_jump_lines, true) end},
        {opt = "dw_key_select_left",          name = "dw-select-left",          key_fn = function() cmd_dw_word_move(-1, true) end},
        {opt = "dw_key_select_right",         name = "dw-select-right",         key_fn = function() cmd_dw_word_move( 1, true) end},
        {opt = "dw_key_select_up",            name = "dw-select-up",            key_fn = function() cmd_dw_line_move(-1, true) end},
        {opt = "dw_key_select_down",          name = "dw-select-down",          key_fn = function() cmd_dw_line_move( 1, true) end},
        {opt = "dw_key_open_record",          name = "dw-open-record",          key_fn = cmd_open_record_file},
        {opt = "dw_key_cycle_esc_mode",       name = "dw-cycle-esc-mode",       key_fn = cmd_cycle_dw_esc_mode},
        {opt = "dw_key_cycle_copy_mode",      name = "dw-cycle-copy-mode",      key_fn = cmd_cycle_copy_mode},
        {opt = "dw_key_toggle_copy_context",  name = "dw-toggle-copy-context",  key_fn = cmd_toggle_copy_ctx},
    }

    for _, d in ipairs(binding_defs) do
        parse_and_collect(Options[d.opt], d.name, d.mouse_fn, d.key_fn, d.updates_selection, d.complex)
    end


    for _, k in ipairs(keys) do
        local active = (k.is_mouse and enable_mouse) or (k.is_kb and enable_kb)
        if active and k.key and is_valid_mpv_key(k.key) and type(k.fn) == "function" then
            if not (k.key == "Ctrl" or k.key == "Shift" or k.key == "Alt" or k.key == "Meta") then
                local wrapped_fn = function(t)
                    return k.fn(t)
                end

                if k.complex then
                    mp.add_forced_key_binding(k.key, k.name, wrapped_fn, {complex = true})
                else
                    local settings = nil
                    if k.key:match("LEFT") or k.key:match("RIGHT") or k.key:match("UP") or k.key:match("DOWN")
                       or k.key:match("ЛЕВЫЙ") or k.key:match("ПРАВЫЙ") or k.key:match("ВВЕРХ") or k.key:match("ВНИЗ")
                       or k.key == "ENTER" or k.key == "KP_ENTER" then
                        settings = "repeatable"
                    end
                    mp.add_forced_key_binding(k.key, k.name, wrapped_fn, settings)
                end
            end
        else mp.remove_key_binding(k.name) end
    end

    -- Cleanup Dragging & Window state
    if not enable_mouse then
        FSM.DW_MOUSE_DRAGGING = false
        FSM.DW_MOUSE_PENDING_DRAG = false
        mp.remove_key_binding("dw-mouse-drag")
        if FSM.DW_MOUSE_SCROLL_TIMER then
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

-- ===============================================================================
-- CLIPBOARD, OSD OVERRIDES, AND MODE TOGGLES
-- ===============================================================================


local function set_clipboard(text, mode)
    if text and text ~= "" then
        mp.set_property("user-data/kardenwort/last_clipboard", text)
    end
    -- Native property is unreliable on some Windows MPV builds for system-wide sync.
    -- We skip it on Windows to ensure PowerShell (which handles retries/encoding) is used.
    local platform = package.config:sub(1,1)
    if platform ~= "\\" then
        local success = pcall(function() mp.set_property("clipboard", text) end)
        if success then return end
    end
    if platform == "\\" then
        local safe_txt = text:gsub("'", "''")
        local cmd = string.format("[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; for ($i=0; $i -lt %d; $i++) { try { Set-Clipboard -Value '%s' -ErrorAction Stop; break } catch { Start-Sleep -Milliseconds %d } }", Options.win_clipboard_retries, safe_txt, Options.win_clipboard_retry_delay)
        utils.subprocess({ args = {"powershell", "-NoProfile", "-Command", cmd}, cancellable = false })
    else
        local un = io.popen("uname -a")
        local uname_str = un and un:read("*a") or ""
        if un then un:close() end
        uname_str = uname_str:lower()

        local cmd = ""
        if uname_str:find("darwin") then
            cmd = "pbcopy"
        elseif uname_str:find("android") or (os.getenv("PREFIX") and os.getenv("PREFIX"):find("com.termux")) then
            cmd = "termux-clipboard-set"
        elseif os.getenv("WAYLAND_DISPLAY") then
            cmd = "wl-copy"
        else
            cmd = "xclip -selection clipboard -i 2>/dev/null || xsel --clipboard --input 2>/dev/null"
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
    if Options.gd_trigger_enabled == "yes" and platform == "\\" and (mode == "side" or mode == "main") then
        user_hotkey = (mode == "main") and Options.gd_hotkey_main or Options.gd_hotkey_popup
    elseif Options.tts_trigger_enabled == "yes" and platform == "\\" and mode and mode:match("^tts_[1-8]$") then
        user_hotkey = Options["tts_hotkey_" .. mode:match("([1-8])$")]
    end
    if user_hotkey and user_hotkey ~= "" then
        -- Expanded VK mapping for layout-independent triggers
        local vk_codes = {
            ctrl = 0x11, alt = 0x12, shift = 0x10, win = 0x5B,
            a = 0x41, b = 0x42, c = 0x43, d = 0x44, e = 0x45, f = 0x46, g = 0x47, h = 0x48, i = 0x49,
            j = 0x4A, k = 0x4B, l = 0x4C, m = 0x4D, n = 0x4E, o = 0x4F, p = 0x50, q = 0x51, r = 0x52,
            s = 0x53, t = 0x54, u = 0x55, v = 0x56, w = 0x57, x = 0x58, y = 0x59, z = 0x5A,
            ["0"] = 0x30, ["1"] = 0x31, ["2"] = 0x32, ["3"] = 0x33, ["4"] = 0x34,
            ["5"] = 0x35, ["6"] = 0x36, ["7"] = 0x37, ["8"] = 0x38, ["9"] = 0x39,
            f1 = 0x70, f2 = 0x71, f3 = 0x72, f4 = 0x73, f5 = 0x74, f6 = 0x75,
            f7 = 0x76, f8 = 0x77, f9 = 0x78, f10 = 0x79, f11 = 0x7A, f12 = 0x7B,
            -- Cyrillic equivalents (ЙЦУКЕН)
            ["й"] = 0x51, ["ц"] = 0x57, ["у"] = 0x45, ["к"] = 0x52, ["е"] = 0x54, ["н"] = 0x59, ["г"] = 0x55, ["ш"] = 0x49, ["щ"] = 0x4F, ["з"] = 0x50,
            ["ф"] = 0x41, ["ы"] = 0x53, ["в"] = 0x44, ["а"] = 0x46, ["п"] = 0x47, ["р"] = 0x48, ["о"] = 0x4A, ["л"] = 0x4B, ["д"] = 0x4C,
            ["я"] = 0x5A, ["ч"] = 0x58, ["с"] = 0x43, ["м"] = 0x56, ["и"] = 0x42, ["т"] = 0x4E, ["ь"] = 0x4D, ["б"] = 0xBC, ["ю"] = 0xBE
        }

        local all_events = {}
        for hotkey in user_hotkey:gmatch("[^%s,;]+") do
            local primary = hotkey:lower()
            local events = {}
            local modifiers = { "ctrl", "alt", "shift", "win" }

            -- Handle implicit shift from uppercase keys (e.g. "Ctrl+Alt+Q")
            local main_key = hotkey:match("[^+]+$")
            local needs_shift = (main_key and #main_key == 1 and main_key:match("%u")) or primary:find("shift")

            for _, mod in ipairs(modifiers) do
                if mod ~= "shift" and primary:find(mod) then
                    table.insert(events, {vk_codes[mod], 0})
                end
            end
            if needs_shift then table.insert(events, {vk_codes.shift, 0}) end

            -- Get the main key (the last part)
            local key = main_key:lower()
            if key and vk_codes[key] then
                table.insert(events, {vk_codes[key], 0}) -- Down
                table.insert(events, {vk_codes[key], 2}) -- Up
            end

            -- Release modifiers in reverse order
            for i = #events - 1, 1, -1 do
                if events[i][2] == 0 then table.insert(events, {events[i][1], 2}) end
            end

            for _, ev in ipairs(events) do table.insert(all_events, ev) end
        end

        if #all_events == 0 then return end


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
            local delay = (mode == "main") and Options.python_trigger_delay_main or Options.python_trigger_delay_popup
            local py_cmd = string.format("import ctypes, time; time.sleep(%f); u=ctypes.windll.user32; ", delay)
            for _, ev in ipairs(all_events) do
                py_cmd = py_cmd .. string.format("u.keybd_event(0x%X,0,%d,0); ", ev[1], ev[2])
            end
            mp.command_native_async({
                name = "subprocess",
                args = {Options.python_path, "-c", py_cmd},
                playback_only = false,
                capture_stdout = false, capture_stderr = false
            }, function() end)
        else
            -- Robust VK Injector via PowerShell Add-Type (Default)
            local type_name = "Win32K" .. os.time()
            local signature = '[DllImport(\"user32.dll\")] public static extern void keybd_event(byte b, byte s, uint f, uint e);'
            local script = string.format("$t = Add-Type -MemberDefinition '%s' -Name '%s' -Namespace 'Win32' -PassThru;", signature, type_name)

            for _, ev in ipairs(all_events) do
                script = script .. string.format("$t::keybd_event(0x%X,0,%d,0);", ev[1], ev[2])
            end


            mp.command_native_async({
                name = "subprocess",
                args = {"powershell", "-NoProfile", "-Command", script},
                playback_only = false,
                capture_stdout = false, capture_stderr = false
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
    local saved = FSM.saved_osd_border_style or mp.get_property("options/osd-border-style") or "background-box"
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
        if FSM.ui_border_override_depth > 1 then return end
        apply_border_override_state()
    else
        FSM.ui_border_override_depth = math.max(0, (FSM.ui_border_override_depth or 0) - 1)
        if FSM.ui_border_override_depth > 0 then return end
        apply_border_override_state()
    end
end

local function trigger_volume_suspension()
    if not FSM.saved_osd_border_style then return end
    FSM.volume_suspension_active = true
    apply_border_override_state()

    if FSM.volume_suspension_timer then FSM.volume_suspension_timer:kill() end
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
        if not active_idx or active_idx == -1 then active_idx = 1 end

        local has_pointer = (FSM.DW_CURSOR_WORD and FSM.DW_CURSOR_WORD ~= -1)
        local has_range = (FSM.DW_ANCHOR_LINE and FSM.DW_ANCHOR_LINE ~= -1 and FSM.DW_ANCHOR_WORD and FSM.DW_ANCHOR_WORD ~= -1)
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
        FSM.DW_VIEW_CENTER = (FSM.DW_CURSOR_LINE and FSM.DW_CURSOR_LINE ~= -1) and FSM.DW_CURSOR_LINE or active_idx

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




local function get_clipboard_text_smart(time_pos, line_idx)
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cw = FSM.DW_CURSOR_WORD
    local p1_l, p1_w, p2_l, p2_w = get_dw_selection_bounds()
    local has_pink_set = #FSM.DW_CTRL_PENDING_LIST > 0
    local has_yellow_range = p1_l ~= nil
    local has_yellow_point = cw ~= -1

    local cl = line_idx or FSM.DW_CURSOR_LINE

    -- 0. Smart Fallback / Focus
    -- If there is no explicit selection, trust live playback focus first.
    if line_idx == nil and not has_pink_set and not has_yellow_range and not has_yellow_point then
        if time_pos then
            cl = get_center_index(Tracks.pri.subs, time_pos)
        else
            cl = FSM.DW_ACTIVE_LINE
        end
    end

    if cl == -1 then
        if FSM.BOOK_MODE and FSM.DW_FOLLOW_PLAYER and al == -1 and cw == -1 then
            cl = FSM.DW_ACTIVE_LINE
        elseif time_pos then
            cl = get_center_index(Tracks.pri.subs, time_pos)
        else
            cl = FSM.DW_ACTIVE_LINE
        end
    end
    if cl == -1 then return nil, false end

    -- 1. Selection Priority (Pink Set > Yellow Range > Yellow Pointer)
    -- Explicit priority allows user to regulate behavior via Esc stages.

    -- Stage 1: Pink Set (Multi-word Selection via Ctrl+Click)
    if has_pink_set then
        return prepare_export_text({ type = "SET", members = FSM.DW_CTRL_PENDING_LIST }, {
            copy_mode = FSM.COPY_MODE,
            filter_russian = Options.copy_filter_russian
        }), false
    end

    -- Stage 2 & 3: Yellow Selection (Range or Point)
    if has_yellow_range or has_yellow_point then
        local params = p1_l and { type = "RANGE", p1_l = p1_l, p1_w = p1_w, p2_l = p2_l, p2_w = p2_w }
                             or { type = "POINT", line = cl, word = cw }

        return prepare_export_text(params, {
            copy_mode = FSM.COPY_MODE,
            filter_russian = Options.copy_filter_russian
        }), false
    end

    -- 2. Context Priority
    if FSM.COPY_CONTEXT == "ON" then
        local ctx = get_copy_context_text(time_pos, cl)
        if ctx and ctx ~= "" then
            return normalize_inline_break_markers(ctx):gsub("{[^}]+}", ""):gsub("\n", " "), true
        end
    end

    -- 3. Standard Fallback
    return prepare_export_text({ type = "POINT", line = cl }, {
        copy_mode = FSM.COPY_MODE,
        filter_russian = Options.copy_filter_russian
    }), false
end


function cmd_dw_copy(mode)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then return end

    local final_text, is_context = get_clipboard_text_smart()

    if final_text and final_text ~= "" then
        set_clipboard(final_text, mode)
        local now = mp.get_time()
        if (now - (FSM.LAST_OSD_TIME or 0)) > Options.copy_osd_cooldown then
            local label = is_context and "Context" or "DW"
            show_osd(build_copy_preview(label, final_text, 40))
            FSM.LAST_OSD_TIME = now
        end
    end
end

-- Subtitle visibility, track cycling, and position adjustment
local function cmd_toggle_sub_vis()
    if FSM.DRUM_WINDOW ~= "OFF" then
        show_osd("X")
        return
    end
    local function capture_sub_vis_combo()
        if FSM.SEC_ONLY_MODE then return "top" end
        if FSM.native_sub_vis and FSM.native_sec_sub_vis then return "both" end
        if FSM.native_sub_vis and not FSM.native_sec_sub_vis then return "bottom" end
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
    if current_sid ~= 0 then return true end

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
            Diagnostic.info("Secondary Sub Pos requested, but no secondary subtitle track is available")
        end
        return
    end
    if Tracks.sec.is_ass then
        show_osd("Secondary Sub Pos: Not available (ASS controls positioning)")
        return
    end
    if FSM.DRUM == "ON" then
        FSM.native_sec_sub_pos = (FSM.native_sec_sub_pos < 50) and Options.sec_pos_bottom or Options.sec_pos_top
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
    local use_osd_for_srt = (Options.srt_font_name ~= "" or Options.srt_font_bold or Options.srt_font_size > 0)
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
    local supported = {0} -- Always include OFF (0)
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
        if internal_count > 0 then msg = msg .. " [" .. internal_count .. " built-in unsupported]" end
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
                    local lang_lbl = (t.lang and t.lang ~= "und" and t.lang ~= "unknown") and t.lang:upper() or nil
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
        if aid_str == "no" then current_aid = 0 end
    end

    local supported = {0}
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
                local lang_lbl = (t.lang and t.lang ~= "und" and t.lang ~= "unknown") and t.lang:upper() or nil
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
    if FSM.OSC_VIS == 1 then lbl, cmd = "ALWAYS", "always"
    elseif FSM.OSC_VIS == 2 then lbl, cmd = "NEVER", "never" end
    mp.commandv("script-message", "osc-visibility", cmd, "no-osd")
    show_osd("OSC Visibility: " .. lbl)
end

-- ===============================================================================
-- COPY COMMAND AND SYSTEM EVENT OBSERVERS
-- ===============================================================================

-- Copy subtitle to clipboard (mode: none/side/main/tts_N)
local function cmd_copy_sub(mode)
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then return end

    local final_text, is_context = get_clipboard_text_smart(time_pos)

    if final_text and final_text ~= "" then
        set_clipboard(final_text, mode)

        local now = mp.get_time()
        if (now - (FSM.LAST_OSD_TIME or 0)) > Options.copy_osd_cooldown then
            local words, wcount = {}, 0
            for w in final_text:gmatch("%S+") do
                if wcount < Options.copy_word_limit then table.insert(words, w) end
                wcount = wcount + 1
            end
            local osd_t = table.concat(words, " ") .. (wcount > Options.copy_word_limit and "..." or "")
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
    if not ok then Diagnostic.error("sid observer: " .. tostring(err)) end
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
    if not ok then Diagnostic.error("vid observer: " .. tostring(err)) end
end)
mp.observe_property("secondary-sid", "number", function(name, val)
    local ok, err = xpcall(update_media_state, debug.traceback)
    if not ok then Diagnostic.error("sec-sid observer: " .. tostring(err)) end

    -- [20260509180045] Immediate Suppression (Window 2): Enforce visibility state after track-list update.
    local use_osd_for_srt = (Options.srt_font_name ~= "" or Options.srt_font_bold or Options.srt_font_size > 0)
    local sec_use_osd = FSM.native_sec_sub_vis and ((FSM.DRUM == "ON") or (not Tracks.sec.is_ass and use_osd_for_srt))
    if sec_use_osd then
        mp.set_property_bool("secondary-sub-visibility", false)
    end
    drum_osd:update()
end)
mp.observe_property("track-list", "native", function()
    local ok, err = xpcall(update_media_state, debug.traceback)
    if not ok then Diagnostic.error("track-list observer: " .. tostring(err)) end
    if Options.font_scaling_enabled then
        local ok2, err2 = xpcall(update_font_scale, debug.traceback)
        if not ok2 then Diagnostic.error("font-scaling: " .. tostring(err2)) end
    end
end)
mp.observe_property("osd-dimensions", "native", function()
    dw_tooltip_osd:update()
    if Options.font_scaling_enabled then
        local ok, err = xpcall(update_font_scale, debug.traceback)
        if not ok then Diagnostic.error("osd-dim observer: " .. tostring(err)) end
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
    if dw_osd then dw_osd:update() end
end)

mp.observe_property("osd-border-style", "string", function(name, val)
    FSM.osd_border_style = val
    flush_rendering_caches()
    drum_osd:update()
    if dw_osd then dw_osd:update() end
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
mp.add_key_binding(nil, "smart-space", cmd_smart_space, {complex=true})
mp.add_key_binding(nil, "toggle-drum-mode", cmd_toggle_drum)
mp.add_key_binding(nil, "toggle-sub-visibility", cmd_toggle_sub_vis)
mp.add_key_binding(nil, "toggle-secondary-only", cmd_toggle_secondary_only_mode)
mp.add_key_binding(nil, "cycle-secondary-pos", cmd_cycle_sec_pos)
mp.add_key_binding(nil, "cycle-sec-sid", cmd_cycle_sec_sid)
mp.add_key_binding(nil, "toggle-osc-visibility", cmd_toggle_osc)
mp.add_key_binding(nil, "copy-subtitle", function() cmd_copy_sub("none") end)
mp.add_key_binding(nil, "copy-subtitle-popup", function() cmd_copy_sub("side") end)
mp.add_key_binding(nil, "copy-subtitle-main", function() cmd_copy_sub("main") end)
mp.add_key_binding(nil, "copy-subtitle-tts-1", function() cmd_copy_sub("tts_1") end)
mp.add_key_binding(nil, "copy-subtitle-tts-2", function() cmd_copy_sub("tts_2") end)
mp.add_key_binding(nil, "copy-subtitle-tts-3", function() cmd_copy_sub("tts_3") end)
mp.add_key_binding(nil, "copy-subtitle-tts-4", function() cmd_copy_sub("tts_4") end)
mp.add_key_binding(nil, "copy-subtitle-tts-5", function() cmd_copy_sub("tts_5") end)
mp.add_key_binding(nil, "copy-subtitle-tts-6", function() cmd_copy_sub("tts_6") end)
mp.add_key_binding(nil, "copy-subtitle-tts-7", function() cmd_copy_sub("tts_7") end)
mp.add_key_binding(nil, "copy-subtitle-tts-8", function() cmd_copy_sub("tts_8") end)

-- Global Ctrl+Alt+C binding for main GoldenDict window
local function register_global_copy_keys()
    local bind = keybinding_utils.bind
    bind(Options.key_copy_popup, "kardenwort-global-copy-side", function() cmd_copy_sub("side") end, {wrap=true})
    bind(Options.key_copy_main, "kardenwort-global-copy-main", function() cmd_copy_sub("main") end, {wrap=true})
    bind(Options.key_tts_1, "kardenwort-global-copy-tts-1", function() cmd_copy_sub("tts_1") end, {wrap=true})
    bind(Options.key_tts_2, "kardenwort-global-copy-tts-2", function() cmd_copy_sub("tts_2") end, {wrap=true})
    bind(Options.key_tts_3, "kardenwort-global-copy-tts-3", function() cmd_copy_sub("tts_3") end, {wrap=true})
    bind(Options.key_tts_4, "kardenwort-global-copy-tts-4", function() cmd_copy_sub("tts_4") end, {wrap=true})
    bind(Options.key_tts_5, "kardenwort-global-copy-tts-5", function() cmd_copy_sub("tts_5") end, {wrap=true})
    bind(Options.key_tts_6, "kardenwort-global-copy-tts-6", function() cmd_copy_sub("tts_6") end, {wrap=true})
    bind(Options.key_tts_7, "kardenwort-global-copy-tts-7", function() cmd_copy_sub("tts_7") end, {wrap=true})
    bind(Options.key_tts_8, "kardenwort-global-copy-tts-8", function() cmd_copy_sub("tts_8") end, {wrap=true})
end
register_global_copy_keys()
mp.add_key_binding(nil, "cycle-copy-mode", cmd_cycle_copy_mode)
mp.add_key_binding(nil, "toggle-copy-context", cmd_toggle_copy_ctx)
mp.add_key_binding(nil, "toggle-drum-window", cmd_toggle_drum_window)
mp.add_key_binding(nil, "toggle-drum-search", cmd_toggle_search)
mp.add_key_binding(nil, "toggle-book-mode", toggle_book_mode)
mp.add_key_binding(nil, "replay-subtitle", cmd_replay_sub)
mp.add_key_binding(nil, "seek_prev", function(t) cmd_seek_with_repeat(-1, t) end, {complex = true})
mp.add_key_binding(nil, "seek_next", function(t) cmd_seek_with_repeat(1, t) end, {complex = true})

mp.add_key_binding(nil, "seek_time_forward", function() cmd_seek_time(1) end, {repeatable = true})
mp.add_key_binding(nil, "seek_time_backward", function() cmd_seek_time(-1) end, {repeatable = true})
mp.add_key_binding(nil, "toggle-anki-global", cmd_toggle_anki_global)
mp.add_key_binding(nil, "toggle-record-file", cmd_open_record_file)
mp.add_key_binding(nil, "cycle-immersion-mode", cmd_cycle_immersion_mode)
mp.add_key_binding(nil, "toggle-help", cmd_toggle_help)
mp.add_key_binding(nil, "cycle-audio", cmd_cycle_audio)

local function register_global_position_keys()
    local bind = keybinding_utils.bind
    bind(Options.key_sub_pos_up, "kardenwort-sub-pos-up", function() cmd_adjust_sub_pos(-1) end, {forced=true, wrap=true})
    bind(Options.key_sub_pos_down, "kardenwort-sub-pos-down", function() cmd_adjust_sub_pos(1) end, {forced=true, wrap=true})
    bind(Options.key_sec_sub_pos_up, "kardenwort-sec-sub-pos-up", function() cmd_adjust_sec_sub_pos(-1) end, {forced=true, wrap=true})
    bind(Options.key_sec_sub_pos_down, "kardenwort-sec-sub-pos-down", function() cmd_adjust_sec_sub_pos(1) end, {forced=true, wrap=true})
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
            if dw_osd then dw_osd:update() end
        end, debug.traceback)
        if not ok then Diagnostic.error("periodic sync: " .. tostring(err)) end
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
