-- ===============================================================================
-- test_hooks.lua — Test instrumentation IPC surface for kardenwort
-- Dormant in production. Activated by IPC `script-message-to kardenwort ...`.
-- Loaded unconditionally at boot (preserves original behavior).
-- All function references are injected via M.init(refs) so no new globals.
-- ===============================================================================

local mp = require 'mp'
local utils = require 'mp.utils'

local M = {}

local FSM, Options, Tracks, Diagnostic
local refs

-- kardenwortProbe: snapshot of full FSM state for state-query IPC.
local kardenwortProbe = {}

function M.init(fsm, opts, tracks, diagnostic, r)
    FSM = fsm
    Options = opts
    Tracks = tracks
    Diagnostic = diagnostic
    refs = r or {}
end

function kardenwortProbe._snapshot()
    local safe_search_results = {}
    for _, r in ipairs(FSM.SEARCH_RESULTS or {}) do
        table.insert(safe_search_results, {
            idx = r.idx,
            text = r.text
        })
    end

    local tracks_summary = {
        pri = {
            id = Tracks.pri.id,
            is_ass = Tracks.pri.is_ass,
            path = Tracks.pri.path,
            count = #(Tracks.pri.subs or {})
        },
        sec = {
            id = Tracks.sec.id,
            is_ass = Tracks.sec.is_ass,
            path = Tracks.sec.path,
            count = #(Tracks.sec.subs or {})
        }
    }

    return {
        options            = Options,
        autopause          = FSM.AUTOPAUSE,
        drum_mode          = FSM.DRUM,
        drum_window        = FSM.DRUM_WINDOW,
        active_sub_index     = FSM.ACTIVE_IDX,
        sec_active_sub_index = FSM.SEC_ACTIVE_IDX,
        playback_state     = FSM.MEDIA_STATE,
        pri_sub_count      = #(Tracks.pri.subs or {}),
        sec_sub_count      = #(Tracks.sec.subs or {}),
        dw_cursor          = { line = FSM.DW_CURSOR_LINE, word = FSM.DW_CURSOR_WORD },
        dw_active_line     = FSM.DW_ACTIVE_LINE,
        dw_anchor          = { line = FSM.DW_ANCHOR_LINE, word = FSM.DW_ANCHOR_WORD },
        dw_selection_count = #(FSM.DW_CTRL_PENDING_LIST or {}),
        dw_view_center     = FSM.DW_VIEW_CENTER,
        dw_follow_player   = FSM.DW_FOLLOW_PLAYER,
        dw_block_top       = FSM.DW_BLOCK_TOP or 0,
        dw_total_height    = FSM.DW_TOTAL_HEIGHT or 0,
        dw_esc_neutral_armed = FSM.DW_ESC_NEUTRAL_ARMED,
        dw_neutral_cursor  = { line = FSM.DW_NEUTRAL_LINE, word = FSM.DW_NEUTRAL_WORD },
        dw_seeking_manually = FSM.DW_SEEKING_MANUALLY,
        immersion_mode     = FSM.IMMERSION_MODE,
        copy_mode          = FSM.COPY_MODE,
        loop_mode          = FSM.LOOP_MODE,
        book_mode          = FSM.BOOK_MODE,
        native_sub_vis     = FSM.native_sub_vis,
        native_sec_sub_vis = FSM.native_sec_sub_vis,
        sec_only_mode      = FSM.SEC_ONLY_MODE,
        native_sec_sub_pos = FSM.native_sec_sub_pos,
        replay_remaining      = FSM.REPLAY_REMAINING or 0,
        rewind_transit_active = FSM.TIMESEEK_INHIBIT_UNTIL ~= nil,
        rewind_transit_until  = FSM.TIMESEEK_INHIBIT_UNTIL or 0,
        rewind_transit_cross_card = FSM.REWIND_TRANSIT_CROSS_CARD == true,
        last_paused_sub_end   = FSM.last_paused_sub_end,
        karaoke_mode          = FSM.KARAOKE,
        search_mode           = FSM.SEARCH_MODE,
        search_query       = FSM.SEARCH_QUERY,
        search_results     = safe_search_results,
        dw_tooltip_mode    = FSM.DW_TOOLTIP_MODE,
        tracks             = tracks_summary,
        fsm_state          = FSM.MEDIA_STATE,
        test_data          = FSM.TEST_DATA or {},
        layout_version     = FSM.LAYOUT_VERSION or 0,
        tooltip_forced     = FSM.DW_TOOLTIP_FORCE,
        tooltip_cache_size = #(FSM.DW_TOOLTIP_SEC_SUBS or {}),
        dw_sticky_x        = FSM.DW_CURSOR_X,
        anki_db_mtime      = FSM.ANKI_DB_MTIME or 0,
        anki_db_size       = FSM.ANKI_DB_SIZE or 0,
        platform           = package.config:sub(1,1) == "\\" and "windows" or "unix"
    }
end

function M.register_all()
    local _probe_seq = 0

    mp.register_script_message("state-query", function()
        _probe_seq = _probe_seq + 1
        local snap = kardenwortProbe._snapshot()
        snap._seq = _probe_seq
        mp.set_property("user-data/kardenwort/state", utils.format_json(snap))
    end)

    mp.register_script_message("render-query", function(overlay_name)
        local map = {
            drum    = refs.drum_osd, -- drum    = drum_osd
            dw      = refs.dw_osd, -- dw      = dw_osd
            tooltip = refs.dw_tooltip_osd, -- tooltip = dw_tooltip_osd
            search  = refs.search_osd, -- search  = search_osd
            seek    = refs.seek_osd, -- seek    = seek_osd
        }
        local osd = map[overlay_name]
        local data = (osd and osd.data) or ""
        _probe_seq = _probe_seq + 1
        mp.set_property("user-data/kardenwort/render", _probe_seq .. "|" .. data)
    end)

    mp.register_script_message("immersion-mode-set", function(mode)
        if mode == "MOVIE" or mode == "PHRASE" then
            FSM.IMMERSION_MODE = mode
            refs.master_tick()
        end
    end)

    mp.register_script_message("autopause-set", function(state)
        if state == "ON" or state == "OFF" then
            FSM.AUTOPAUSE = state
        end
    end)

    mp.register_script_message("adjust-sec-sub-pos", function(val)
        refs.cmd_adjust_sec_sub_pos(tonumber(val))
    end)

    mp.register_script_message("native-sec-sub-pos-set", function(val)
        local n = tonumber(val)
        if n then
            FSM.native_sec_sub_pos = n
            mp.set_property_number("secondary-sub-pos", n)
        end
    end)

    mp.register_script_message("toggle-sub-vis", function()
        refs.cmd_toggle_sub_vis()
    end)

    mp.register_script_message("drum-window-toggle", function()
        refs.cmd_toggle_drum_window()
    end)

    mp.register_script_message("test-bind-seek", function()
        mp.add_forced_key_binding("KP0", "kardenwort-seek_time_forward", function() refs.cmd_seek_time(1) end, {repeatable = true})
        mp.add_forced_key_binding("KP1", "kardenwort-seek_time_backward", function() refs.cmd_seek_time(-1) end, {repeatable = true})
    end)

    mp.register_script_message("test-dw-word-move", function(dir, shift)
        Diagnostic.info("RECEIVED kardenwort-test-dw-word-move: " .. tostring(dir) .. " " .. tostring(shift))
        refs.cmd_dw_word_move(tonumber(dir), shift == "yes" or shift == "true")
    end)

    mp.register_script_message("test-ctrl-toggle-word", function(line_str, word_str)
        local line, word = tonumber(line_str), tonumber(word_str)
        if line and word then refs.ctrl_toggle_word(line, word, false) end
    end)

    mp.register_script_message("test-dw-esc", function()
        refs.cmd_dw_esc()
    end)

    mp.register_script_message("test-dw-tooltip-toggle", function()
        refs.cmd_dw_tooltip_toggle()
    end)

    mp.register_script_message("test-dw-line-move", function(dir_str, shift)
        local dir = tonumber(dir_str)
        if dir then refs.cmd_dw_line_move(dir, shift == "yes" or shift == "true") end
    end)

    mp.register_script_message("test-dw-scroll", function(dir_str)
        local dir = tonumber(dir_str)
        if dir then refs.cmd_dw_scroll(dir) end
    end)

    mp.register_script_message("test-replay", function()
        refs.cmd_replay_sub()
    end)

    mp.register_script_message("test-seek-time", function(dir_str)
        local dir = tonumber(dir_str)
        if dir then refs.cmd_seek_time(dir) end
    end)

    mp.register_script_message("test-set-cursor", function(line_str, word_str)
        local line, word = tonumber(line_str), tonumber(word_str)
        if line and word then
            FSM.DW_CURSOR_LINE = line
            FSM.DW_CURSOR_WORD = word
            FSM.DW_CURSOR_X = nil
        end
    end)

    mp.register_script_message("test-set-follow-player", function(state)
        FSM.DW_FOLLOW_PLAYER = (state == "ON" or state == "true")
    end)

    mp.register_script_message("test-seek-delta", function(dir_str)
        local dir = tonumber(dir_str)
        if dir then refs.cmd_dw_seek_delta(dir) end
    end)

    mp.register_script_message("seek_next", function() refs.cmd_seek_with_repeat(1, nil) end)
    mp.register_script_message("seek_prev", function() refs.cmd_seek_with_repeat(-1, nil) end)
    mp.register_script_message("test-cycle-sec-sid", function()
        refs.cmd_cycle_sec_sid()
    end)

    mp.register_script_message("sub-visibility-set", function(state)
        local val = (state == "ON")
        FSM.native_sub_vis = val
        FSM.native_sec_sub_vis = val
        FSM.SEC_ONLY_MODE = false
        refs.master_tick()
    end)

    mp.register_script_message("drum-mode-set", function(state)
        if state == "ON" or state == "OFF" then
            FSM.DRUM = state
            refs.master_tick()
        end
    end)

    mp.register_script_message("test-dw-export-pink", function()
        Diagnostic.info("RECEIVED kardenwort-test-dw-export-pink")
        refs.ctrl_commit_set(FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD)
    end)

    mp.register_script_message("test-dw-export-yellow", function()
        refs.dw_anki_export_selection()
    end)

    mp.register_script_message("test-prepare-export", function(type, p1_l, p1_w, p2_l, p2_w)
        local params
        if type == "RANGE" then
            params = { type = "RANGE", p1_l = tonumber(p1_l), p1_w = tonumber(p1_w), p2_l = tonumber(p2_l), p2_w = tonumber(p2_w) }
        elseif type == "SET" then
            params = { type = "SET", members = FSM.DW_CTRL_PENDING_LIST }
        else
            params = { type = "POINT", line = tonumber(p1_l), word = tonumber(p1_w) }
        end
        local term = refs.prepare_export_text(params, { clean = true, restore_sentence = true })
        mp.set_property("user-data/kardenwort/last_export", term)
    end)

    mp.register_script_message("test-dw-copy", function()
        refs.cmd_dw_copy()
    end)

    mp.register_script_message("test-search-input", function(char)
        if FSM.SEARCH_MODE then
            local q_table = refs.utf8_to_table(FSM.SEARCH_QUERY)
            table.insert(q_table, FSM.SEARCH_CURSOR + 1, char)
            FSM.SEARCH_QUERY = table.concat(q_table)
            FSM.SEARCH_CURSOR = FSM.SEARCH_CURSOR + 1
            refs.update_search_results()
            refs.render_search()
        end
    end)

    mp.register_script_message("test-get-tokens", function(text)
        local tokens = refs.build_word_list_internal(text, true)
        local snap = {}
        for i, t in ipairs(tokens) do
            table.insert(snap, { text = t.text, logical_idx = t.logical_idx, is_word = t.is_word })
        end
        FSM.TEST_DATA = FSM.TEST_DATA or {}
        FSM.TEST_DATA.test_tokens = snap
    end)

    mp.register_script_message("test-calc-highlight-stack", function(line_str, word_str, time_str)
        local line_idx = tonumber(line_str)
        local word_idx = tonumber(word_str)
        local time_pos = tonumber(time_str) or mp.get_property_number("time-pos", 0) or 0
        local res = { ok = false, reason = "invalid_args" }
        local subs = Tracks.pri.subs

        if subs and line_idx and word_idx and subs[line_idx] then
            local tokens = refs.get_sub_tokens(subs[line_idx])
            local token_idx = nil
            if tokens then
                for i, tok in ipairs(tokens) do
                    if tok.is_word and refs.logical_cmp(tok.logical_idx, word_idx) then
                        token_idx = i
                        break
                    end
                end
            end
            if token_idx then
                local orange_stack, purple_stack, has_phrase, matching_terms, purple_depth =
                    refs.calculate_highlight_stack(subs, line_idx, token_idx, time_pos)
                res = {
                    ok = true,
                    line = line_idx,
                    word = word_idx,
                    token_idx = token_idx,
                    time = time_pos,
                    orange_stack = orange_stack,
                    purple_stack = purple_stack,
                    has_phrase = has_phrase,
                    purple_depth = purple_depth,
                    term_count = #(matching_terms or {}),
                }
            else
                res = { ok = false, reason = "token_not_found", line = line_idx, word = word_idx }
            end
        end

        FSM.TEST_DATA = FSM.TEST_DATA or {}
        FSM.TEST_DATA.highlight_stack = res
        mp.set_property("user-data/kardenwort/highlight_stack", utils.format_json(res))
    end)

    mp.register_script_message("test-set-option", function(name, val)
        if val == "yes" or val == "true" then val = true
        elseif val == "no" or val == "false" then val = false
        elseif tonumber(val) then val = tonumber(val) end
        Options[name] = val
        if name == "book_mode" then FSM.BOOK_MODE = val end
        refs.flush_rendering_caches()
    end)

    mp.register_script_message("test-load-anki-tsv", function()
        refs.load_anki_tsv(true, true)
    end)

    mp.register_script_message("test-dw-toggle", function()
        refs.cmd_toggle_drum_window()
    end)

    mp.register_script_message("test-dw-tooltip-pin", function(arg1)
        local tbl = { event = "down" }
        if arg1 and arg1:sub(1,1) == "{" then
            local ok, parsed = pcall(utils.parse_json, arg1)
            if ok and parsed then tbl = parsed end
        end
        refs.cmd_dw_tooltip_pin(tbl)
    end)

    mp.register_script_message("test-dw-tooltip-pin-at", function(x_str, y_str, arg3)
        local x, y = tonumber(x_str), tonumber(y_str)
        if not x or not y then return end
        local tbl = { event = "down" }
        if arg3 and arg3:sub(1,1) == "{" then
            local ok, parsed = pcall(utils.parse_json, arg3)
            if ok and parsed then tbl = parsed end
        end
        local dw_mode = (FSM.DRUM_WINDOW ~= "OFF")
        local drum_mode = refs.is_osd_tooltip_mode_eligible()
        if not dw_mode and not drum_mode then return end
        if tbl.event == "down" then
            FSM.DW_TOOLTIP_FORCE = false
            FSM.DW_TOOLTIP_HOLDING = true
            local subs = Tracks.pri.subs
            if not subs or #subs == 0 then return end
            local line_idx = refs.resolve_tooltip_target_line(subs, x, y, dw_mode)
            if line_idx then
                FSM.DW_TOOLTIP_LOCKED_LINE = -1
                FSM.DW_TOOLTIP_LINE = line_idx
                local py = refs.get_tooltip_line_y(line_idx, y)
                if py then py = math.floor(py + 0.5) end
                local ass = refs.draw_dw_tooltip(subs, line_idx, py)
                refs.apply_tooltip_ass(ass)
            end
        elseif tbl.event == "up" then
            FSM.DW_TOOLTIP_HOLDING = false
        end
    end)

    mp.register_script_message("test-dw-key", function(key)
        local shift = key:find("Shift%+") ~= nil
        local ctrl = key:find("Ctrl%+") ~= nil
        local base = key:gsub("Shift%+", ""):gsub("Ctrl%+", "")

        if base == "DOWN" then refs.cmd_dw_line_move(1, shift)
        elseif base == "UP" then refs.cmd_dw_line_move(-1, shift)
        elseif base == "LEFT" then refs.cmd_dw_word_move(-1, shift, ctrl)
        elseif base == "RIGHT" then refs.cmd_dw_word_move(1, shift, ctrl)
        elseif key == "e" then
            FSM.DW_TOOLTIP_FORCE = not FSM.DW_TOOLTIP_FORCE
            if FSM.DW_TOOLTIP_FORCE then FSM.DW_TOOLTIP_TARGET_MODE = "CURSOR" end
        elseif key == "r" then
            refs.cmd_dw_toggle_pink()
        elseif key == "o" then
            refs.cmd_open_record_file()
        end
    end)

    mp.register_script_message("test-dw-double-click", function(line_str)
        local ok, err = xpcall(function()
            local line = tonumber(line_str)
            if line and Tracks and Tracks.pri and Tracks.pri.subs then
                if refs.dw_handle_double_click_target(Tracks.pri.subs, line, FSM.DW_CURSOR_WORD) then
                    refs.master_tick()
                    refs.flush_rendering_caches()
                end
            end
        end, debug.traceback)
        if not ok then Diagnostic.error("kardenwort-test-dw-double-click error: " .. tostring(err)) end
    end)

    mp.register_script_message("test-get-sub-text", function(track_name, index_str)
        local idx = tonumber(index_str) or 1
        local subs = (track_name == "sec") and Tracks.sec.subs or Tracks.pri.subs
        local sub = subs and subs[idx]
        FSM.TEST_DATA = FSM.TEST_DATA or {}
        FSM.TEST_DATA.test_sub_text = sub and sub.text or ""
    end)

    mp.register_script_message("test-truncate", function(text, max_chars_str)
        local max_chars = tonumber(max_chars_str) or 120
        local truncated = refs.utf8_truncate(text or "", max_chars)
        FSM.TEST_DATA = FSM.TEST_DATA or {}
        FSM.TEST_DATA.test_truncated_str = truncated
    end)

    mp.register_script_message("test-build-copy-preview", function(label, text, max_chars_str)
        local max_chars = tonumber(max_chars_str) or 40
        FSM.TEST_DATA = FSM.TEST_DATA or {}
        FSM.TEST_DATA.test_copy_preview = refs.build_copy_preview(label or "DW", text or "", max_chars)
    end)

    mp.register_script_message("test-validate-term", function(term)
        local clean = term:gsub("{.-}", ""):match("^%s*(.-)%s*$")
        local valid = (clean and #clean > 0)
        FSM.TEST_DATA = FSM.TEST_DATA or {}
        FSM.TEST_DATA.test_term_valid = valid
    end)

    mp.register_script_message("test-search-mode-set", function(state)
        FSM.SEARCH_MODE = (state == "ON" or state == "true")
        if FSM.SEARCH_MODE then
            FSM.SEARCH_QUERY = ""
            FSM.SEARCH_CURSOR = 0
            refs.render_search()
        end
    end)

    mp.register_script_message("test-hit-test", function(x_str, y_str)
        local x, y = tonumber(x_str), tonumber(y_str)
        local l, w, p = refs.drum_osd_hit_test(x, y)
        FSM.TEST_DATA = FSM.TEST_DATA or {}
        FSM.TEST_DATA.hit_test_res = { line = l, word = w, is_pri = p }
    end)

    mp.register_script_message("test-query-tooltip-state", function()
        local res = {
            data = refs.dw_tooltip_osd.data,
            line = FSM.DW_TOOLTIP_LINE,
            holding = FSM.DW_TOOLTIP_HOLDING,
            force = FSM.DW_TOOLTIP_FORCE
        }
        mp.set_property("user-data/test-tooltip-state", utils.format_json(res))
    end)

    mp.register_script_message("test-query-tooltip-style-contract", function()
        local result = {}
        for _, mode in ipairs({"dw", "dm", "srt"}) do
            local ctx = refs.build_tooltip_style_context(mode)
            result[mode] = {
                parent_mode = ctx.parent_mode,
                policy = ctx.policy,
                is_bgbox = ctx.is_bgbox,
                needs_override = ctx.needs_override,
                neutralize_inband = ctx.neutralize_inband,
                bg_alpha = ctx.bg_alpha,
                card_alpha = ctx.card_alpha,
                card_ass = refs.format_tooltip_card_event(ctx, 10, 20, 100, 50, ctx.card_alpha),
                text_ass = refs.format_tooltip_text_event(ctx, 160, 40, "sample"),
            }
        end
        mp.set_property("user-data/test-tooltip-style-contract", utils.format_json(result))
    end)

    mp.register_script_message("test-query-hit-zones", function()
        FSM.TEST_DATA = FSM.TEST_DATA or {}
        FSM.TEST_DATA.drum_hit_zones = FSM.DRUM_HIT_ZONES
    end)

    mp.register_script_message("test-fuzzy-match", function(query, target)
        local q = query:lower():gsub("%s+", "")
        local t = target:lower()
        local q_idx = 1
        for i = 1, #t do
            if t:sub(i, i) == q:sub(q_idx, q_idx) then
                q_idx = q_idx + 1
                if q_idx > #q then break end
            end
        end
        FSM.TEST_DATA = FSM.TEST_DATA or {}
        FSM.TEST_DATA.test_fuzzy_match_result = (q_idx > #q)
    end)

    mp.register_script_message("test-expand-ru-keys", function(key_str)
        local results = refs.expand_ru_keys(key_str, "test-expand")
        mp.set_property("user-data/kardenwort/last_export", utils.format_json(results))
    end)

    -- Test instrumentation for missed functional coverage (ZID: 20260512130623)
    mp.register_script_message("test-set-search-query", function(query)
        if Tracks.pri.path and (not Tracks.pri.subs or #Tracks.pri.subs == 0) then
            Tracks.pri.subs = refs.load_sub(Tracks.pri.path, Tracks.pri.is_ass)
        end
        FSM.SEARCH_QUERY = query or ""
        FSM.SEARCH_CURSOR = #refs.utf8_to_table(FSM.SEARCH_QUERY)
        FSM.SEARCH_ANCHOR = -1
        refs.update_search_results()
        refs.render_search()
    end)

    mp.register_script_message("test-search-delete-word", function()
        local before = FSM.SEARCH_QUERY or ""
        if before == "" then return end
        local trimmed = before:gsub("%s*%S+$", "")
        if trimmed ~= "" and not trimmed:match("%s$") then
            trimmed = trimmed .. " "
        end
        FSM.SEARCH_QUERY = trimmed
        FSM.SEARCH_CURSOR = #refs.utf8_to_table(FSM.SEARCH_QUERY)
        FSM.SEARCH_ANCHOR = -1
    end)

    mp.register_script_message("test-export-selection", function()
        refs.sync_ctrl_pending_list()
        local members = FSM.DW_CTRL_PENDING_LIST or {}
        if #members > 0 then
            local first = members[1]
            refs.ctrl_commit_set(first.line, first.word)
            return
        end
        refs.dw_anki_export_selection()
    end)

    mp.register_script_message("test-normalize-key-display", function(key)
        local normalized = refs.normalize_key_display(key)
        mp.set_property("user-data/kardenwort/test_normalization", normalized)
    end)

    mp.register_script_message("test-help-toggle", function()
        local ok, err = pcall(refs.cmd_toggle_help)
        mp.set_property_native("user-data/kardenwort/test_help_toggle_ok", ok and "1" or "0")
        mp.set_property_native("user-data/kardenwort/test_help_toggle_error", ok and "" or tostring(err))
        mp.set_property_native("user-data/kardenwort/test_help_mode", FSM.HELP_MODE and "ON" or "OFF")
    end)

    mp.register_script_message("test-help-close-esc", function()
        if not FSM.HELP_MODE then
            local ok_open = pcall(refs.cmd_toggle_help)
            if not ok_open then
                mp.set_property_native("user-data/kardenwort/test_help_esc_ok", "0")
                mp.set_property_native("user-data/kardenwort/test_help_esc_error", "failed to open help before ESC test")
                mp.set_property_native("user-data/kardenwort/test_help_mode", FSM.HELP_MODE and "ON" or "OFF")
                return
            end
        end
        local ok, err = pcall(refs.cmd_dw_esc)
        mp.set_property_native("user-data/kardenwort/test_help_esc_ok", ok and "1" or "0")
        mp.set_property_native("user-data/kardenwort/test_help_esc_error", ok and "" or tostring(err))
        mp.set_property_native("user-data/kardenwort/test_help_mode", FSM.HELP_MODE and "ON" or "OFF")
    end)
end

return M