-- ============================================================================
-- mouse_input.lua — Drum/DW mouse interaction, hit-testing, drag/scroll
-- ============================================================================

local mp = require("mp")
local text_utils = require("text_utils")
local subtitle_parser = require("subtitle_parser")
local subtitle_window = require("subtitle_window")
local tooltip = require("tooltip")

local M = {}

local get_center_index = subtitle_parser.get_center_index

local FSM, Options, Tracks, Diagnostic
local _helpers

function M.init(fsm, opts, tracks, diag, helpers)
    assert(fsm, "FATAL: fsm dependency missing")
    assert(opts, "FATAL: opts dependency missing")
    assert(tracks, "FATAL: tracks dependency missing")
    assert(diag, "FATAL: diag dependency missing")
    assert(helpers, "FATAL: helpers dependency missing")
    assert(helpers.dw_osd, "FATAL: helper 'dw_osd' missing")
    assert(helpers.drum_osd, "FATAL: helper 'drum_osd' missing")
    assert(helpers.is_inside_dw_selection, "FATAL: helper 'is_inside_dw_selection' missing")
    assert(helpers.ctrl_commit_set, "FATAL: helper 'ctrl_commit_set' missing")
    assert(helpers.dw_anki_export_selection, "FATAL: helper 'dw_anki_export_selection' missing")
    assert(helpers.show_osd, "FATAL: helper 'show_osd' missing")

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

function dw_get_mouse_osd()
    local mouse = mp.get_property_native("mouse-pos")
    if not mouse then
        return 960, 540
    end
    local mx = mouse.x or 0
    local my = mouse.y or 0
    local osd = mp.get_property_native("osd-dimensions")
    local ow = osd and osd.w or 1920
    local oh = osd and osd.h or 1080
    if ow == 0 then
        ow = 1920
    end
    if oh == 0 then
        oh = 1080
    end

    local scale_isotropic = oh / 1080
    local osd_y = my / scale_isotropic
    local osd_x = 960 + ((mx - (ow / 2)) / scale_isotropic)

    return osd_x, osd_y
end

local function dw_hit_test(osd_x, osd_y)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return nil, nil
    end

    if not FSM.DW_HIT_ZONES or #FSM.DW_HIT_ZONES == 0 then
        subtitle_window.draw_dw(subs, FSM.DW_VIEW_CENTER, FSM.ACTIVE_IDX)
    end
    if not FSM.DW_HIT_ZONES or #FSM.DW_HIT_ZONES == 0 then
        return nil, nil
    end

    local first_zone = FSM.DW_HIT_ZONES[1]
    local last_zone = FSM.DW_HIT_ZONES[#FSM.DW_HIT_ZONES]

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
                local tokens = text_utils.get_sub_tokens(last_sub) or {}
                local cnt = 0
                for _, t in ipairs(tokens) do
                    if text_utils.is_word_token(t) then
                        cnt = cnt + 1
                    end
                end
                word_idx = math.max(1, cnt)
            end
        end
        return last_zone.sub_idx, word_idx
    end

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
                local tokens = text_utils.get_sub_tokens(sub) or {}
                local cnt = 0
                for _, t in ipairs(tokens) do
                    if text_utils.is_word_token(t) then
                        cnt = cnt + 1
                    end
                end
                word_idx = math.max(1, cnt)
            end
        end
        return best_zone.sub_idx, word_idx
    end

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

    local neighbor =
        dw_resolve_neighbor_word(FSM.DW_HIT_ZONES, best_zone.sub_idx, best_zone.y_top, osd_x)
    return best_zone.sub_idx, neighbor or 1
end

local function dw_tooltip_hit_test(osd_x, osd_y)
    local tooltip_active = (FSM.DW_TOOLTIP_LINE ~= -1)
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local drum_mode = tooltip.is_osd_tooltip_mode_eligible()
    if not tooltip_active or not FSM.DW_TOOLTIP_HIT_ZONES then
        return nil, nil
    end
    if not dw_mode and not drum_mode then
        return nil, nil
    end
    if dw_mode and not Options.dw_sec_interactivity then
        return nil, nil
    end
    if not dw_mode and not Options.drum_sec_interactivity then
        return nil, nil
    end

    for _, line in ipairs(FSM.DW_TOOLTIP_HIT_ZONES) do
        if osd_y >= line.y_top and osd_y <= line.y_bottom then
            local rel_x = osd_x - line.x_start
            if rel_x >= 0 and rel_x <= line.total_width then
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
    if not FSM.DRUM_HIT_ZONES or not Options.osd_interactivity then
        return nil, nil, nil
    end

    local best_line = nil
    local min_y_dist = 60

    for _, line in ipairs(FSM.DRUM_HIT_ZONES) do
        local rel_x = osd_x - line.x_start
        if rel_x >= 0 and rel_x <= line.total_width then
            local dist_y = 0
            if osd_y < line.y_top then
                dist_y = line.y_top - osd_y
            elseif osd_y > line.y_bottom then
                dist_y = osd_y - line.y_bottom
            end

            if dist_y < min_y_dist then
                min_y_dist = dist_y
                best_line = line
                if dist_y == 0 then
                    break
                end
            end
        end
    end

    if best_line then
        local line = best_line
        local rel_x = osd_x - line.x_start
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
    if not line_idx then
        return nil
    end
    if hit_pri then
        return line_idx
    end

    local sec_subs = (Tracks.sec.subs and #Tracks.sec.subs > 0) and Tracks.sec.subs
        or FSM.DW_TOOLTIP_SEC_SUBS
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
    if not Options.osd_interactivity then
        return nil, nil, nil
    end

    if FSM.DRUM_WINDOW ~= "OFF" then
        if Options.dw_sec_interactivity then
            local l, w = dw_tooltip_hit_test(osd_x, osd_y)
            if l then
                return l, w, false
            end
        end
        if Options.dw_pri_interactivity then
            local l, w = dw_hit_test(osd_x, osd_y)
            return l, w, true
        end
        return nil, nil, nil
    else
        local is_drum = (FSM.DRUM == "ON")
        local pri_enabled = is_drum and Options.drum_pri_interactivity
            or Options.srt_pri_interactivity
        local sec_enabled = is_drum and Options.drum_sec_interactivity
            or Options.srt_sec_interactivity

        if pri_enabled or sec_enabled then
            local line, word, hit_pri = drum_osd_hit_test(osd_x, osd_y)
            if not line then
                return nil, nil, nil
            end

            if hit_pri and not pri_enabled then
                return nil, nil, nil
            end
            if not hit_pri and not sec_enabled then
                return nil, nil, nil
            end

            return line, word, hit_pri
        end
    end
    return nil, nil, nil
end

local function dw_sync_cursor_to_mouse()
    if mp.get_time() < (FSM.DW_MOUSE_LOCK_UNTIL or 0) then
        return
    end

    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return
    end

    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx, word_idx

    if FSM.DRUM_WINDOW ~= "OFF" or Options.osd_interactivity then
        line_idx, word_idx = kardenwort_hit_test_all(osd_x, osd_y)
    end

    if line_idx and word_idx then
        if FSM.DW_MOUSE_DRAGGING and not FSM.DW_PROTECTED_SELECTION then
            FSM.DW_CURSOR_LINE = line_idx
            FSM.DW_CURSOR_WORD = word_idx
        end

        if FSM.DRUM_WINDOW ~= "OFF" then
            local active_idx = get_center_index(subs, mp.get_property_number("time-pos") or 0)
            _helpers.dw_osd.data = subtitle_window.draw_dw(subs, FSM.DW_VIEW_CENTER, active_idx)
            _helpers.dw_osd:update()
        else
            _helpers.drum_osd:update()
        end
    end
end

function get_dw_drag_threshold_px()
    local threshold = tonumber(Options.dw_mouse_drag_threshold_px) or 5
    if threshold < 0 then
        return 0
    end
    return threshold
end

function get_dw_mouse_auto_scroll_interval()
    local interval = tonumber(Options.dw_mouse_auto_scroll_interval) or 0.05
    if interval <= 0 then
        return 0.05
    end
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
    if not best_zone then
        return nil
    end

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
        if not FSM.DW_MOUSE_PENDING_DRAG then
            return
        end

        local osd_x, osd_y = dw_get_mouse_osd()
        if not dw_pointer_exceeded_drag_threshold(osd_x, osd_y) then
            return
        end

        FSM.DW_MOUSE_PENDING_DRAG = false
        FSM.DW_MOUSE_DRAGGING = true
    end

    dw_sync_cursor_to_mouse()
end

function dw_get_auto_scroll_block_zones(hit_zones, dm_mode, is_pri)
    if not hit_zones or #hit_zones == 0 then
        return nil, nil
    end
    if not dm_mode then
        return hit_zones[1], hit_zones[#hit_zones]
    end

    local target_is_pri = (is_pri ~= false)
    local first_zone = nil
    local last_zone = nil
    for _, zone in ipairs(hit_zones) do
        if zone.is_pri == target_is_pri and zone.y_top and zone.y_bottom then
            if not first_zone or zone.y_top < first_zone.y_top then
                first_zone = zone
            end
            if not last_zone or zone.y_bottom > last_zone.y_bottom then
                last_zone = zone
            end
        end
    end
    return first_zone, last_zone
end

local function dw_mouse_auto_scroll()
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local dm_mode = (FSM.DRUM == "ON" and FSM.DRUM_WINDOW == "OFF")
    if not dw_mode and not dm_mode then
        return
    end

    dw_mouse_update_selection()

    if not FSM.DW_MOUSE_DRAGGING then
        return
    end
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return
    end

    local _, osd_y = dw_get_mouse_osd()

    local DW_EDGE_SCROLL_RATIO_MAX = 0.49
    local base_h = Options.font_base_height or 1080
    local edge_ratio = tonumber(Options.dw_mouse_edge_scroll_ratio) or 0.15
    if edge_ratio < 0 then
        edge_ratio = 0
    end
    if edge_ratio > DW_EDGE_SCROLL_RATIO_MAX then
        edge_ratio = DW_EDGE_SCROLL_RATIO_MAX
    end
    local edge_zone = base_h * edge_ratio
    local top_scroll_trigger = edge_zone
    local bottom_scroll_trigger = base_h - edge_zone
    local hit_zones = dw_mode and FSM.DW_HIT_ZONES or FSM.DRUM_HIT_ZONES
    local first_zone, last_zone =
        dw_get_auto_scroll_block_zones(hit_zones, dm_mode, FSM.DW_DRAG_IS_PRI)
    if not first_zone or not last_zone then
        return
    end
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
        local dw_overflows_bottom = last_zone.y_bottom
            and last_zone.y_bottom >= (base_h - edge_activation_pad)
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
            if FSM.DW_CURSOR_LINE > 1 then
                FSM.DW_CURSOR_LINE = FSM.DW_CURSOR_LINE - 1
            end
            scrolled = true
        end
    elseif osd_y > (bottom_scroll_trigger + edge_activation_pad) then
        if FSM.DW_VIEW_CENTER < #subs then
            FSM.DW_VIEW_CENTER = FSM.DW_VIEW_CENTER + 1
            if FSM.DW_CURSOR_LINE < #subs then
                FSM.DW_CURSOR_LINE = FSM.DW_CURSOR_LINE + 1
            end
            scrolled = true
        end
    end

    if scrolled then
        dw_mouse_update_selection()
    end
end

local function cmd_dw_tooltip_pin(tbl)
    if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then
        _helpers.show_osd("X")
        return
    end
    Diagnostic.debug("TOOLTIP PIN: event=" .. tostring(tbl.event))
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local drum_mode = tooltip.is_osd_tooltip_mode_eligible()
    if not dw_mode and not drum_mode then
        return
    end

    if tbl.event == "down" then
        FSM.DW_TOOLTIP_FORCE = false
        FSM.DW_TOOLTIP_HOLDING = true
        local subs = Tracks.pri.subs
        if not subs or #subs == 0 then
            return
        end

        local osd_x, osd_y = dw_get_mouse_osd()
        local line_idx = resolve_tooltip_target_line(subs, osd_x, osd_y, dw_mode)

        if line_idx then
            FSM.DW_TOOLTIP_LOCKED_LINE = -1
            FSM.DW_TOOLTIP_LINE = line_idx
            local y = tooltip.get_tooltip_line_y(line_idx, osd_y)
            if y then
                y = math.floor(y + 0.5)
            end
            local ass = subtitle_window.draw_dw_tooltip(subs, line_idx, y)
            if ass ~= "" then
                tooltip.apply_tooltip_ass(ass)
            end
            Diagnostic.debug(
                "TOOLTIP ROUTE: PIN->"
                    .. (dw_mode and "DW" or "DRUM")
                    .. " line="
                    .. tostring(line_idx)
            )
        end
    elseif tbl.event == "up" then
        FSM.DW_TOOLTIP_HOLDING = false
    end
end

local function cmd_toggle_dw_tooltip_hover()
    if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then
        _helpers.show_osd("X")
        return
    end
    FSM.DW_TOOLTIP_MODE = (FSM.DW_TOOLTIP_MODE == "CLICK") and "HOVER" or "CLICK"
    _helpers.show_osd("DW Translation: " .. FSM.DW_TOOLTIP_MODE)
    if FSM.DW_TOOLTIP_MODE == "CLICK" then
        FSM.DW_TOOLTIP_FORCE = false
        tooltip.clear_tooltip_overlay("hover-mode-click")
    end
end

local function cmd_dw_tooltip_toggle()
    if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then
        _helpers.show_osd("X")
        return
    end
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local drum_mode = tooltip.is_osd_tooltip_mode_eligible()
    if not dw_mode and not drum_mode then
        return
    end

    if FSM.DW_TOOLTIP_FORCE then
        Diagnostic.info("TOOLTIP TOGGLE: OFF (" .. (dw_mode and "DW" or "DRUM") .. ")")
        FSM.DW_TOOLTIP_FORCE = false
        tooltip.clear_tooltip_overlay("toggle-off")
        return
    end

    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return
    end

    local is_paused = mp.get_property_bool("pause", true)
    local line_idx = -1

    if is_paused then
        line_idx = (FSM.DW_TOOLTIP_TARGET_MODE == "CURSOR") and FSM.DW_CURSOR_LINE
            or FSM.DW_ACTIVE_LINE
        if line_idx == -1 then
            line_idx = FSM.DW_CURSOR_LINE
        end
    else
        line_idx = FSM.DW_ACTIVE_LINE
    end

    if line_idx ~= -1 then
        Diagnostic.info("TOOLTIP TOGGLE: ON (" .. (dw_mode and "DW" or "DRUM") .. ")")
        FSM.DW_TOOLTIP_FORCE = true
        FSM.DW_TOOLTIP_LINE = line_idx
        local y = tooltip.get_tooltip_line_y(line_idx, nil)
        if not y then
            y = 540
        else
            y = math.floor(y + 0.5)
        end
        local ass = subtitle_window.draw_dw_tooltip(subs, line_idx, y)
        if ass ~= "" then
            tooltip.apply_tooltip_ass(ass)
        end
    end
end

local function dw_tooltip_mouse_update()
    local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
    local drum_mode = tooltip.is_osd_tooltip_mode_eligible()
    if not dw_mode and not drum_mode then
        tooltip.clear_tooltip_overlay("mode-ineligible")
        FSM.DW_TOOLTIP_FORCE = false
        return
    end
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return
    end

    local osd_x, osd_y = dw_get_mouse_osd()
    local line_idx = resolve_tooltip_target_line(subs, osd_x, osd_y, dw_mode)

    if FSM.DW_TOOLTIP_FORCE then
        local is_paused = mp.get_property_bool("pause", true)
        local target_l
        if not is_paused then
            target_l = FSM.DW_ACTIVE_LINE
        else
            target_l = (FSM.DW_TOOLTIP_TARGET_MODE == "ACTIVE") and FSM.DW_ACTIVE_LINE
                or FSM.DW_CURSOR_LINE
        end

        if target_l ~= -1 then
            FSM.DW_TOOLTIP_LINE = target_l
            local y = tooltip.get_tooltip_line_y(target_l, nil)
            if y then
                y = math.floor(y + 0.5)
                local new_ass = subtitle_window.draw_dw_tooltip(subs, target_l, y)
                if new_ass ~= "" then
                    tooltip.apply_tooltip_ass(new_ass)
                elseif dw_mode then
                    tooltip.clear_tooltip_overlay("forced-render-empty")
                end
            else
                if dw_mode then
                    tooltip.clear_tooltip_overlay("forced-target-missing")
                end
            end
        end
        return
    end

    if FSM.DW_MOUSE_DRAGGING or (line_idx and line_idx == FSM.DW_TOOLTIP_LOCKED_LINE) then
        if FSM.DW_TOOLTIP_LINE ~= -1 then
            tooltip.clear_tooltip_overlay("drag-or-locked")
        end
        return
    end

    if not FSM.DW_MOUSE_DRAGGING and line_idx ~= FSM.DW_TOOLTIP_LOCKED_LINE then
        FSM.DW_TOOLTIP_LOCKED_LINE = -1
    end

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
            local target_y = tooltip.get_tooltip_line_y(target_l, nil)
            if target_y then
                target_y = math.floor(target_y + 0.5)
                local new_ass = subtitle_window.draw_dw_tooltip(subs, target_l, target_y)
                FSM.DW_TOOLTIP_LINE = target_l
                if new_ass ~= "" then
                    tooltip.apply_tooltip_ass(new_ass)
                elseif dw_mode then
                    tooltip.clear_tooltip_overlay("hover-render-empty")
                end
            else
                if not FSM.DW_TOOLTIP_HOLDING and FSM.DW_TOOLTIP_LINE ~= -1 then
                    if dw_mode then
                        tooltip.clear_tooltip_overlay("target-y-missing")
                    end
                end
            end
        elseif not FSM.DW_TOOLTIP_HOLDING then
            if FSM.DW_TOOLTIP_LINE ~= -1 then
                if dw_mode then
                    tooltip.clear_tooltip_overlay("hover-gap")
                end
            end
        end
    else
        if FSM.DW_TOOLTIP_LINE ~= -1 then
            if dw_mode and line_idx and line_idx ~= FSM.DW_TOOLTIP_LINE then
                tooltip.clear_tooltip_overlay("click-focus-left")
            end
        end
    end
end

-- --- make_mouse_handler logic mapping ---

local MOUSE_HANDLERS = {}

local function make_mouse_handler(is_shift, on_up_callback, on_down_callback, updates_selection)
    if updates_selection == nil then
        updates_selection = true
    end
    local handler = function(tbl)
        if mp.get_time() < (FSM.DW_MOUSE_LOCK_UNTIL or 0) then
            return
        end

        if tbl.event == "down" then
            FSM.DW_FOLLOW_PLAYER = false
            FSM.DW_MOUSE_DRAGGING = false
            FSM.DW_MOUSE_PENDING_DRAG = false
            if FSM.DW_MOUSE_SCROLL_TIMER then
                FSM.DW_MOUSE_SCROLL_TIMER:kill()
                FSM.DW_MOUSE_SCROLL_TIMER = nil
            end

            local osd_x, osd_y = dw_get_mouse_osd()
            FSM.DW_MOUSE_DOWN_X, FSM.DW_MOUSE_DOWN_Y = osd_x, osd_y

            local is_tooltip_hit = dw_tooltip_hit_test(osd_x, osd_y)
            local line_idx, word_idx, is_pri = kardenwort_hit_test_all(osd_x, osd_y)

            if line_idx then
                FSM.DW_TOOLTIP_LOCKED_LINE = line_idx
                FSM.DW_DRAG_IS_PRI = is_pri

                if FSM.DW_TOOLTIP_LINE ~= -1 and not is_tooltip_hit then
                    FSM.DW_TOOLTIP_LINE = -1
                    tooltip.apply_tooltip_ass("")
                end

                if on_down_callback then
                    on_down_callback(tbl)
                end

                if word_idx and updates_selection then
                    local is_inside = on_up_callback
                        and _helpers.is_inside_dw_selection(line_idx, word_idx)
                    FSM.DW_PROTECTED_SELECTION = is_inside and not is_shift

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

                    FSM.DW_MOUSE_PENDING_DRAG = true
                    FSM.DW_MOUSE_DRAGGING = false
                    mp.add_forced_key_binding(
                        "mouse_move",
                        "dw-mouse-drag",
                        dw_mouse_update_selection
                    )
                    FSM.DW_MOUSE_SCROLL_TIMER = mp.add_periodic_timer(
                        get_dw_mouse_auto_scroll_interval(),
                        dw_mouse_auto_scroll
                    )

                    _helpers.drum_osd:update()
                    if FSM.DRUM_WINDOW ~= "OFF" then
                        _helpers.dw_osd:update()
                    end
                end
            end
        elseif tbl.event == "up" then
            FSM.DW_MOUSE_DRAGGING = false
            FSM.DW_MOUSE_PENDING_DRAG = false

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

            if on_up_callback then
                on_up_callback(tbl)
            end
        end
    end
    MOUSE_HANDLERS[handler] = true
    return handler
end

local cmd_dw_mouse_select = make_mouse_handler(false)
local cmd_dw_mouse_select_shift = make_mouse_handler(true)
MOUSE_HANDLERS[cmd_dw_tooltip_pin] = true

local function dw_anki_export_smart_callback(tbl)
    if tbl and tbl.event ~= "up" then
        return
    end

    local starts_pink = false
    if FSM.DW_ANCHOR_LINE ~= -1 then
        local line_set = FSM.DW_CTRL_PENDING_SET[FSM.DW_ANCHOR_LINE]
        if line_set and line_set[FSM.DW_ANCHOR_WORD] then
            starts_pink = true
        end
    end

    if starts_pink then
        _helpers.ctrl_commit_set(FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD)
    else
        _helpers.dw_anki_export_selection()
    end
end

local cmd_dw_export_anki = make_mouse_handler(false, dw_anki_export_smart_callback)

-- Module Exports
M.dw_get_mouse_osd = dw_get_mouse_osd
M.dw_hit_test = dw_hit_test
M.dw_tooltip_hit_test = dw_tooltip_hit_test
M.drum_osd_hit_test = drum_osd_hit_test
M.resolve_tooltip_target_line = resolve_tooltip_target_line
M.kardenwort_hit_test_all = kardenwort_hit_test_all
M.dw_sync_cursor_to_mouse = dw_sync_cursor_to_mouse
M.get_dw_drag_threshold_px = get_dw_drag_threshold_px
M.get_dw_mouse_auto_scroll_interval = get_dw_mouse_auto_scroll_interval
M.dw_pointer_exceeded_drag_threshold = dw_pointer_exceeded_drag_threshold
M.dw_resolve_neighbor_word = dw_resolve_neighbor_word
M.dw_mouse_update_selection = dw_mouse_update_selection
M.dw_get_auto_scroll_block_zones = dw_get_auto_scroll_block_zones
M.dw_mouse_auto_scroll = dw_mouse_auto_scroll
M.cmd_dw_tooltip_pin = cmd_dw_tooltip_pin
M.cmd_toggle_dw_tooltip_hover = cmd_toggle_dw_tooltip_hover
M.cmd_dw_tooltip_toggle = cmd_dw_tooltip_toggle
M.dw_tooltip_mouse_update = dw_tooltip_mouse_update

M.make_mouse_handler = make_mouse_handler
M.cmd_dw_mouse_select = cmd_dw_mouse_select
M.cmd_dw_mouse_select_shift = cmd_dw_mouse_select_shift
M.cmd_dw_export_anki = cmd_dw_export_anki
M.MOUSE_HANDLERS = MOUSE_HANDLERS

return M
