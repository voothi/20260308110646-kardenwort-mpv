-- ===============================================================================
-- subtitle_window.lua — Unified subtitle window renderer for kardenwort
-- Contains draw_drum, draw_dw, draw_dw_tooltip, their draw caches,
-- option-profile tables, and the make_draw_cache factory.
-- Requires render_utils, text_utils, subtitle_parser for helpers.
-- build_tooltip_style_context / get_tooltip_parent_mode stay in main.lua
-- (tooltip subsystem) — injected via helpers.
-- ===============================================================================

local mp = require 'mp'
local render_utils = require 'render_utils'
local text_utils = require 'text_utils'
local subtitle_parser = require 'subtitle_parser'

local M = {}

local FSM, Options, Tracks, Diagnostic
local _helpers

function M.init(fsm, opts, tracks, diagnostic, helpers)
    assert(fsm, "FATAL: fsm dependency missing")
    assert(opts, "FATAL: opts dependency missing")
    assert(tracks, "FATAL: tracks dependency missing")
    assert(diagnostic, "FATAL: diagnostic dependency missing")
    FSM = fsm
    Options = opts
    Tracks = tracks
    Diagnostic = diagnostic
    _helpers = setmetatable(helpers or {}, {
        __index = function(t, k)
            error("FATAL: Missing injected helper function: " .. tostring(k), 2)
        end
    })
end

-- Helpers read at call time (defined in main.lua, injected via helpers).
-- Referenced directly via _helpers table — no wrapper call frames needed.

-- --- draw caches ----------------------------------------------------------
-- Initialized with defaults; set_caches() replaces them with main.lua's
-- shared cache tables so flush_rendering_caches can reset them.

local DRUM_DRAW_CACHE = {
    subs_ptr = nil, center_idx = -1, highlight_count = 0, is_drum = false,
    al = -1, aw = -1, cl = -1, cw = -1,
    pending_version = 0, layout_version = 0, result = "",
    hit_zones = nil
}

local DW_DRAW_CACHE = {
    view_center = -1, active_idx = -1, highlight_count = 0,
    subs_ptr = nil, layout_version = 0,
    cl = -1, cw = -1, al = -1, aw = -1,
    pending_version = 0, result = ""
}

local DW_TOOLTIP_DRAW_CACHE = { target_idx = -1, osd_y = -1, version = -1, cl = -1, cw = -1, av = -1 }

function M.set_caches(caches)
    DRUM_DRAW_CACHE = caches.DRUM_DRAW_CACHE
    DW_DRAW_CACHE = caches.DW_DRAW_CACHE
    DW_TOOLTIP_DRAW_CACHE = caches.DW_TOOLTIP_DRAW_CACHE
end

-- Aliases to render_utils functions (used by draw functions).
local compose_term_smart = render_utils.compose_term_smart
local calculate_highlight_stack = render_utils.calculate_highlight_stack
local populate_token_meta = render_utils.populate_token_meta
local format_highlighted_word = render_utils.format_highlighted_word
local dw_get_str_width_proportional = render_utils.dw_get_str_width_proportional
local dw_get_str_width = render_utils.dw_get_str_width
local calculate_sub_gap = render_utils.calculate_sub_gap
local wrap_tokens = render_utils.wrap_tokens
local calculate_osd_line_meta = render_utils.calculate_osd_line_meta
local dw_vline_height = render_utils.dw_vline_height
local dw_build_layout = render_utils.dw_build_layout
local dw_calculate_block_top = render_utils.dw_calculate_block_top
local format_tooltip_card_event = render_utils.format_tooltip_card_event
local format_tooltip_text_event = render_utils.format_tooltip_text_event

-- Aliases to text_utils functions.
local calculate_ass_alpha = text_utils.calculate_ass_alpha
local get_sub_tokens = text_utils.get_sub_tokens

-- Aliases to subtitle_parser functions.
local get_center_index = subtitle_parser.get_center_index

-- --- make_draw_cache factory -----------------------------------------------

function M.make_draw_cache(fields)
    local cache = {}
    for _, f in ipairs(fields) do
        cache[f] = -1
    end
    cache.result = ""
    cache.hit_zones = nil
    return cache
end

-- --- option-profile tables ------------------------------------------------

-- Populated at init from existing Options.<mode>_* keys.
-- User-facing script-opts keys are unchanged.
M.profiles = {}

function M.build_profiles()
    local modes = {"drum", "srt", "dw", "tooltip"}
    local shared_keys = {
        "font_name", "font_size", "font_bold",
        "line_height_mul", "vsp", "double_gap", "block_gap_mul",
        "active_color", "context_color",
        "active_opacity", "context_opacity",
        "active_bold", "context_bold",
        "active_size_mul", "context_size_mul",
        "bg_color", "bg_opacity", "border_size", "shadow_offset",
        "pri_highlight_color", "sec_highlight_color",
        "pri_ctrl_select_color", "sec_ctrl_select_color",
        "pri_highlight_bold", "sec_highlight_bold",
    }
    for _, mode in ipairs(modes) do
        M.profiles[mode] = {}
        for _, key in ipairs(shared_keys) do
            local opt_key = mode .. "_" .. key
            M.profiles[mode][key] = Options[opt_key]
        end
    end
end

-- --- draw_drum ------------------------------------------------------------

local function format_sub_wrapped(meta, is_active, t_pos, is_drum, font_name, font_size)
    local tokens = meta.tokens
    local vlines = meta.vlines
    local token_meta = meta.token_meta
    if #tokens == 0 or not token_meta then return "" end

    local base_color = is_drum and (is_active and Options.drum_active_color or Options.drum_context_color)
                                or (is_active and Options.srt_active_color or Options.srt_context_color)
    local opacity = calculate_ass_alpha(is_drum and (is_active and Options.drum_active_opacity or Options.drum_context_opacity)
                                                  or (is_active and Options.srt_active_opacity or Options.srt_context_opacity))
    local f_bold = is_drum and Options.drum_font_bold or Options.srt_font_bold
    local bold_state = (is_active and (is_drum and Options.drum_active_bold or f_bold)
                                  or (is_drum and Options.drum_context_bold or f_bold)) and "1" or "0"
    local size = font_size * (is_active and Options.drum_active_size_mul or Options.drum_context_size_mul)

    local line_strings = {}
    for _, vl in ipairs(vlines) do
        local formatted_parts = {}
        for _, j in ipairs(vl.token_indices) do
            local meta_item = token_meta[j]
            if meta_item.priority >= 1 or (meta_item.priority == 0 and meta_item.is_phrase) then
                local final_bold = (meta_item.priority == 3) and Options.anki_highlight_bold or meta.h_bold
                local is_man = (meta_item.priority == 1 or meta_item.priority == 2)
                local bg_alpha = calculate_ass_alpha(is_drum and Options.drum_bg_opacity or Options.srt_bg_opacity)
                table.insert(formatted_parts, format_highlighted_word({text = meta_item.text}, meta_item.color, base_color, meta_item.is_phrase, bold_state, true, final_bold, is_man, is_drum and Options.drum_bg_color or Options.srt_bg_color, bg_alpha, is_drum and Options.drum_border_size or Options.srt_border_size))
            else
                table.insert(formatted_parts, meta_item.text)
            end
        end
        local line_text = ""
        if Options.dw_original_spacing then
            line_text = table.concat(formatted_parts, "")
        else
            line_text = compose_term_smart(formatted_parts)
        end
        table.insert(line_strings, (line_text:gsub("\n", "")))
    end

    local result_text = table.concat(line_strings, "\\N")
    return string.format("{\\fn%s}{\\1a&H%s&}{\\b%s}{\\1c&H%s&}{\\fs%d}%s",
        font_name, opacity, bold_state, base_color, size, result_text)
end

local function draw_drum(subs, view_center, active_idx, y_pos_percent, time_pos, font_size, hit_zones, force_plain, is_pri)
    if view_center == -1 then return "" end

    if DRUM_DRAW_CACHE.subs_ptr == subs and
       DRUM_DRAW_CACHE.view_center     == view_center and
       DRUM_DRAW_CACHE.active_idx      == active_idx and
       DRUM_DRAW_CACHE.is_drum         == (FSM.DRUM == "ON") and
       DRUM_DRAW_CACHE.highlight_count == #FSM.ANKI_HIGHLIGHTS and
       DRUM_DRAW_CACHE.layout_version   == FSM.LAYOUT_VERSION and
       DRUM_DRAW_CACHE.al              == FSM.DW_ANCHOR_LINE and
       DRUM_DRAW_CACHE.aw              == FSM.DW_ANCHOR_WORD and
       DRUM_DRAW_CACHE.cl              == FSM.DW_CURSOR_LINE and
       DRUM_DRAW_CACHE.cw              == FSM.DW_CURSOR_WORD and
       DRUM_DRAW_CACHE.pending_version == (FSM.DW_CTRL_PENDING_VERSION or 0) then

        if hit_zones and DRUM_DRAW_CACHE.hit_zones then
            for k, v in ipairs(DRUM_DRAW_CACHE.hit_zones) do hit_zones[k] = v end
        end
        return DRUM_DRAW_CACHE.result
    end

    local is_drum = (FSM.DRUM == "ON")
    local context_lines = is_drum and Options.drum_context_lines or 0
    local half = context_lines
    local start_idx = math.max(1, view_center - half)
    local end_idx = math.min(#subs, view_center + half)

    if end_idx - start_idx < 2 * half then
        if start_idx == 1 then
            end_idx = math.min(#subs, start_idx + 2 * half)
        elseif end_idx == #subs then
            start_idx = math.max(1, end_idx - 2 * half)
        end
    end

    local is_top = (y_pos_percent < 50)
    local y_pixel = y_pos_percent * 1080 / 100

    local is_drum_mode = (FSM.DRUM == "ON")
    local prefix = is_drum_mode and "drum" or "srt"
    local font_name = is_drum_mode and (Options.drum_font_name ~= "" and Options.drum_font_name or mp.get_property("sub-font", "Inter"))
                                   or (Options.srt_font_name ~= "" and Options.srt_font_name or mp.get_property("sub-font", "Inter"))
    local lh_mul = is_drum_mode and Options.drum_line_height_mul or Options.srt_line_height_mul
    local vsp = is_drum_mode and Options.drum_vsp or Options.srt_vsp
    local d_gap = Options[prefix .. "_double_gap"]
    local adj = (not d_gap) and (Options.drum_gap_adj or 0) or 0

    local sub_metas = {}
    local total_h = 0

    for i = start_idx, end_idx do
        local is_active = (i == active_idx)
        local size = font_size * (is_active and Options.drum_active_size_mul or Options.drum_context_size_mul)
        local m = calculate_osd_line_meta(subs[i].text, i, size, font_name, lh_mul, vsp)

        local base_color = is_drum_mode and (is_active and Options.drum_active_color or Options.drum_context_color)
                                        or (is_active and Options.srt_active_color or Options.srt_context_color)

        local h_color = is_drum_mode and (is_pri and Options.drum_pri_highlight_color or Options.drum_sec_highlight_color)
                                     or (is_pri and Options.srt_pri_highlight_color or Options.srt_sec_highlight_color)
        local c_color = is_drum_mode and (is_pri and Options.drum_pri_ctrl_select_color or Options.drum_sec_ctrl_select_color)
                                     or (is_pri and Options.srt_pri_ctrl_select_color or Options.srt_sec_ctrl_select_color)
        local h_bold = is_drum_mode and (is_pri and Options.drum_pri_highlight_bold or Options.drum_sec_highlight_bold)
                                    or (is_pri and Options.srt_pri_highlight_bold or Options.srt_sec_highlight_bold)

        m.token_meta = populate_token_meta(subs, i, m.tokens, base_color, subs[i].start_time, nil, force_plain, h_color, c_color)
        m.h_bold = h_bold

        table.insert(sub_metas, m)
        total_h = total_h + m.total_height
        if i < end_idx then
            total_h = total_h + calculate_sub_gap(prefix, m.size, lh_mul, vsp) + adj
        end
    end

    local y_start = y_pixel
    if not is_top then y_start = y_pixel - total_h end

    local cur_y = y_start
    for _, m in ipairs(sub_metas) do
        if hit_zones and Options.osd_interactivity then
            for _, vl in ipairs(m.vlines) do
                vl.y_top = cur_y + vl.y_offset
                vl.y_bottom = vl.y_top + vl.height
                vl.x_start = 960 - vl.total_width / 2
                vl.sub_idx = m.sub_idx
                vl.is_pri = is_pri
                table.insert(hit_zones, vl)
            end
        end
        cur_y = cur_y + m.total_height
        if m.sub_idx < end_idx then
            cur_y = cur_y + calculate_sub_gap(prefix, m.size, lh_mul, vsp) + adj
        end
    end

    local bg_color = is_drum and Options.drum_bg_color or Options.srt_bg_color
    local bg_opacity = is_drum and Options.drum_bg_opacity or Options.srt_bg_opacity
    local bord = is_drum and Options.drum_border_size or Options.srt_border_size
    local shad = is_drum and Options.drum_shadow_offset or Options.srt_shadow_offset

    local all_text = ""
    local vsp_tag = vsp ~= 0 and string.format("{\\vsp%g}", vsp) or ""

    for i, m in ipairs(sub_metas) do
        local line_text = format_sub_wrapped(m, m.sub_idx == active_idx, subs[m.sub_idx].start_time, is_drum, font_name, font_size)
        if i == 1 then
            all_text = line_text
        else
            local prev_is_active = (sub_metas[i-1].sub_idx == active_idx)
            local line_fs = font_size * (prev_is_active and Options.drum_active_size_mul or Options.drum_context_size_mul)
            local vsp_extra = d_gap and (line_fs * Options[prefix .. "_block_gap_mul"] / 2) or 0
            local separator = string.format("{\\vsp%g}%s{\\vsp%g}", vsp + vsp_extra + adj, d_gap and "\\N\\N" or "\\N", vsp)
            all_text = all_text .. separator .. line_text
        end
    end

    local style_block = string.format("{\\bord%g}{\\shad%g}{\\3c&H%s&}{\\4c&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\q2}%s",
        bord, shad, bg_color, bg_color, calculate_ass_alpha(bg_opacity), calculate_ass_alpha(bg_opacity), vsp_tag)

    local ass = ""
    if is_top then
        ass = ass .. string.format("{\\pos(960, %d)}{\\an8}{\\fs%d}%s%s\n", y_pixel, font_size, style_block, all_text)
    else
        ass = ass .. string.format("{\\pos(960, %d)}{\\an2}{\\fs%d}%s%s\n", y_pixel, font_size, style_block, all_text)
    end

    DRUM_DRAW_CACHE.subs_ptr        = subs
    DRUM_DRAW_CACHE.view_center     = view_center
    DRUM_DRAW_CACHE.active_idx      = active_idx
    DRUM_DRAW_CACHE.is_drum         = (FSM.DRUM == "ON")
    DRUM_DRAW_CACHE.highlight_count = #FSM.ANKI_HIGHLIGHTS
    DRUM_DRAW_CACHE.layout_version  = FSM.LAYOUT_VERSION
    DRUM_DRAW_CACHE.al              = FSM.DW_ANCHOR_LINE
    DRUM_DRAW_CACHE.aw              = FSM.DW_ANCHOR_WORD
    DRUM_DRAW_CACHE.cl              = FSM.DW_CURSOR_LINE
    DRUM_DRAW_CACHE.cw              = FSM.DW_CURSOR_WORD
    DRUM_DRAW_CACHE.pending_version = FSM.DW_CTRL_PENDING_VERSION or 0
    DRUM_DRAW_CACHE.result          = ass

    if hit_zones then
        DRUM_DRAW_CACHE.hit_zones = {}
        for k, v in ipairs(hit_zones) do DRUM_DRAW_CACHE.hit_zones[k] = v end
    else
        DRUM_DRAW_CACHE.hit_zones = nil
    end

    return ass
end

-- --- draw_dw --------------------------------------------------------------

local function draw_dw(subs, view_center, active_idx)
    if not subs or #subs == 0 then return "" end

    if DW_DRAW_CACHE.view_center    == view_center and
       DW_DRAW_CACHE.active_idx     == active_idx and
       DW_DRAW_CACHE.subs_ptr       == subs and
       DW_DRAW_CACHE.highlight_count == #FSM.ANKI_HIGHLIGHTS and
       DW_DRAW_CACHE.layout_version  == FSM.LAYOUT_VERSION and
       DW_DRAW_CACHE.cl             == FSM.DW_CURSOR_LINE and
       DW_DRAW_CACHE.cw             == FSM.DW_CURSOR_WORD and
       DW_DRAW_CACHE.al             == FSM.DW_ANCHOR_LINE and
       DW_DRAW_CACHE.aw             == FSM.DW_ANCHOR_WORD and
       DW_DRAW_CACHE.pending_version == (FSM.DW_CTRL_PENDING_VERSION or 0) then

        if DW_DRAW_CACHE.hit_zones then FSM.DW_HIT_ZONES = DW_DRAW_CACHE.hit_zones end
        if DW_DRAW_CACHE.line_y_map then FSM.DW_LINE_Y_MAP = DW_DRAW_CACHE.line_y_map end
        return DW_DRAW_CACHE.result
    end

    local bg_alpha = calculate_ass_alpha(Options.dw_bg_opacity)
    local layout, total_height = dw_build_layout(subs, view_center)
    local lh_mul = Options.dw_line_height_mul
    local block_top = dw_calculate_block_top(view_center, active_idx, layout, total_height)
    local current_y = block_top
    FSM.DW_LINE_Y_MAP = {}
    FSM.DW_HIT_ZONES = {}

    for layout_i, entry in ipairs(layout) do
        local i = entry.sub_idx
        local is_active = (i == active_idx)
        local base_color = is_active and Options.dw_active_color or Options.dw_context_color
        entry.token_meta = populate_token_meta(subs, i, entry.words, base_color, subs[i].start_time, entry, not Options.dw_pri_highlighting, Options.dw_highlight_color, Options.dw_ctrl_select_color)
    end

    local all_visual_lines_ass = {}
    local min_x = math.huge
    local max_x = -math.huge
    for layout_i, entry in ipairs(layout) do
        local i = entry.sub_idx
        local entry_y_top = current_y

        FSM.DW_LINE_Y_MAP[i] = math.floor(current_y + (entry.height / 2) + 0.5)
        current_y = current_y + entry.height
        if layout_i < #layout then
            local is_active = (entry.sub_idx == active_idx)
            local line_fs = Options.dw_font_size * (is_active and Options.dw_active_size_mul or Options.dw_context_size_mul)
            current_y = current_y + calculate_sub_gap("dw", line_fs, lh_mul, Options.dw_vsp)
        end

        local is_active = (i == active_idx)
        local color = is_active and Options.dw_active_color or Options.dw_context_color
        local opacity = calculate_ass_alpha(is_active and Options.dw_active_opacity or Options.dw_context_opacity)
        local font_name = (Options.dw_font_name ~= "") and Options.dw_font_name or mp.get_property("sub-font", "Inter")
        local bold_state = (is_active and Options.dw_active_bold or Options.dw_context_bold) and "1" or "0"
        local f_size = Options.dw_font_size * (is_active and Options.dw_active_size_mul or Options.dw_context_size_mul)
        local line_prefix = string.format("{\\fn%s}{\\fs%d}{\\b%s}{\\1c&H%s&}{\\1a&H%s&}", font_name, f_size, bold_state, color, opacity)

        local token_meta = entry.token_meta
        local vline_h = dw_vline_height()
        for vl_index, vl_indices in ipairs(entry.vlines) do
            local formatted_words = {}
            local space_w = dw_get_str_width(" ", f_size, font_name)
            local line_words = {}
            local line_w = 0

            for pos, j in ipairs(vl_indices) do
                local t = entry.words[j]
                local ww = dw_get_str_width(t.text, f_size, font_name)
                local space = (pos > 1 and not Options.dw_original_spacing) and space_w or 0

                if t.logical_idx then
                    table.insert(line_words, {
                        logical_idx = t.logical_idx,
                        x_offset = line_w + space,
                        width = ww,
                        text = t.text
                    })
                end
                line_w = line_w + space + ww

                local meta_item = token_meta[j]
                if meta_item.priority >= 1 or (meta_item.priority == 0 and meta_item.is_phrase) then
                    local final_bold = (meta_item.priority == 3) and Options.anki_highlight_bold or Options.dw_highlight_bold
                    local is_manual = (meta_item.priority == 1 or meta_item.priority == 2)
                    table.insert(formatted_words, format_highlighted_word({text = meta_item.text}, meta_item.color, color, meta_item.is_phrase, bold_state, true, final_bold, is_manual, Options.dw_bg_color, bg_alpha, Options.dw_border_size))
                else
                    table.insert(formatted_words, meta_item.text)
                end
            end

            local vl_y_top = entry_y_top + (vl_index - 1) * vline_h
            local vl_y_bottom = vl_y_top + vline_h
            local line_x_start = 960 - line_w / 2

            table.insert(FSM.DW_HIT_ZONES, {
                sub_idx = entry.sub_idx,
                y_top = vl_y_top,
                y_bottom = vl_y_bottom,
                x_start = line_x_start,
                total_width = line_w,
                words = line_words,
            })
            min_x = math.min(min_x, line_x_start)
            max_x = math.max(max_x, line_x_start + line_w)

            local line_text = ""
            if Options.dw_original_spacing then
                line_text = table.concat(formatted_words, "")
            else
                line_text = compose_term_smart(formatted_words)
            end
            local line_style = string.format("{\\pos(960, %g)}{\\an8}{\\bord%g}{\\shad%g}{\\3c&H%s&}{\\4c&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\q2}",
                vl_y_top, Options.dw_border_size, Options.dw_shadow_offset, Options.dw_bg_color, Options.dw_bg_color, bg_alpha, bg_alpha)
            local line_ass = line_style .. line_prefix .. line_text
            table.insert(all_visual_lines_ass, line_ass)
        end
    end

    FSM.DW_BLOCK_TOP = block_top
    FSM.DW_TOTAL_HEIGHT = total_height

    if min_x == math.huge then
        min_x = 960
        max_x = 960
    end
    local pad_x = math.max(8, (Options.dw_border_size or 0) * 4)
    local pad_y = math.max(4, (Options.dw_border_size or 0) * 2)
    local rect_left = min_x - pad_x
    local rect_top = block_top - pad_y
    local rect_w = math.max(1, (max_x - min_x) + (2 * pad_x))
    local rect_h = math.max(1, total_height + (2 * pad_y))
    local bg_rect = string.format("{\\pos(%g, %g)}{\\an7}{\\bord%g}{\\shad%g}{\\3c&H%s&}{\\4c&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\1c&H%s&}{\\1a&H%s&}{\\p1}m 0 0 l %g 0 l %g %g l 0 %g{\\p0}",
        rect_left, rect_top, Options.dw_border_size, Options.dw_shadow_offset, Options.dw_bg_color, Options.dw_bg_color, bg_alpha, bg_alpha, Options.dw_bg_color, bg_alpha, rect_w, rect_w, rect_h, rect_h)
    local final_ass = bg_rect
    if #all_visual_lines_ass > 0 then
        final_ass = final_ass .. "\n" .. table.concat(all_visual_lines_ass, "\n")
    end

    DW_DRAW_CACHE.view_center    = view_center
    DW_DRAW_CACHE.active_idx     = active_idx
    DW_DRAW_CACHE.subs_ptr       = subs
    DW_DRAW_CACHE.highlight_count = #FSM.ANKI_HIGHLIGHTS
    DW_DRAW_CACHE.layout_version  = FSM.LAYOUT_VERSION
    DW_DRAW_CACHE.cl             = FSM.DW_CURSOR_LINE
    DW_DRAW_CACHE.cw             = FSM.DW_CURSOR_WORD
    DW_DRAW_CACHE.al             = FSM.DW_ANCHOR_LINE
    DW_DRAW_CACHE.aw             = FSM.DW_ANCHOR_WORD
    DW_DRAW_CACHE.pending_version = (FSM.DW_CTRL_PENDING_VERSION or 0)
    DW_DRAW_CACHE.result          = final_ass

    DW_DRAW_CACHE.hit_zones = FSM.DW_HIT_ZONES
    DW_DRAW_CACHE.line_y_map = FSM.DW_LINE_Y_MAP

    return final_ass
end

local build_tooltip_style_context = function(mode)
    return _helpers.build_tooltip_style_context(mode)
end
local get_tooltip_parent_mode = function()
    return _helpers.get_tooltip_parent_mode()
end

-- --- draw_dw_tooltip ------------------------------------------------------

local function draw_dw_tooltip(subs, target_line_idx, osd_y)
    local tooltip_sec_subs = (Tracks.sec.subs and #Tracks.sec.subs > 0) and Tracks.sec.subs or FSM.DW_TOOLTIP_SEC_SUBS
    if target_line_idx == -1 or not tooltip_sec_subs or #tooltip_sec_subs == 0 then return "" end

    if DW_TOOLTIP_DRAW_CACHE.target_idx == target_line_idx and
       DW_TOOLTIP_DRAW_CACHE.osd_y == osd_y and
       DW_TOOLTIP_DRAW_CACHE.version == FSM.LAYOUT_VERSION and
       DW_TOOLTIP_DRAW_CACHE.cl == FSM.DW_CURSOR_LINE and
       DW_TOOLTIP_DRAW_CACHE.cw == FSM.DW_CURSOR_WORD and
       DW_TOOLTIP_DRAW_CACHE.av == FSM.ANKI_VERSION then

        if DW_TOOLTIP_DRAW_CACHE.hit_zones then
            FSM.DW_TOOLTIP_HIT_ZONES = {}
            for k, v in ipairs(DW_TOOLTIP_DRAW_CACHE.hit_zones) do FSM.DW_TOOLTIP_HIT_ZONES[k] = v end
        end
        return DW_TOOLTIP_DRAW_CACHE.result
    end

    local primary_sub = subs[target_line_idx]
    if not primary_sub then return "" end

    local fs = Options.tooltip_font_size
    local line_height = fs * Options.tooltip_line_height_mul
    local base_h = Options.font_base_height or 1080
    local base_w = math.floor(base_h * 16 / 9)
    local anchor_x = base_w - math.floor((120 * base_h / 1080) + 0.5)
    local style_ctx = build_tooltip_style_context(get_tooltip_parent_mode())
    local midpoint = (primary_sub.start_time + primary_sub.end_time) / 2
    local center_idx = get_center_index(tooltip_sec_subs, midpoint)
    if center_idx == -1 then return "" end

    local start_idx = math.max(1, center_idx - Options.tooltip_context_lines)
    local end_idx = math.min(#tooltip_sec_subs, center_idx + Options.tooltip_context_lines)

    local font_name = (Options.tooltip_font_name ~= "") and Options.tooltip_font_name or mp.get_property("sub-font", "Inter")
    local mono_hint = font_name:lower():match("consolas") or font_name:lower():match("mono")
    local max_text_w = math.floor(base_w * 0.73)
    local total_visual_lines = 0
    local subtitle_metas = {}

    for i = start_idx, end_idx do
        local sub = tooltip_sec_subs[i]
        local tokens = get_sub_tokens(sub, true) or {}

        local vline_indices = wrap_tokens(tokens, max_text_w, fs, font_name, true)

        if #vline_indices == 0 then
            vline_indices = {{}}
        end

        local is_active = (i == center_idx)
        local base_color = is_active and Options.tooltip_active_color or Options.tooltip_context_color
        local opacity = is_active and Options.tooltip_active_opacity or Options.tooltip_context_opacity
        local bold_state = (is_active and Options.tooltip_active_bold or Options.tooltip_context_bold) and "1" or "0"
        local alpha_tag = string.format("{\\1a&H%s&}", calculate_ass_alpha(opacity))

        local force_plain = not Options.dw_sec_highlighting
        local token_meta = populate_token_meta(tooltip_sec_subs, i, tokens, base_color, sub.start_time, nil, force_plain, Options.tooltip_highlight_color, Options.tooltip_ctrl_select_color)

        local visual_lines_meta = {}
        for _, indices in ipairs(vline_indices) do
            local line_text = ""
            local line_w = 0
            local line_words = {}
            for _, idx in ipairs(indices) do
                local t = tokens[idx]
                local tm = token_meta[idx]
                local ww = dw_get_str_width(t.text, fs, font_name)
                if mono_hint then
                    ww = math.max(ww, dw_get_str_width_proportional(t.text, fs))
                end

                if t.is_word and t.logical_idx then
                    table.insert(line_words, {
                        logical_idx = t.logical_idx,
                        x_offset = line_w,
                        width = ww
                    })
                end

                local final_bold = (tm.priority == 3) and Options.anki_highlight_bold or Options.tooltip_highlight_bold
                local is_man = (tm.priority == 1 or tm.priority == 2)
                line_text = line_text .. format_highlighted_word(t, tm.color, base_color, tm.is_phrase, bold_state, true, final_bold, is_man, style_ctx.bg_color, style_ctx.bg_alpha, style_ctx.bord)
                line_w = line_w + ww
            end
            local line_prefix = string.format("{\\fn%s}{\\fs%d}{\\b%s}{\\1c&H%s&}", font_name, fs, bold_state, base_color)
            table.insert(visual_lines_meta, {
                width = line_w,
                words = line_words,
                line_text = line_prefix .. alpha_tag .. line_text
            })
            total_visual_lines = total_visual_lines + 1
        end

        table.insert(subtitle_metas, {sub_idx = i, visual_lines = visual_lines_meta})
    end

    local bord = style_ctx.bord
    local rect_bg_alpha = style_ctx.card_alpha

    local layout_line_h = line_height + Options.tooltip_vsp
    local total_gap = calculate_sub_gap("tooltip", fs, Options.tooltip_line_height_mul, Options.tooltip_vsp)

    local num_logical_blocks = end_idx - start_idx + 1
    local block_height = (total_visual_lines * layout_line_h)
    if num_logical_blocks > 1 then
        block_height = block_height + ((num_logical_blocks - 1) * total_gap)
    end

    local half_h = block_height / 2
    local margin = 20
    local screen_h = base_h
    local pad_x = math.max(16, (bord or 0) * 6)
    local pad_y = math.max(4, (bord or 0) * 2)
    local pad_top = pad_y + math.max(0, tonumber(Options.tooltip_top_pad_extra) or 0)

    local logical_interval = layout_line_h + total_gap
    local final_y = osd_y + (Options.tooltip_y_offset_lines * logical_interval)
    local half_h_with_pad = half_h + pad_top

    if final_y - half_h_with_pad < margin then
        final_y = margin + half_h_with_pad
    elseif final_y + half_h_with_pad > screen_h - margin then
        final_y = screen_h - margin - half_h_with_pad
    end

    FSM.DW_TOOLTIP_HIT_ZONES = {}
    local all_tooltip_lines_ass = {}
    local min_x = math.huge
    local max_x = -math.huge
    local cur_y = final_y - half_h
    for _, sm in ipairs(subtitle_metas) do
        for _, vl in ipairs(sm.visual_lines) do
            local line_x_start = anchor_x - vl.width
            table.insert(FSM.DW_TOOLTIP_HIT_ZONES, {
                sub_idx = sm.sub_idx,
                y_top = cur_y,
                y_bottom = cur_y + layout_line_h,
                x_start = line_x_start,
                total_width = vl.width,
                words = vl.words
            })
            min_x = math.min(min_x, line_x_start)
            max_x = math.max(max_x, line_x_start + vl.width)

            local line_center_y = cur_y + (layout_line_h / 2)
            local line_ass = format_tooltip_text_event(style_ctx, anchor_x, line_center_y, vl.line_text)
            table.insert(all_tooltip_lines_ass, line_ass)

            cur_y = cur_y + layout_line_h
        end
        cur_y = cur_y + total_gap
    end

    if min_x == math.huge then
        min_x = anchor_x
        max_x = anchor_x
    end
    local block_top = final_y - half_h
    local rect_left = min_x - pad_x
    local rect_top = block_top - pad_top
    local rect_w = math.max(1, (max_x - min_x) + (2 * pad_x))
    local rect_h = math.max(1, block_height + (2 * pad_top))

    local bg_rect = format_tooltip_card_event(style_ctx, rect_left, rect_top, rect_w, rect_h, rect_bg_alpha)

    local ass = bg_rect
    if #all_tooltip_lines_ass > 0 then
        ass = ass .. "\n" .. table.concat(all_tooltip_lines_ass, "\n")
    end

    DW_TOOLTIP_DRAW_CACHE.target_idx = target_line_idx
    DW_TOOLTIP_DRAW_CACHE.osd_y = osd_y
    DW_TOOLTIP_DRAW_CACHE.version = FSM.LAYOUT_VERSION
    DW_TOOLTIP_DRAW_CACHE.cl = FSM.DW_CURSOR_LINE
    DW_TOOLTIP_DRAW_CACHE.cw = FSM.DW_CURSOR_WORD
    DW_TOOLTIP_DRAW_CACHE.av = FSM.ANKI_VERSION
    DW_TOOLTIP_DRAW_CACHE.result = ass

    DW_TOOLTIP_DRAW_CACHE.hit_zones = {}
    for k, v in ipairs(FSM.DW_TOOLTIP_HIT_ZONES) do DW_TOOLTIP_DRAW_CACHE.hit_zones[k] = v end

    return ass
end

-- --- module exports --------------------------------------------------------

M.format_sub_wrapped = format_sub_wrapped
M.draw_drum = draw_drum
M.draw_dw = draw_dw
M.draw_dw_tooltip = draw_dw_tooltip

return M
