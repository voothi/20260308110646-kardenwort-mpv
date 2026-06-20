-- ============================================================================
-- dw_navigation.lua — Subtitle Window navigation and selection commands
-- ============================================================================

local mp = require("mp")
local text_utils = require("text_utils")
local render_utils = require("render_utils")
local dw_esc = require("dw_esc")
local tsv_export = require("tsv_export")
local help_hud = require("help_hud")
local subtitle_parser = require("subtitle_parser")

local M = {}

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
    assert(helpers.dw_tooltip_osd, "FATAL: helper 'dw_tooltip_osd' missing")
    assert(helpers.set_clipboard, "FATAL: helper 'set_clipboard' missing")
    assert(helpers.show_osd, "FATAL: helper 'show_osd' missing")
    assert(helpers.dw_get_mouse_osd, "FATAL: helper 'dw_get_mouse_osd' missing")
    assert(helpers.kardenwort_hit_test_all, "FATAL: helper 'kardenwort_hit_test_all' missing")
    assert(helpers.protect_internal_replay_seek, "FATAL: helper 'protect_internal_replay_seek' missing")
    assert(helpers.dw_sync_cursor_to_mouse, "FATAL: helper 'dw_sync_cursor_to_mouse' missing")

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

-- Import text_utils aliases
local get_sub_tokens = text_utils.get_sub_tokens
local logical_cmp = text_utils.logical_cmp
local build_word_list = text_utils.build_word_list
local build_word_list_internal = text_utils.build_word_list_internal
local normalize_inline_break_markers = text_utils.normalize_inline_break_markers
local build_copy_preview = text_utils.build_copy_preview
local L_EPSILON = text_utils.L_EPSILON

-- Import tsv_export aliases
local get_copy_context_text = tsv_export.get_copy_context_text
local prepare_export_text = tsv_export.prepare_export_text
local extract_anki_context = tsv_export.extract_anki_context
local save_anki_tsv_row = tsv_export.save_anki_tsv_row

-- Import subtitle_parser aliases
local get_center_index = subtitle_parser.get_center_index
local get_effective_boundaries = subtitle_parser.get_effective_boundaries

-- Import render_utils aliases
local dw_get_str_width = render_utils.dw_get_str_width
local dw_vline_height = render_utils.dw_vline_height

local function dw_reset_selection()
    dw_esc.reset_selection()
end

-- 1. is_inside_dw_selection
local function is_inside_dw_selection(l, w)
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
    if al == -1 or cl == -1 or aw == -1 or cw == -1 then
        return false
    end

    local p1_l, p1_w, p2_l, p2_w
    if al < cl or (al == cl and aw <= cw) then
        p1_l, p1_w, p2_l, p2_w = al, aw, cl, cw
    else
        p1_l, p1_w, p2_l, p2_w = cl, cw, al, aw
    end

    if l < p1_l or l > p2_l then
        return false
    end
    if l == p1_l and w < p1_w - L_EPSILON then
        return false
    end
    if l == p2_l and w > p2_w + L_EPSILON then
        return false
    end
    return true
end

-- 2. get_dw_selection_bounds
local function get_dw_selection_bounds()
    local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
    local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD

    if al == -1 or aw == -1 or cl == -1 or cw == -1 then
        return nil
    end
    if al == cl and logical_cmp(aw, cw) then
        return nil
    end -- Single word is not a "range selection" in this context

    if al < cl or (al == cl and aw < cw + L_EPSILON) then
        return al, aw, cl, cw
    else
        return cl, cw, al, aw
    end
end

-- 3. get_first_valid_word_idx
local function get_first_valid_word_idx(sub)
    if not sub then
        return -1
    end
    local tokens = get_sub_tokens(sub)
    if not tokens then
        return -1
    end
    for _, t in ipairs(tokens) do
        if t.is_word then
            return t.logical_idx
        end
    end
    return -1
end

-- 4. ensure_sub_layout
local function ensure_sub_layout(sub)
    if not sub then
        return nil
    end
    if sub.layout_cache and sub.layout_cache.version == FSM.LAYOUT_VERSION then
        return sub.layout_cache.entry
    end

    local tokens = get_sub_tokens(sub) or {}
    if #tokens == 0 then
        tokens = { { text = "" } }
    end
    local font_size = Options.dw_font_size
    local font_name = Options.dw_font_name
    local max_w = 1860
    local space_w = dw_get_str_width(" ", font_size, font_name)

    local logical_to_visual = {}
    for j, t in ipairs(tokens) do
        if t.logical_idx then
            logical_to_visual[t.logical_idx] = j
        end
    end

    local vlines = {}
    local cur_indices = {}
    local cur_w = 0
    for j, w in ipairs(tokens) do
        local ww = dw_get_str_width(w, font_size, font_name)
        local space = (#cur_indices > 0 and not Options.dw_original_spacing) and space_w or 0
        if cur_w + space + ww > max_w and #cur_indices > 0 then
            table.insert(vlines, cur_indices)
            cur_indices = { j }
            cur_w = ww
        else
            table.insert(cur_indices, j)
            cur_w = cur_w + space + ww
        end
    end
    if #cur_indices > 0 then
        table.insert(vlines, cur_indices)
    end
    if #vlines == 0 then
        vlines = { { 1 } }
    end

    local entry_h = #vlines * dw_vline_height()

    sub.layout_cache = {
        version = FSM.LAYOUT_VERSION,
        entry = {
            sub_idx = -1, -- caller-specific; draw path will overwrite with real index
            vlines = vlines,
            logical_to_visual = logical_to_visual,
            words = tokens,
            height = entry_h,
        },
    }
    return sub.layout_cache.entry
end

-- 5. dw_get_word_visual_line
local function dw_get_word_visual_line(sub, logical_idx)
    local entry = ensure_sub_layout(sub)
    if not entry then
        return 1, 1
    end

    local v_idx = entry.logical_to_visual[logical_idx]
    if not v_idx then
        return 1, 1
    end
    for i, vl in ipairs(entry.vlines) do
        for _, idx in ipairs(vl) do
            if idx == v_idx then
                return i, #entry.vlines
            end
        end
    end
    return 1, 1
end

-- 6. dw_closest_word_at_x
local function dw_closest_word_at_x(sub, target_x, word_only, vl_filter)
    local entry = ensure_sub_layout(sub)
    if not entry then
        return -1
    end

    local words = entry.words or {}
    local vlines = entry.vlines
    local visual_to_logical = {}
    for j, t in ipairs(words or {}) do
        if t.logical_idx then
            visual_to_logical[j] = t.logical_idx
        end
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
                if k < #vl_indices and not Options.dw_original_spacing then
                    vl_width = vl_width + space_w
                end
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

-- 7. dw_pick_middle_word_idx
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

-- 8. dw_compute_word_center_x
local function dw_compute_word_center_x(sub)
    if not sub or FSM.DW_CURSOR_WORD == -1 then
        return nil
    end
    local entry = ensure_sub_layout(sub)
    if not entry then
        return nil
    end

    local v_idx = entry.logical_to_visual[FSM.DW_CURSOR_WORD]
    if not v_idx then
        return nil
    end

    local vl_idx, _ = dw_get_word_visual_line(sub, FSM.DW_CURSOR_WORD)
    local vl_indices = entry.vlines[vl_idx]
    if not vl_indices then
        return nil
    end

    local space_w = dw_get_str_width(" ")
    local vl_width = 0
    for k, wi in ipairs(vl_indices) do
        vl_width = vl_width + dw_get_str_width(entry.words[wi])
        if k < #vl_indices and not Options.dw_original_spacing then
            vl_width = vl_width + space_w
        end
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

-- 9. dw_ensure_visible
local function dw_ensure_visible(line_idx, paged)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return
    end

    local is_drum_mini = (FSM.DRUM == "ON" and FSM.DRUM_WINDOW == "OFF")
    local is_srt = (FSM.DRUM == "OFF" and FSM.DRUM_WINDOW == "OFF")
    local win_lines = is_srt and 1
        or (is_drum_mini and (Options.drum_context_lines * 2 + 1) or Options.dw_lines_visible)
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

-- 10. dw_create_nav_event_snapshot
local function dw_create_nav_event_snapshot(evt)
    local time_pos = mp.get_property_number("time-pos")
    return {
        time = time_pos or 0,
        paused = mp.get_property_bool("pause"),
        is_repeat = (type(evt) == "table" and evt.event == "repeat"),
        event = evt,
    }
end

-- 11. dw_resolve_nav_intent_context
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
            if
                snapshot.time >= (s - Options.nav_tolerance)
                and snapshot.time <= (e + Options.nav_tolerance)
            then
                ctx.active_line = best
            end
        end

        -- Lookahead: check if next sub is already in its padding range
        -- This eliminates "lag" when the player hasn't fired the official event yet.
        local next_idx = (best ~= -1) and (best + 1) or 1
        if next_idx <= #subs then
            local ns, ne = get_effective_boundaries(subs, subs[next_idx], next_idx)
            if
                snapshot.time >= (ns - Options.nav_tolerance)
                and snapshot.time <= (ne + Options.nav_tolerance)
            then
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

-- 12. ctrl_discard_set
local function ctrl_discard_set()
    -- Reset both the persistent pending set (Pink) and any active selection range anchors (Gold)
    FSM.DW_CTRL_PENDING_SET = {}
    FSM.DW_CTRL_PENDING_LIST = {}
    FSM.DW_ANCHOR_LINE = -1
    FSM.DW_ANCHOR_WORD = -1
    if FSM.DRUM_WINDOW ~= "OFF" then
        FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
        _helpers.dw_osd:update()
    end
end

-- 13. ctrl_toggle_word
local function ctrl_toggle_word(line_idx, word_idx, no_sync)
    if line_idx < 1 or word_idx < 0 then
        return
    end

    if not FSM.DW_CTRL_PENDING_SET[line_idx] then
        FSM.DW_CTRL_PENDING_SET[line_idx] = {}
    end

    local line_set = FSM.DW_CTRL_PENDING_SET[line_idx]
    if line_set[word_idx] then
        line_set[word_idx] = nil
        -- Clean up empty line tables to keep iteration fast
        local has_any = false
        for _ in pairs(line_set) do
            has_any = true
            break
        end
        if not has_any then
            FSM.DW_CTRL_PENDING_SET[line_idx] = nil
        end
    else
        line_set[word_idx] = { line = line_idx, word = word_idx }
    end
    if not no_sync then
        dw_esc.sync_ctrl_pending_list()
        FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
        if FSM.DRUM_WINDOW ~= "OFF" then
            _helpers.dw_osd:update()
        elseif FSM.DRUM == "ON" then
            _helpers.drum_osd:update()
        end
    end
end

-- 14. dw_handle_double_click_target
local function dw_handle_double_click_target(subs, line_idx, word_idx)
    if not subs or #subs == 0 then
        return false
    end
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
        dw_esc.capture_neutral_marker()
        FSM.DW_CURSOR_LINE = line_idx
        FSM.DW_CURSOR_X = nil
        dw_esc.apply_post_transition_selection(word_idx)
        FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"

        if not FSM.BOOK_MODE then
            FSM.DW_VIEW_CENTER = line_idx
        end

        -- Explicitly ensure we don't open the full Drum Window (Mode W)
        -- when interacting in OSD mode (Mode C).
        if FSM.DRUM == "ON" and FSM.DRUM_WINDOW == "OFF" then
            _helpers.drum_osd:update()
        elseif FSM.DRUM_WINDOW ~= "OFF" then
            _helpers.dw_osd:update()
        end
        return true
    end
    return false
end

-- 15. cmd_dw_double_click
local function cmd_dw_double_click()
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return
    end

    local osd_x, osd_y = _helpers.dw_get_mouse_osd()
    local line_idx, word_idx = _helpers.kardenwort_hit_test_all(osd_x, osd_y)
    if not line_idx then
        return
    end

    dw_handle_double_click_target(subs, line_idx, word_idx)
end

-- 16. cmd_dw_scroll
local function cmd_dw_scroll(dir)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return
    end
    -- Bootstrap: If the viewport hasn't been explicitly set yet,
    -- anchor it to the current active index before applying the scroll delta.
    if FSM.DW_VIEW_CENTER == -1 then
        local time_pos = mp.get_property_number("time-pos") or 0
        FSM.DW_VIEW_CENTER = get_center_index(subs, time_pos)
        if FSM.DW_VIEW_CENTER == -1 then
            FSM.DW_VIEW_CENTER = 1
        end
    end
    FSM.DW_FOLLOW_PLAYER = false
    FSM.DW_VIEW_CENTER = math.max(1, math.min(#subs, FSM.DW_VIEW_CENTER + dir))
    -- Keep null-pointer source in sync with manual viewport scroll to avoid stale entry line
    -- on the next UP/DOWN/LEFT/RIGHT activation after Esc.
    if FSM.DW_CURSOR_WORD == -1 and FSM.DW_ANCHOR_LINE == -1 then
        FSM.DW_CURSOR_LINE = FSM.DW_VIEW_CENTER
    end
    _helpers.dw_sync_cursor_to_mouse()
end

-- 17. cmd_dw_wheel_scroll
local function cmd_dw_wheel_scroll(dir)
    local osd_x, osd_y = _helpers.dw_get_mouse_osd()
    local line_idx, _ = _helpers.kardenwort_hit_test_all(osd_x, osd_y)

    -- In Drum Window (DOCKED), ALWAYS scroll.
    -- In Drum Mode (OSD), also ALWAYS scroll to match DW field behavior
    -- (not only when hovering exact subtitle hit-zones).
    if FSM.DRUM_WINDOW ~= "OFF" or FSM.DRUM == "ON" or line_idx then
        cmd_dw_scroll(dir)
    end
end

-- 18. dw_anki_export_selection
-- Keep declaration name exact for structural tests
local function dw_anki_export_selection()
    local ok, err = pcall(function()
        local subs = Tracks.pri.subs
        if not subs or #subs == 0 then
            return
        end

        local al, aw = FSM.DW_ANCHOR_LINE, FSM.DW_ANCHOR_WORD
        local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD
        -- [20260528132406] No-selection fallback: resolve line from live time-pos at keypress moment
        -- to bypass DW_CURSOR_LINE staleness (tick-race, Book Mode drift).
        if al == -1 and cw == -1 then
            local live_pos = mp.get_property_number("time-pos")
            local live_idx = live_pos and get_center_index(subs, live_pos) or -1
            cl = (live_idx ~= -1) and live_idx
                or (FSM.DW_ACTIVE_LINE ~= -1 and FSM.DW_ACTIVE_LINE or cl)
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
                            if i == p1_l and t.logical_idx < p1_w - L_EPSILON then
                                in_range = false
                            end
                            if i == p2_l and t.logical_idx > p2_w + L_EPSILON then
                                in_range = false
                            end
                            if in_range then
                                table.insert(
                                    indices,
                                    string.format("%d:%g:%d", i - p1_l, t.logical_idx, pivot_idx)
                                )
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
            if pivot_pos == -1 then
                pivot_pos = char_offset / 2
            end
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
            if pivot_pos == -1 then
                pivot_pos = char_offset / 2
            end
            context_line = table.concat(ctx_parts, "\0")
            time_pos = subs[cl].start_time + 0.001
        end

        if term and term ~= "" then
            -- Clean context: remove ASS tags
            context_line = context_line:gsub("{[^}]+}", "")
            local term_words = build_word_list(term)
            local effective_limit = math.max(Options.anki_context_max_words, #term_words + 20)
            local extracted_context =
                extract_anki_context(context_line, term, effective_limit, pivot_pos, advanced_index)
            -- Use the multi-index generated above
            save_anki_tsv_row(term, extracted_context, time_pos, advanced_index)
            _helpers.show_osd("Anki Highlight Saved: " .. term)

            -- In-memory update was already performed by save_anki_tsv_row.
            -- Removing redundant full-file reload to prevent UI stuttering.
            dw_esc.reset_selection()
            if _helpers.dw_tooltip_osd then
                _helpers.dw_tooltip_osd:update()
            end
        end
    end)

    if not ok then
        _helpers.show_osd("Anki Export Error: " .. tostring(err), 5)
    end
end

-- 19. ctrl_commit_set
-- Keep declaration name exact for structural tests
local function ctrl_commit_set(line_idx, word_idx)
    Diagnostic.info(
        string.format("ctrl_commit_set(line=%s, word=%s)", tostring(line_idx), tostring(word_idx))
    )
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
    if #members == 0 then
        return
    end

    -- Requirement: Unified Paired Export
    local term = prepare_export_text(
        { type = "SET", members = members },
        { clean = true, restore_sentence = true }
    )

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
    if pivot_pos == -1 then
        pivot_pos = char_offset / 2
    end
    local context_line = table.concat(ctx_parts, "\0")

    -- Build advanced index string
    local indices = {}
    for i, m in ipairs(members) do
        table.insert(indices, string.format("%d:%g:%d", m.line - p1_l, m.word, i))
    end
    local advanced_index = table.concat(indices, ",")

    save_anki_tsv_row(
        term,
        extract_anki_context(
            context_line,
            term,
            Options.anki_context_max_words,
            pivot_pos,
            advanced_index
        ),
        subs[p1_l].start_time + 0.001,
        advanced_index
    )
    _helpers.show_osd("Anki Paired Saved: " .. term)

    dw_reset_selection()

    _helpers.dw_osd:update()
end

-- 20. cmd_dw_add_smart
local function cmd_dw_add_smart()
    if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then
        _helpers.show_osd("X")
        return
    end
    ctrl_commit_set(FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD)
end

-- 21. cmd_dw_toggle_pink
local function cmd_dw_toggle_pink(tbl, was_mouse)
    if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then
        _helpers.show_osd("X")
        return
    end
    -- Only trigger mouse buttons on release to avoid double-toggle
    if was_mouse and tbl and tbl.event ~= "up" then
        return
    end

    local line, word
    -- Canonical context check
    local is_mouse = (was_mouse == true)

    local p1_l, p1_w, p2_l, p2_w = get_dw_selection_bounds()

    if p1_l then
        -- Toggle the entire yellow range into the pink set
        local subs = Tracks.pri.subs
        if not subs then
            return
        end

        for i = p1_l, p2_l do
            local sub = subs[i]
            if sub then
                local s_w = (i == p1_l) and p1_w or -1
                local e_w = (i == p2_l) and p2_w or 999999
                local in_range = (i > p1_l)

                local tokens = get_sub_tokens(sub)
                if tokens then
                    for _, t in ipairs(tokens) do
                        if logical_cmp(t.logical_idx, s_w) then
                            in_range = true
                        end
                        if in_range then
                            if not t.text:match("^%s*$") then
                                ctrl_toggle_word(i, t.logical_idx, true)
                            end
                        end
                        if logical_cmp(t.logical_idx, e_w) then
                            in_range = false
                            break
                        end
                    end
                end
            end
        end
        dw_esc.sync_ctrl_pending_list()
        FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
        if FSM.DRUM_WINDOW ~= "OFF" then
            _helpers.dw_osd:update()
        end
        -- Clear yellow selection after it "turns pink"
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        -- Only clear drag-binding if we were actually interacting with the mouse
        if is_mouse then
            mp.remove_key_binding("dw-mouse-drag")
        end
        _helpers.drum_osd:update()
        if FSM.DRUM_WINDOW ~= "OFF" then
            _helpers.dw_osd:update()
        end
    else
        -- Fallback to single word toggle (standard behavior)
        if was_mouse then
            local osd_x, osd_y = _helpers.dw_get_mouse_osd()
            line, word = _helpers.kardenwort_hit_test_all(osd_x, osd_y)
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

-- 22. cmd_dw_line_move
local function cmd_dw_line_move(dir, shift, evt)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return
    end

    local snapshot = dw_create_nav_event_snapshot(evt)
    local ctx = dw_resolve_nav_intent_context(subs, snapshot)

    FSM.DW_FOLLOW_PLAYER = false

    -- Activation logic for NULL pointer
    if FSM.DW_CURSOR_WORD == -1 then
        -- Snap repeat during null activation to prevent immediate double-jump
        if snapshot.is_repeat then
            return
        end

        local line_idx = dw_esc.resolve_null_activation_line(ctx, dir, subs)

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
        FSM.DW_ANCHOR_WORD = (FSM.DW_CURSOR_WORD > 0) and FSM.DW_CURSOR_WORD
            or (start_word > 0 and start_word or 1)
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

-- 23. cmd_dw_word_move
local function cmd_dw_word_move(dir, shift, ctrl, evt)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return
    end

    local snapshot = dw_create_nav_event_snapshot(evt)
    local ctx = dw_resolve_nav_intent_context(subs, snapshot)

    FSM.DW_FOLLOW_PLAYER = false

    -- Activation logic for NULL pointer
    if FSM.DW_CURSOR_WORD == -1 then
        if snapshot.is_repeat then
            return
        end

        local line_idx = dw_esc.resolve_null_activation_line(ctx, dir, subs)

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
    if not raw_sub then
        return
    end

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
                FSM.DW_CURSOR_WORD = (dir > 0) and next_logical[1].logical_idx
                    or next_logical[#next_logical].logical_idx
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

-- 24. cmd_replay_sub
local function cmd_replay_sub()
    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then
        return
    end

    local is_paused = mp.get_property_bool("pause")

    -- Sticky Hold Workaround for Hardware Ghosting
    -- If 's' is pressed, the keyboard matrix might send a fake 'Space UP' event just before 's' DOWN.
    -- If Space was held, or released within the last 300ms, we assume they are still intending to hold it.
    local was_holding_space = (FSM.SPACEBAR == "HOLDING")
        or (
            FSM.SPACEBAR == "IDLE"
            and FSM.space_up_time
            and (mp.get_time() - FSM.space_up_time) < 0.3
        )

    if was_holding_space then
        FSM.SPACEBAR = "HOLDING" -- Force restore state
        FSM.GHOST_HOLD_EXPIRY = mp.get_time() + 2.0 -- 2 second safety window for desync recovery
    end

    -- Fixed Window Replay (Subtitle Independent)
    -- As per user request: "get rid of the boundaries of subtitles altogether and leave only the range of the track"
    local replay_start = math.max(0, time_pos - Options.replay_ms / 1000)
    local replay_end = time_pos
    local subs = Tracks.pri.subs
    local current_idx = -1
    local replay_start_idx = -1
    if subs and #subs > 0 then
        current_idx = get_center_index(subs, time_pos)
        replay_start_idx = get_center_index(subs, replay_start)
    end
    local is_cross_card_replay = (
        current_idx ~= -1
        and replay_start_idx ~= -1
        and current_idx ~= replay_start_idx
    )
    local sec_subs = Tracks.sec.subs
    local sec_replay_start_idx = (sec_subs and #sec_subs > 0)
            and get_center_index(sec_subs, replay_start)
        or -1

    if FSM.AUTOPAUSE == "OFF" then
        -- Autopause OFF: "Flashback" Replay (Finite Segment)
        -- No toggling: each press restarts the replay window
        FSM.LOOP_MODE = "ON"
        FSM.LOOP_START = replay_start
        FSM.LOOP_END = replay_end
        FSM.LOOP_ARMED = false
        _helpers.protect_internal_replay_seek()
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
        if is_paused then
            mp.set_property_bool("pause", false)
        end
        FSM.TIMESEEK_INHIBIT_UNTIL = nil
        FSM.REWIND_START_IDX = nil
        FSM.REWIND_TRANSIT_CROSS_CARD = false
        FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown
        local x_str = (Options.replay_count > 1) and (" x" .. Options.replay_count) or ""
        local template = Options.replay_msg_format
        local msg = template
            :gsub("%%m", tostring(Options.replay_ms))
            :gsub("%%s", tostring(Options.replay_ms / 1000))
            :gsub("%%c", tostring(Options.replay_count))
            :gsub("%%x", x_str)
        _helpers.show_osd(msg)
    else
        -- Autopause ON Mode: Immediate Replay (Fixed Segment)
        FSM.LOOP_MODE = "OFF"
        _helpers.protect_internal_replay_seek()
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
        if is_paused then
            mp.set_property_bool("pause", false)
        end
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
        local msg = template
            :gsub("%%m", tostring(Options.replay_ms))
            :gsub("%%s", tostring(Options.replay_ms / 1000))
            :gsub("%%c", tostring(Options.replay_count))
            :gsub("%%x", x_str)
        _helpers.show_osd(msg)
    end
end

-- 25. cmd_dw_seek_selected
local function cmd_dw_seek_selected()
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return
    end
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
            dw_esc.capture_neutral_marker()
            dw_esc.apply_post_transition_selection(FSM.DW_CURSOR_WORD)
            FSM.DW_CURSOR_X = nil
            FSM.DW_TOOLTIP_TARGET_MODE = "ACTIVE"

            if not FSM.BOOK_MODE then
                FSM.DW_VIEW_CENTER = FSM.DW_CURSOR_LINE
            end

            _helpers.show_osd("Seeking to line: " .. FSM.DW_CURSOR_LINE)
        end
    end
end

-- 26. cmd_dw_seek_delta
local function cmd_dw_seek_delta(dir)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return
    end

    local time_pos = mp.get_property_number("time-pos")
    if not time_pos then
        return
    end

    -- Intentional Focus Handover
    -- When manually seeking, we MUST ignore the padding boundaries of the current index
    -- to prevent "Magnetic Snapping" back to the previous line.
    FSM.IGNORE_NEXT_JUMP = true
    FSM.JUST_JERKED_TO = -1
    FSM.TIMESEEK_INHIBIT_UNTIL = nil
    FSM.REWIND_TRANSIT_CROSS_CARD = false
    FSM.MANUAL_NAV_COOLDOWN = mp.get_time() + Options.nav_cooldown -- Settle period for smart logic

    local current_idx = get_center_index(subs, time_pos)
    if current_idx == -1 and (not FSM.ACTIVE_IDX or FSM.ACTIVE_IDX == -1) then
        return
    end

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
    if wrapped_msg then
        _helpers.show_osd(wrapped_msg)
    end
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
                dw_esc.capture_neutral_marker()
                FSM.DW_ESC_NEUTRAL_ARMED = dw_esc.is_neutral_policy_enabled()
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

-- 27. get_clipboard_text_smart
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
    if cl == -1 then
        return nil, false
    end

    -- 1. Selection Priority (Pink Set > Yellow Range > Yellow Pointer)
    -- Explicit priority allows user to regulate behavior via Esc stages.

    -- Stage 1: Pink Set (Multi-word Selection via Ctrl+Click)
    if has_pink_set then
        return prepare_export_text({ type = "SET", members = FSM.DW_CTRL_PENDING_LIST }, {
            copy_mode = FSM.COPY_MODE,
            filter_russian = Options.copy_filter_russian,
        }),
            false
    end

    -- Stage 2 & 3: Yellow Selection (Range or Point)
    if has_yellow_range or has_yellow_point then
        local params = p1_l
                and { type = "RANGE", p1_l = p1_l, p1_w = p1_w, p2_l = p2_l, p2_w = p2_w }
            or { type = "POINT", line = cl, word = cw }

        return prepare_export_text(params, {
            copy_mode = FSM.COPY_MODE,
            filter_russian = Options.copy_filter_russian,
        }),
            false
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
        filter_russian = Options.copy_filter_russian,
    }),
        false
end

-- 28. cmd_dw_copy
local function cmd_dw_copy(mode)
    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return
    end

    local final_text, is_context = get_clipboard_text_smart()

    if final_text and final_text ~= "" then
        _helpers.set_clipboard(final_text, mode)
        local now = mp.get_time()
        if (now - (FSM.LAST_OSD_TIME or 0)) > Options.copy_osd_cooldown then
            local label = is_context and "Context" or "DW"
            _helpers.show_osd(build_copy_preview(label, final_text, 40))
            FSM.LAST_OSD_TIME = now
        end
    end
end

-- 29. cmd_dw_esc
local function cmd_dw_esc()
    if FSM.HELP_MODE then
        help_hud.cmd_toggle_help()
        return
    end
    -- Stage 1: Clear Pink Set (Purple highlights)
    if next(FSM.DW_CTRL_PENDING_SET) then
        FSM.DW_CTRL_PENDING_SET = {}
        FSM.DW_CTRL_PENDING_LIST = {}
        FSM.DW_CTRL_PENDING_VERSION = (FSM.DW_CTRL_PENDING_VERSION or 0) + 1
        if FSM.DRUM_WINDOW ~= "OFF" then
            _helpers.dw_osd:update()
        elseif FSM.DRUM == "ON" then
            _helpers.drum_osd:update()
        end
        return
    end

    -- Stage 2: Clear Yellow Range (multi-word selection)
    -- get_dw_selection_bounds returns nil if it's a single-word pointer
    if get_dw_selection_bounds() then
        FSM.DW_ANCHOR_LINE = -1
        FSM.DW_ANCHOR_WORD = -1
        if FSM.DRUM_WINDOW ~= "OFF" then
            _helpers.dw_osd:update()
        elseif FSM.DRUM == "ON" then
            _helpers.drum_osd:update()
        end
        return
    end

    -- Stage 3: Clear Yellow Pointer & Full Reset
    if FSM.DW_CURSOR_WORD ~= -1 then
        dw_reset_selection()
        return
    end

    -- Stage 4: Neutral no-selection Esc flow for manual mode.
    -- 1st Esc arms neutral marker; 2nd Esc restores follow explicitly.
    if dw_esc.is_neutral_policy_enabled() and FSM.DW_ESC_NEUTRAL_ARMED then
        FSM.DW_FOLLOW_PLAYER = true
        FSM.DW_ESC_NEUTRAL_ARMED = false
        if FSM.DW_CURSOR_LINE == -1 then
            local neutral_line = dw_esc.resolve_neutral_cursor_line()
            if neutral_line and neutral_line ~= -1 then
                FSM.DW_CURSOR_LINE = neutral_line
            end
        end
        if FSM.DRUM_WINDOW ~= "OFF" then
            _helpers.dw_osd:update()
        elseif FSM.DRUM == "ON" then
            _helpers.drum_osd:update()
        end
        return
    end
    if dw_esc.is_neutral_policy_enabled() and not FSM.DW_FOLLOW_PLAYER then
        dw_esc.capture_neutral_marker()
        local neutral_line = dw_esc.resolve_neutral_cursor_line()
        if neutral_line and neutral_line ~= -1 then
            FSM.DW_CURSOR_LINE = neutral_line
        end
        FSM.DW_ESC_NEUTRAL_ARMED = true
        if FSM.DRUM_WINDOW ~= "OFF" then
            _helpers.dw_osd:update()
        elseif FSM.DRUM == "ON" then
            _helpers.drum_osd:update()
        end
        return
    end

    -- Auto-follow mode: Esc with no active selection should still restore follow.
    if not dw_esc.is_neutral_policy_enabled() and not FSM.DW_FOLLOW_PLAYER then
        local time_pos = mp.get_property_number("time-pos") or 0
        local live_idx = get_center_index(Tracks.pri.subs, time_pos)
        if live_idx and live_idx ~= -1 then
            FSM.DW_ACTIVE_LINE = live_idx
            FSM.DW_CURSOR_LINE = live_idx
        end
        FSM.DW_FOLLOW_PLAYER = true
        if FSM.DRUM_WINDOW ~= "OFF" then
            _helpers.dw_osd:update()
        elseif FSM.DRUM == "ON" then
            _helpers.drum_osd:update()
        end
        return
    end
end

-- Export module interfaces
M.is_inside_dw_selection = is_inside_dw_selection
M.dw_anki_export_selection = dw_anki_export_selection
M.ctrl_discard_set = ctrl_discard_set
M.get_dw_selection_bounds = get_dw_selection_bounds
M.cmd_dw_esc = cmd_dw_esc
M.ctrl_toggle_word = ctrl_toggle_word
M.ctrl_commit_set = ctrl_commit_set
M.cmd_dw_add_smart = cmd_dw_add_smart
M.cmd_dw_toggle_pink = cmd_dw_toggle_pink
M.dw_handle_double_click_target = dw_handle_double_click_target
M.cmd_dw_double_click = cmd_dw_double_click
M.cmd_dw_scroll = cmd_dw_scroll
M.cmd_dw_wheel_scroll = cmd_dw_wheel_scroll
M.ensure_sub_layout = ensure_sub_layout
M.dw_get_word_visual_line = dw_get_word_visual_line
M.dw_closest_word_at_x = dw_closest_word_at_x
M.dw_pick_middle_word_idx = dw_pick_middle_word_idx
M.get_first_valid_word_idx = get_first_valid_word_idx
M.dw_compute_word_center_x = dw_compute_word_center_x
M.dw_ensure_visible = dw_ensure_visible
M.dw_create_nav_event_snapshot = dw_create_nav_event_snapshot
M.dw_resolve_nav_intent_context = dw_resolve_nav_intent_context
M.cmd_dw_line_move = cmd_dw_line_move
M.cmd_dw_word_move = cmd_dw_word_move
M.cmd_replay_sub = cmd_replay_sub
M.cmd_dw_seek_selected = cmd_dw_seek_selected
M.cmd_dw_seek_delta = cmd_dw_seek_delta
M.cmd_dw_copy = cmd_dw_copy
M.get_clipboard_text_smart = get_clipboard_text_smart

return M
