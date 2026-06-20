-- ============================================================================
-- tooltip.lua — Drum/SRT/DW Tooltip styling and overlay helpers
-- ============================================================================

local mp = require("mp")
local text_utils = require("text_utils")

local M = {}

local FSM, Options, Tracks, Diagnostic
local _helpers

function M.init(fsm, opts, tracks, diag, helpers)
    assert(fsm, "FATAL: fsm dependency missing")
    assert(opts, "FATAL: opts dependency missing")
    assert(tracks, "FATAL: tracks dependency missing")
    assert(diag, "FATAL: diag dependency missing")
    assert(helpers, "FATAL: helpers dependency missing")
    assert(helpers.dw_tooltip_osd, "FATAL: helper 'dw_tooltip_osd' missing")
    assert(helpers.manage_ui_border_override, "FATAL: helper 'manage_ui_border_override' missing")
    assert(helpers.DW_TOOLTIP_DRAW_CACHE, "FATAL: helper 'DW_TOOLTIP_DRAW_CACHE' missing")

    FSM = fsm
    Options = opts
    Tracks = tracks
    Diagnostic = diag
    _helpers = setmetatable(helpers, {
        __index = function(t, k)
            error("FATAL: Missing injected helper function: " .. tostring(k), 2)
        end,
    })
end

-- --- Functions below match exact signatures expected by structural tests ---

local apply_tooltip_ass

local calculate_ass_alpha = text_utils.calculate_ass_alpha

function normalize_tooltip_native_box_policy()
    local policy = tostring(Options.tooltip_native_box_policy or "auto"):lower()
    if policy ~= "auto" and policy ~= "neutralize" and policy ~= "override" then
        return "auto"
    end
    return policy
end

function get_tooltip_parent_mode()
    if FSM.DRUM_WINDOW ~= "OFF" then
        return "dw"
    end
    if FSM.DRUM == "ON" then
        return "dm"
    end
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
        card_alpha = (
            Options.tooltip_dw_bg_alpha
            and Options.tooltip_dw_bg_alpha ~= ""
            and Options.tooltip_dw_bg_alpha
        ) or card_alpha
    elseif parent_mode == "dm" then
        card_alpha = (
            Options.tooltip_dm_bg_alpha
            and Options.tooltip_dm_bg_alpha ~= ""
            and Options.tooltip_dm_bg_alpha
        ) or card_alpha
    elseif parent_mode == "srt" then
        card_alpha = (
            Options.tooltip_srt_bg_alpha
            and Options.tooltip_srt_bg_alpha ~= ""
            and Options.tooltip_srt_bg_alpha
        ) or card_alpha
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
    if not _helpers.dw_tooltip_osd then
        return
    end
    ass = ass or ""
    local will_visible = (ass ~= "")
    local wants_override = false
    if will_visible then
        local style_ctx = build_tooltip_style_context(get_tooltip_parent_mode())
        wants_override = style_ctx.needs_override
    end
    local has_override = (FSM.DW_TOOLTIP_BORDER_OVERRIDE == true)
    if wants_override and not has_override then
        _helpers.manage_ui_border_override(true)
        has_override = true
    elseif not wants_override and has_override then
        _helpers.manage_ui_border_override(false)
        has_override = false
    end
    FSM.DW_TOOLTIP_BORDER_OVERRIDE = has_override
    if ass ~= _helpers.dw_tooltip_osd.data then
        _helpers.dw_tooltip_osd.data = ass
        _helpers.dw_tooltip_osd:update()
    end
end

local function invalidate_dw_tooltip_cache()
    local cache = _helpers.DW_TOOLTIP_DRAW_CACHE
    if not cache then
        return
    end
    cache.target_idx = -1
    cache.osd_y = -1
    cache.version = -1
    cache.cl = -1
    cache.cw = -1
    cache.av = -1
    cache.result = ""
    cache.hit_zones = nil
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
    local use_osd_for_srt = (
        Options.srt_font_name ~= ""
        or Options.srt_font_bold
        or Options.srt_font_size > 0
    )
    local srt_active = (FSM.DRUM == "OFF" and use_osd_for_srt)

    return (FSM.DRUM == "ON" or srt_active)
        and FSM.DRUM_WINDOW == "OFF"
        and FSM.native_sub_vis
        and not FSM.MEDIA_STATE:match("ASS")
        and Options.osd_interactivity
end

local function get_tooltip_line_y(line_idx, fallback_y)
    if not line_idx or line_idx == -1 then
        return nil
    end
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

-- Export module interfaces
M.normalize_tooltip_native_box_policy = normalize_tooltip_native_box_policy
M.get_tooltip_parent_mode = get_tooltip_parent_mode
M.build_tooltip_style_context = build_tooltip_style_context
M.apply_tooltip_ass = apply_tooltip_ass
M.invalidate_dw_tooltip_cache = invalidate_dw_tooltip_cache
M.clear_tooltip_overlay = clear_tooltip_overlay
M.is_osd_tooltip_mode_eligible = is_osd_tooltip_mode_eligible
M.get_tooltip_line_y = get_tooltip_line_y

return M
