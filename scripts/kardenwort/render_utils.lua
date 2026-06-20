-- ============================================================================
-- render_utils.lua — Shared ASS-rendering helpers for kardenwort
-- Contains the rendering helper layer used by all four render modes
-- (drum/srt/dw/tooltip): measurement, layout, highlight, formatting.
-- Reads FSM/Options/Diagnostic at call time via injected references.
-- Requires text_utils and subtitle_parser for pure helpers.
-- is_inside_dw_selection stays in main.lua (DW nav) — injected via helpers.
-- ============================================================================

local mp = require("mp")
local text_utils = require("text_utils")
local subtitle_parser = require("subtitle_parser")

local M = {}

local FSM, Options, Diagnostic
local _helpers

function M.init(fsm, opts, diagnostic, helpers)
    assert(fsm, "FATAL: fsm dependency missing")
    assert(opts, "FATAL: opts dependency missing")
    assert(diagnostic, "FATAL: diagnostic dependency missing")
    FSM = fsm
    Options = opts
    Diagnostic = diagnostic
    _helpers = setmetatable(helpers or {}, {
        __index = function(t, k)
            error("FATAL: Missing injected helper function: " .. tostring(k), 2)
        end,
    })
end

local function is_inside_dw_selection(l, w)
    return _helpers.is_inside_dw_selection(l, w)
end

-- --- compose_term_smart (pure, no singleton access) -----------------------

local function compose_term_smart(words)
    if not words or #words == 0 then
        return ""
    end
    local res = ""
    for idx, w in ipairs(words) do
        res = res .. w
        local next_w = words[idx + 1]

        if next_w then
            local no_space_before = next_w:match("^[%.,!?;:…»”%)%]%}]$")
                or next_w:match("^[/-]$")
                or next_w:match("^\226\128\147$")
                or next_w:match("^\226\128\148$")
                or next_w:match("^[\"']$")

            local no_space_after = w:match("^[/-]$")
                or w:match("^\226\128\147$")
                or w:match("^\226\128\148$")
                or w:match("^[«“%(%[%{]$")
                or w:match("^[\"']$")

            if not no_space_before and not no_space_after then
                res = res .. " "
            end
        end
    end

    if #words == 1 then
        local outer_bal = (res:match("^%b[]$") or res:match("^%b()$") or res:match("^%b{}$"))
        if outer_bal then
            res = res:sub(2, -2)
        else
            res = res:gsub("[%.,!?;:%s]+$", ""):gsub("^[%s]+", "")
        end
    end

    return res
end

-- --- calculate_highlight_stack --------------------------------------------

local function calculate_highlight_stack(subs, sub_idx, token_idx, time_pos)
    if not next(FSM.ANKI_HIGHLIGHTS) or not subs or not subs[sub_idx] then
        return 0, 0, false, {}, 0
    end

    local tokens = text_utils.get_sub_tokens(subs[sub_idx])
    if not tokens then
        return 0, 0, 0, false
    end

    local target_token = tokens[token_idx]
    if not target_token or not target_token.is_word then
        return 0, 0, false, {}, 0
    end

    local target_l_idx = target_token.logical_idx
    local target_lower_full = target_token.lower_clean
    if not target_lower_full or target_lower_full == "" then
        return 0, 0, false, {}, 0
    end

    local target_subsets = { [target_lower_full] = true }
    for sw in target_token.text:gmatch("[^%s/-\226\128\147\226\128\148]+") do
        local csw = text_utils.utf8_to_lower(sw:gsub("[%p%s]", ""))
        if csw ~= "" then
            target_subsets[csw] = true
        end
    end

    local function get_relative_word_text(rel_logical_offset)
        local curr_s_idx = sub_idx
        local target_logical_idx = target_l_idx + rel_logical_offset

        local safety = 0
        local safety_limit = Options.anki_split_search_window or 20
        while safety < safety_limit do
            safety = safety + 1
            local c_tokens = text_utils.get_sub_tokens(subs[curr_s_idx])
            if not c_tokens then
                return nil
            end

            for _, t in ipairs(c_tokens) do
                if text_utils.logical_cmp(t.logical_idx, target_logical_idx) then
                    return t.text
                end
            end

            local wc = subs[curr_s_idx].word_count or 0
            if target_logical_idx > wc then
                target_logical_idx = target_logical_idx - wc
                curr_s_idx = curr_s_idx + 1
                if
                    not subs[curr_s_idx]
                    or not subs[curr_s_idx - 1]
                    or (
                        subs[curr_s_idx].start_time - subs[curr_s_idx - 1].end_time
                        > (Options.anki_split_gap_limit or 10.0)
                    )
                then
                    return nil
                end
            elseif target_logical_idx < 1 then
                curr_s_idx = curr_s_idx - 1
                if
                    not subs[curr_s_idx]
                    or not subs[curr_s_idx + 1]
                    or (
                        subs[curr_s_idx + 1].start_time - subs[curr_s_idx].end_time
                        > (Options.anki_split_gap_limit or 10.0)
                    )
                then
                    return nil
                end
                text_utils.get_sub_tokens(subs[curr_s_idx])
                target_logical_idx = target_logical_idx + (subs[curr_s_idx].word_count or 0)
            else
                return nil
            end
        end
        return nil
    end

    local exact_pivot_slot_cache = {}
    local function has_exact_pivot_slot(expected_sub_idx, pivot_l_idx, expected_clean_word)
        local key = tostring(expected_sub_idx)
            .. "|"
            .. tostring(pivot_l_idx)
            .. "|"
            .. tostring(expected_clean_word or "")
        if exact_pivot_slot_cache[key] ~= nil then
            return exact_pivot_slot_cache[key]
        end
        local expected_sub = subs[expected_sub_idx]
        if not expected_sub then
            exact_pivot_slot_cache[key] = false
            return false
        end
        local expected_tokens = text_utils.get_sub_tokens(expected_sub)
        if not expected_tokens then
            exact_pivot_slot_cache[key] = false
            return false
        end
        for _, tok in ipairs(expected_tokens) do
            if tok.is_word and text_utils.logical_cmp(tok.logical_idx, pivot_l_idx) then
                local tok_clean = tok.lower_clean
                    or text_utils.utf8_to_lower(tok.text:gsub("[%p%s]", ""))
                if expected_clean_word and expected_clean_word ~= "" then
                    local match = (tok_clean == expected_clean_word)
                    exact_pivot_slot_cache[key] = match
                    return match
                end
                exact_pivot_slot_cache[key] = true
                return true
            end
        end
        exact_pivot_slot_cache[key] = false
        return false
    end

    local function pivot_line_match(
        actual_sub_idx,
        expected_sub_idx,
        pivot_l_idx,
        expected_clean_word
    )
        if actual_sub_idx == expected_sub_idx then
            return true
        end
        if math.abs(actual_sub_idx - expected_sub_idx) ~= 1 then
            return false
        end
        if has_exact_pivot_slot(expected_sub_idx, pivot_l_idx, expected_clean_word) then
            return false
        end
        return true
    end

    local orange_stack = 0
    local purple_stack = 0
    local purple_depth = 0
    local has_phrase = false
    local matched_terms = {}
    local matching_source_terms = {}

    local candidates
    if
        not Options.anki_global_highlight
        and FSM.ANKI_HIGHLIGHTS_SORTED
        and #FSM.ANKI_HIGHLIGHTS_SORTED > 0
    then
        local sub_start = subs[sub_idx].start_time
        local sub_end = subs[sub_idx].end_time
        local max_window = Options.anki_local_fuzzy_window
            + (Options.anki_split_search_window or 15)
        local t_lo = sub_start - max_window
        local t_hi = sub_end + max_window
        local sorted = FSM.ANKI_HIGHLIGHTS_SORTED
        local lo, hi = 1, #sorted
        local first = #sorted + 1
        while lo <= hi do
            local mid = math.floor((lo + hi) / 2)
            if sorted[mid].time >= t_lo then
                first = mid
                hi = mid - 1
            else
                lo = mid + 1
            end
        end
        candidates = {}
        for k = first, #sorted do
            if sorted[k].time > t_hi then
                break
            end
            table.insert(candidates, FSM.ANKI_HIGHLIGHTS[sorted[k].idx])
        end
    else
        candidates = FSM.ANKI_HIGHLIGHTS
    end

    for _, data in ipairs(candidates) do
        local term_key = data.term
        local entry_key = data.__entry_key or term_key
        if not matched_terms[entry_key] then
            local match_found = false
            local term_is_split = false
            local term_is_local_split = false
            local is_in_footprint = false

            if not data.__term_clean then
                data.__is_elliptical = term_key:find("...", 1, true) ~= nil
                local term_tokens =
                    text_utils.build_word_list_internal(text_utils.utf8_to_lower(term_key), false)
                data.__term_clean = {}
                for _, t in ipairs(term_tokens) do
                    if t.is_word then
                        table.insert(
                            data.__term_clean,
                            text_utils.utf8_to_lower(t.text:gsub("[%p%s]", ""))
                        )
                    end
                end
                local cleaned_ctx = data.context:gsub("{{c%d+::(.-)}}", "%1"):gsub("{[^}]+}", "")
                data.__ctx_lower = text_utils.utf8_to_lower(cleaned_ctx)

                data.__ctx_words = {}
                local ctx_tokens = text_utils.build_word_list_internal(data.__ctx_lower, false)
                for _, t in ipairs(ctx_tokens) do
                    if t.is_word then
                        data.__ctx_words[text_utils.utf8_to_lower(t.text:gsub("[%p%s]", ""))] = true
                    end
                end

                if data.index and not data.__pivots then
                    data.__pivots = {}
                    for part in (tostring(data.index) .. ","):gmatch("([^,]*),") do
                        local l_off, p_idx, t_pos = part:match("^([%-+]?%d+):(%d+%.?%d*):(%d+)$")
                        if l_off then
                            table.insert(data.__pivots, {
                                l_off = tonumber(l_off),
                                p_idx = tonumber(p_idx),
                                t_pos = tonumber(t_pos),
                            })
                        else
                            local single = tonumber(part)
                            if single then
                                table.insert(
                                    data.__pivots,
                                    { l_off = 0, p_idx = single, t_pos = 1 }
                                )
                            end
                        end
                    end
                end
            end
            local term_clean = data.__term_clean

            local window = Options.anki_local_fuzzy_window
            if #term_clean > 10 then
                window = window + ((#term_clean - 10) * 0.5)
            end

            local sub_start = subs[sub_idx].start_time
            local sub_end = subs[sub_idx].end_time

            local in_window = false
            if
                Options.anki_global_highlight
                or (data.time >= sub_start - window and data.time <= sub_end + window)
            then
                in_window = true
            elseif #term_clean > 1 then
                local scan_padding = Options.anki_split_search_window or 15
                local min_scan = math.max(1, sub_idx - scan_padding)
                local max_scan = math.min(#subs, sub_idx + scan_padding)
                if
                    data.time >= (subs[min_scan].start_time - window)
                    and data.time <= (subs[max_scan].end_time + window)
                then
                    in_window = true
                end
            end

            local t_center = data.__cached_anchor_sub
            if not t_center or data.__cached_time ~= data.time then
                t_center = subtitle_parser.get_center_index_static(subs, data.time)
                data.__cached_anchor_sub = t_center
                data.__cached_time = data.time
            end

            local in_span = false
            if t_center ~= -1 and data.__min_l and data.__max_l then
                local s_idx = t_center + data.__min_l
                local e_idx = t_center + data.__max_l
                if sub_idx >= s_idx and sub_idx <= e_idx then
                    in_span = true
                end
            end

            if Options.anki_global_highlight or in_span or in_window then
                is_in_footprint = false
                if t_center ~= -1 and data.__min_l then
                    local t_start = (t_center + data.__min_l) * 1000 + data.__min_w
                    local t_end = (t_center + data.__max_l) * 1000 + data.__max_w
                    local t_total = sub_idx * 1000 + target_l_idx
                    if t_total >= t_start and t_total <= t_end then
                        is_in_footprint = true
                    end
                end

                local target_offsets = {}
                for term_offset, tw_clean in ipairs(term_clean) do
                    if target_subsets[tw_clean] then
                        table.insert(target_offsets, term_offset)
                    end
                end

                if #target_offsets > 0 then
                    local any_sequence = false
                    for _, term_offset in ipairs(target_offsets) do
                        local sequence_match = true

                        if data.__is_elliptical then
                            sequence_match = false
                        elseif #term_clean > 1 then
                            for k = 1, #term_clean do
                                if k ~= term_offset then
                                    local rw_text = get_relative_word_text(k - term_offset)
                                    if
                                        not rw_text
                                        or term_clean[k]
                                            ~= text_utils.utf8_to_lower(rw_text:gsub("[%p%s]", ""))
                                    then
                                        sequence_match = false
                                        break
                                    end
                                end
                            end
                        end

                        local context_satisfied = false

                        if Options.anki_global_highlight then
                            local needs_strict = Options.anki_context_strict and (#term_clean > 1)
                            if needs_strict then
                                local match_count = 0
                                local scan_pad = Options.anki_neighbor_window or 5
                                for s_off = -scan_pad, scan_pad do
                                    local scan_sub = subs[sub_idx + s_off]
                                    if scan_sub then
                                        local s_tokens = text_utils.get_sub_tokens(scan_sub)
                                        if s_tokens then
                                            for _, t in ipairs(s_tokens) do
                                                if t.is_word then
                                                    local cw = text_utils.utf8_to_lower(
                                                        t.text:gsub("[%p%s]", "")
                                                    )
                                                    if #cw >= 2 and data.__ctx_words[cw] then
                                                        local is_term = false
                                                        for _, tw in ipairs(term_clean) do
                                                            if tw == cw then
                                                                is_term = true
                                                                break
                                                            end
                                                        end
                                                        if not is_term then
                                                            match_count = match_count + 1
                                                            break
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                        if match_count >= 1 then
                                            break
                                        end
                                    end
                                end
                                context_satisfied = (match_count >= 1)
                            else
                                context_satisfied = true
                            end
                        else
                            if data.__pivots and #data.__pivots > 0 then
                                local origin_l =
                                    subtitle_parser.get_center_index_static(subs, data.time)
                                if origin_l ~= -1 then
                                    local g = data.__pivots[term_offset]
                                    if g then
                                        local expected_sub_idx = origin_l + g.l_off
                                        local expected_word = term_clean[term_offset]
                                        local line_match = pivot_line_match(
                                            sub_idx,
                                            expected_sub_idx,
                                            g.p_idx,
                                            expected_word
                                        )
                                        if line_match and target_l_idx == g.p_idx then
                                            context_satisfied = true
                                        end
                                    end
                                end
                            else
                                context_satisfied = true
                            end
                        end

                        if sequence_match and context_satisfied then
                            any_sequence = true
                            break
                        end
                    end

                    if any_sequence then
                        match_found = true
                        if #term_clean > 1 then
                            has_phrase = true
                        end
                    end

                    if not match_found and #term_clean > 1 then
                        local origin_sub_idx = Options.anki_global_highlight and sub_idx
                            or subtitle_parser.get_center_index_static(subs, data.time)
                        if not subs[sub_idx].__split_valid_indices then
                            subs[sub_idx].__split_valid_indices = {}
                        end
                        local valid_set = subs[sub_idx].__split_valid_indices[entry_key]

                        if valid_set == nil then
                            valid_set = false
                            local ctx_list = {}
                            local s_start = math.max(
                                1,
                                math.min(sub_idx, origin_sub_idx) - Options.anki_split_search_window
                            )
                            local s_end = math.min(
                                #subs,
                                math.max(sub_idx, origin_sub_idx) + Options.anki_split_search_window
                            )

                            for scan_i = s_start, s_end do
                                local scan_tokens = text_utils.get_sub_tokens(subs[scan_i])
                                if scan_tokens then
                                    local gap = math.abs(subs[scan_i].start_time - data.time)
                                    if
                                        Options.anki_global_highlight
                                        or gap < Options.anki_split_gap_limit
                                    then
                                        for t_i, t in ipairs(scan_tokens) do
                                            if t.is_word then
                                                local cw = text_utils.utf8_to_lower(
                                                    t.text:gsub("[%p%s]", "")
                                                )
                                                if cw ~= "" then
                                                    table.insert(ctx_list, {
                                                        cw = cw,
                                                        s_i = scan_i,
                                                        t_i = t_i,
                                                        l_i = t.logical_idx,
                                                        start = subs[scan_i].start_time,
                                                    })
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            local occs = {}
                            local all_present = true
                            for i_c, tc in ipairs(term_clean) do
                                occs[i_c] = {}
                                for c_idx, cw_obj in ipairs(ctx_list) do
                                    if cw_obj.cw == tc then
                                        table.insert(occs[i_c], c_idx)
                                    end
                                end
                                if #occs[i_c] == 0 then
                                    all_present = false
                                    break
                                end
                            end

                            if all_present then
                                local best_tuple = nil
                                local min_span = 999999
                                local best_unanchored_tuple = nil
                                local min_unanchored_span = 999999

                                local function search(term_idx, current_tuple)
                                    if term_idx > #term_clean then
                                        local valid_timing = true
                                        local has_anchor = not data.index
                                            or (data.index == -1)
                                            or (origin_sub_idx == -1)
                                            or Options.anki_global_highlight
                                        for m_idx = 1, #current_tuple do
                                            local m = ctx_list[current_tuple[m_idx]]
                                            if m_idx > 1 then
                                                local prev_m = ctx_list[current_tuple[m_idx - 1]]
                                                if
                                                    math.abs(m.start - prev_m.start)
                                                    > Options.anki_split_gap_limit
                                                then
                                                    valid_timing = false
                                                    break
                                                end
                                            end
                                            if data.__pivots and #data.__pivots > 0 then
                                                local all_pivots_matched = true
                                                for _, g in ipairs(data.__pivots) do
                                                    local m = ctx_list[current_tuple[g.t_pos]]
                                                    local expected_sub_idx = origin_sub_idx
                                                        + g.l_off
                                                    local expected_word = term_clean[g.t_pos]
                                                    local line_match = m
                                                        and pivot_line_match(
                                                            m.s_i,
                                                            expected_sub_idx,
                                                            g.p_idx,
                                                            expected_word
                                                        )
                                                    if not (line_match and m.l_i == g.p_idx) then
                                                        all_pivots_matched = false
                                                        break
                                                    end
                                                end
                                                if all_pivots_matched then
                                                    has_anchor = true
                                                end
                                            end
                                        end

                                        if valid_timing then
                                            local span = current_tuple[#current_tuple]
                                                - current_tuple[1]
                                            if has_anchor then
                                                if span < min_span then
                                                    min_span = span
                                                    best_tuple = {}
                                                    for k, v in ipairs(current_tuple) do
                                                        best_tuple[k] = v
                                                    end
                                                end
                                            else
                                                if span < min_unanchored_span then
                                                    min_unanchored_span = span
                                                    best_unanchored_tuple = {}
                                                    for k, v in ipairs(current_tuple) do
                                                        best_unanchored_tuple[k] = v
                                                    end
                                                end
                                            end
                                        end
                                        return
                                    end
                                    local prev_idx = (term_idx == 1) and 0
                                        or current_tuple[term_idx - 1]
                                    for _, c_idx in ipairs(occs[term_idx]) do
                                        if c_idx > prev_idx then
                                            current_tuple[term_idx] = c_idx
                                            search(term_idx + 1, current_tuple)
                                        end
                                    end
                                end
                                search(1, {})

                                if not best_tuple and best_unanchored_tuple then
                                    if
                                        Options.anki_global_highlight
                                        or (origin_sub_idx ~= -1)
                                        or not (data.__pivots and #data.__pivots > 0)
                                    then
                                        best_tuple = best_unanchored_tuple
                                    end
                                end

                                if best_tuple then
                                    local is_all_local = true
                                    for _, c_idx in ipairs(best_tuple) do
                                        if ctx_list[c_idx].s_i ~= sub_idx then
                                            is_all_local = false
                                            break
                                        end
                                    end
                                    valid_set = { is_local = is_all_local, indices = {} }
                                    local min_idx = math.huge
                                    local max_idx = 0
                                    for _, c_idx in ipairs(best_tuple) do
                                        local cw_obj = ctx_list[c_idx]
                                        valid_set.indices[cw_obj.s_i .. "-" .. cw_obj.t_i] = true
                                        local total_val = cw_obj.s_i * 1000 + cw_obj.l_i
                                        if total_val < min_idx then
                                            min_idx = total_val
                                        end
                                        if total_val > max_idx then
                                            max_idx = total_val
                                        end
                                    end
                                    valid_set.min_idx = min_idx
                                    valid_set.max_idx = max_idx

                                    local is_contiguous = true
                                    local last_c = -1
                                    for _, c_idx in ipairs(best_tuple) do
                                        if last_c ~= -1 and c_idx ~= last_c + 1 then
                                            is_contiguous = false
                                            break
                                        end
                                        last_c = c_idx
                                    end
                                    valid_set.is_contiguous = is_contiguous
                                end
                            end
                            subs[sub_idx].__split_valid_indices[entry_key] = valid_set
                        end

                        if valid_set then
                            if valid_set.indices[sub_idx .. "-" .. token_idx] then
                                match_found = true
                                term_is_split = not valid_set.is_contiguous
                            end
                        end
                    end
                end
            end

            if match_found then
                if term_is_split then
                    purple_stack = purple_stack + 1
                    purple_depth = purple_depth + 1
                else
                    orange_stack = orange_stack + 1
                    if is_in_footprint then
                        purple_depth = purple_depth + 1
                    end
                end
                matched_terms[entry_key] = true
                has_phrase = has_phrase or (#term_clean > 1)
                table.insert(matching_source_terms, { text = data.term, is_split = term_is_split })
            end
        end
    end
    return orange_stack, purple_stack, has_phrase, matching_source_terms, purple_depth
end

-- --- populate_token_meta --------------------------------------------------

local function populate_token_meta(
    subs,
    sub_idx,
    tokens,
    base_color,
    t_pos,
    entry,
    force_plain,
    h_color,
    ctrl_color
)
    local token_meta = {}
    local cl, cw = FSM.DW_CURSOR_LINE, FSM.DW_CURSOR_WORD

    h_color = h_color or Options.dw_highlight_color
    ctrl_color = ctrl_color or Options.dw_ctrl_select_color

    for j, t in ipairs(tokens) do
        local l_idx = t.logical_idx or (entry and entry.visual_to_logical[j])
        local meta = {
            text = t.text,
            color = base_color,
            is_word = t.is_word,
            is_phrase = false,
            priority = 0,
        }

        if l_idx and not force_plain then
            local line_set = FSM.DW_CTRL_PENDING_SET[sub_idx]
            if line_set and line_set[l_idx] then
                meta.color = ctrl_color
                meta.priority = 1
            end

            if meta.priority == 0 then
                local selected = is_inside_dw_selection(sub_idx, l_idx)
                local is_focus_point = (sub_idx == cl and text_utils.logical_cmp(l_idx, cw))
                if selected or is_focus_point then
                    meta.color = h_color
                    meta.priority = 2
                end
            end

            if meta.priority == 0 then
                local h_cache = t.highlight_cache
                local orange_stack, purple_stack, is_phrase, matching_terms, purple_depth

                if h_cache and h_cache.version == FSM.ANKI_VERSION then
                    orange_stack = h_cache.orange_stack
                    purple_stack = h_cache.purple_stack
                    is_phrase = h_cache.is_phrase
                    matching_terms = h_cache.matching_terms
                    purple_depth = h_cache.purple_depth
                else
                    orange_stack, purple_stack, is_phrase, matching_terms, purple_depth =
                        calculate_highlight_stack(subs, sub_idx, j, t_pos)
                    t.highlight_cache = {
                        version = FSM.ANKI_VERSION,
                        orange_stack = orange_stack,
                        purple_stack = purple_stack,
                        is_phrase = is_phrase,
                        matching_terms = matching_terms,
                        purple_depth = purple_depth,
                    }
                end

                meta.purple_depth = purple_depth
                local h_color = base_color

                if orange_stack > 0 and purple_stack > 0 then
                    local mix_depth = math.min((orange_stack + (purple_depth or 1)) - 1, 3)
                    if mix_depth == 1 then
                        h_color = Options.anki_mix_depth_1 or "4A4AD3"
                    elseif mix_depth == 2 then
                        h_color = Options.anki_mix_depth_2 or "3636A8"
                    elseif mix_depth >= 3 then
                        h_color = Options.anki_mix_depth_3 or "151578"
                    end
                elseif orange_stack > 0 then
                    local o_depth = math.min(orange_stack, 3)
                    if o_depth == 1 then
                        h_color = Options.anki_highlight_depth_1
                    elseif o_depth == 2 then
                        h_color = Options.anki_highlight_depth_2
                    else
                        h_color = Options.anki_highlight_depth_3
                    end
                elseif purple_stack > 0 then
                    local p_depth = math.min(purple_stack, 3)
                    if p_depth == 1 then
                        h_color = Options.anki_split_depth_1 or "B088FF"
                    elseif p_depth == 2 then
                        h_color = Options.anki_split_depth_2 or "9674D9"
                    else
                        h_color = Options.anki_split_depth_3 or "7C60B3"
                    end
                end

                if h_color ~= base_color then
                    meta.color = h_color
                    meta.is_phrase = is_phrase
                    meta.matching_terms = matching_terms
                    meta.priority = 3
                end
            end
        end
        token_meta[j] = meta
    end
    return token_meta
end

-- --- format_highlighted_word -----------------------------------------------

local function format_highlighted_word(
    word,
    h_color,
    base_color,
    is_phrase,
    bold_state,
    use_1c,
    force_bold,
    is_manual,
    bg_color,
    bg_alpha,
    border_size
)
    if type(word) == "table" then
        word = word.text
    end
    if not word then
        return ""
    end

    local c_tag = use_1c and "1c" or "c"
    local is_bold = (force_bold ~= nil) and force_bold or Options.anki_highlight_bold
    local b_on = string.format("{\\b%s}", is_bold and "1" or "0")
    local b_off = string.format("{\\b%s}", bold_state or "0")

    if h_color == base_color then
        return word
    end

    bg_color = bg_color or "000000"
    bg_alpha = bg_alpha or "00"
    border_size = border_size or Options.dw_border_size
    local h_tags, r_tags
    if FSM.osd_border_style == "background-box" then
        h_tags = string.format("{\\%s&H%s&}", c_tag, h_color)
        r_tags = string.format("{\\%s&H%s&}", c_tag, base_color)
    else
        h_tags = string.format(
            "{\\%s&H%s&\\3c&H%s&\\4c&H%s&\\3a&H%s&\\4a&H%s&\\bord%g}",
            c_tag,
            h_color,
            bg_color,
            bg_color,
            bg_alpha,
            bg_alpha,
            border_size
        )
        r_tags = string.format(
            "{\\%s&H%s&\\3c&H%s&\\4c&H%s&\\3a&H%s&\\4a&H%s&\\bord%g}",
            c_tag,
            base_color,
            bg_color,
            bg_color,
            bg_alpha,
            bg_alpha,
            border_size
        )
    end

    if is_phrase or is_manual then
        local p_b_on = is_manual and "{\\b0}" or b_on
        return string.format("%s%s%s%s{\\b%s}", p_b_on, h_tags, word, r_tags, bold_state or "0")
    else
        local pre = word:match("^[%p%s]*")
        local suf = word:match("[%p%s]*$")
        local mid = ""
        if #pre < #word then
            mid = word:sub(#pre + 1, #word - #suf)
        end
        if mid ~= "" then
            return string.format("%s%s%s%s%s%s%s", pre, b_on, h_tags, mid, b_off, r_tags, suf)
        else
            return word
        end
    end
end

-- --- dw_get_str_width_proportional ----------------------------------------

local function dw_get_str_width_proportional(str, fs)
    if type(str) == "table" then
        str = str.text
    end
    if not str then
        return 0
    end
    fs = fs or Options.dw_font_size

    str = str:gsub("{[^}]+}", "")

    local w = 0
    for c in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if c == " " then
            w = w + (fs * 0.30)
        elseif c:match("[il1tI|!.,:;'\"`%(%)%[%]]") then
            w = w + (fs * 0.22)
        elseif c:match("[mwMW%@]") then
            w = w + (fs * 0.65)
        elseif c:match("[a-zA-Z0-9]") then
            w = w + (fs * 0.42)
        elseif #c > 1 then
            w = w + (fs * 0.52)
        else
            w = w + (fs * 0.42)
        end
    end
    return w
end

-- --- dw_get_str_width -----------------------------------------------------

local function dw_get_str_width(str, fs, font_name)
    if type(str) == "table" then
        str = str.text
    end
    if not str then
        return 0
    end
    fs = fs or Options.dw_font_size
    font_name = font_name or Options.dw_font_name

    str = str:gsub("{[^}]+}", "")

    if font_name:lower():match("consolas") or font_name:lower():match("mono") then
        local len = 0
        for _ in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
            len = len + 1
        end
        return len * fs * Options.dw_char_width
    end

    return dw_get_str_width_proportional(str, fs)
end

-- --- calculate_sub_gap ----------------------------------------------------

local function calculate_sub_gap(prefix, font_size, lh_mul, vsp)
    local b_gap_mul = Options[prefix .. "_block_gap_mul"] or 0
    local d_gap = Options[prefix .. "_double_gap"]

    if d_gap then
        return (font_size * lh_mul) + (font_size * b_gap_mul) + vsp
    else
        return 0
    end
end

-- --- wrap_tokens ----------------------------------------------------------

local function wrap_tokens(tokens, max_w, font_size, font_name, keep_spaces)
    local vlines = {}
    local cur_indices = {}
    local cur_w = 0
    local space_w = dw_get_str_width(" ", font_size, font_name)

    for j, t in ipairs(tokens) do
        local ww = dw_get_str_width(t.text, font_size, font_name)
        local space = (#cur_indices > 0 and not keep_spaces) and space_w or 0

        local has_newline = t.text:find("\n") ~= nil
        local is_punc = (t.text == "." or t.text == ",")

        if
            ((cur_w + space + ww > max_w and #cur_indices > 0) or has_newline)
            and not (is_punc and not has_newline)
        then
            if #cur_indices > 0 then
                table.insert(vlines, cur_indices)
                cur_indices = {}
                cur_w = 0
            end

            if not has_newline or t.text:gsub("\n", "") ~= "" then
                table.insert(cur_indices, j)
                cur_w = ww
            end
        else
            table.insert(cur_indices, j)
            cur_w = cur_w + space + ww
        end
    end
    if #cur_indices > 0 then
        table.insert(vlines, cur_indices)
    end
    return vlines
end

-- --- calculate_osd_line_meta ----------------------------------------------

local function calculate_osd_line_meta(text, sub_idx, font_size, font_name, line_height_mul, vsp)
    local tokens = text_utils.build_word_list_internal(text, Options.dw_original_spacing)
    local max_text_w = 1860
    local vline_indices =
        wrap_tokens(tokens, max_text_w, font_size, font_name, Options.dw_original_spacing)

    if #vline_indices == 0 then
        vline_indices = { {} }
    end

    local space_w = dw_get_str_width(" ", font_size, font_name)

    local lines = {}
    local total_h = 0
    local max_w = 0

    for i, vl_idx_list in ipairs(vline_indices) do
        local words = {}
        local line_w = 0
        for pos, j in ipairs(vl_idx_list) do
            local t = tokens[j]
            local ww = dw_get_str_width(t.text, font_size, font_name)
            local space = (pos > 1 and not Options.dw_original_spacing) and space_w or 0

            if t.logical_idx then
                table.insert(words, {
                    logical_idx = t.logical_idx,
                    x_offset = line_w + space,
                    width = ww,
                    text = t.text,
                })
            end
            line_w = line_w + space + ww
        end

        local h = (font_size * line_height_mul) + vsp
        table.insert(lines, {
            words = words,
            total_width = line_w,
            height = h,
            y_offset = total_h,
            token_indices = vl_idx_list,
        })
        total_h = total_h + h
        max_w = math.max(max_w, line_w)
    end

    return {
        sub_idx = sub_idx,
        vlines = lines,
        total_width = max_w,
        total_height = total_h,
        tokens = tokens,
        size = font_size,
    }
end

-- --- dw_vline_height ------------------------------------------------------

local function dw_vline_height()
    local wrap_mul = Options.dw_wrap_line_height_mul or Options.dw_line_height_mul
    return (Options.dw_font_size * wrap_mul) + (Options.dw_vsp or 0)
end

-- --- dw_build_layout ------------------------------------------------------

local function dw_build_layout(subs, view_center)
    if
        FSM.DW_LAYOUT_CACHE
        and FSM.DW_LAYOUT_CACHE.view_center == view_center
        and FSM.DW_LAYOUT_CACHE.subs_ptr == subs
        and FSM.DW_LAYOUT_CACHE.layout_version == FSM.LAYOUT_VERSION
    then
        return FSM.DW_LAYOUT_CACHE.layout, FSM.DW_LAYOUT_CACHE.total_height
    end

    local win_lines = Options.dw_lines_visible
    local half_win = math.floor(win_lines / 2)
    view_center = math.max(1, math.min(#subs, view_center))
    local start_idx = view_center - half_win
    local end_idx = view_center + (win_lines - half_win - 1)

    if start_idx < 1 then
        end_idx = end_idx + (1 - start_idx)
        start_idx = 1
    end
    if end_idx > #subs then
        start_idx = start_idx - (end_idx - #subs)
        end_idx = #subs
    end
    start_idx = math.max(1, start_idx)
    end_idx = math.min(#subs, end_idx)

    local lh_mul = Options.dw_line_height_mul
    local vline_h = M.dw_vline_height()
    local sub_gap = calculate_sub_gap("dw", Options.dw_font_size, lh_mul, Options.dw_vsp)
    local max_text_w = 1860
    local space_w = dw_get_str_width(" ")

    local layout = {}
    local total_height = 0

    for i = start_idx, end_idx do
        local s = subs[i]
        local entry

        if s.layout_cache and s.layout_cache.version == FSM.LAYOUT_VERSION then
            entry = s.layout_cache.entry
            if
                not entry
                or type(entry.height) ~= "number"
                or not entry.vlines
                or type(entry.sub_idx) ~= "number"
                or not entry.logical_words
                or not entry.visual_to_logical
            then
                entry = nil
            end
        end

        if not entry then
            local tokens = text_utils.get_sub_tokens(s) or {}
            if #tokens == 0 then
                tokens = { { text = "" } }
            end

            local logical_words = {}
            local visual_to_logical = {}
            local logical_to_visual = {}

            for j, t in ipairs(tokens) do
                if t.logical_idx then
                    visual_to_logical[j] = t.logical_idx
                    logical_to_visual[t.logical_idx] = j
                end
                if text_utils.is_word_token(t) then
                    table.insert(logical_words, t)
                end
            end

            local vlines = {}
            local cur_indices = {}
            local cur_w = 0

            for j, w in ipairs(tokens) do
                local ww = dw_get_str_width(w)
                local space = (#cur_indices > 0 and not Options.dw_original_spacing) and space_w
                    or 0
                if cur_w + space + ww > max_text_w and #cur_indices > 0 then
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

            local entry_h = #vlines * vline_h
            entry = {
                sub_idx = i,
                words = tokens,
                logical_words = logical_words,
                visual_to_logical = visual_to_logical,
                logical_to_visual = logical_to_visual,
                height = entry_h,
                vlines = vlines,
            }

            s.layout_cache = {
                version = FSM.LAYOUT_VERSION,
                entry = entry,
            }
        end

        table.insert(layout, entry)
        total_height = total_height + entry.height
        if i < end_idx then
            total_height = total_height + sub_gap
        end
    end

    FSM.DW_LAYOUT_CACHE = {
        view_center = view_center,
        subs_ptr = subs,
        layout_version = FSM.LAYOUT_VERSION,
        layout = layout,
        total_height = total_height,
    }

    return layout, total_height
end

-- --- dw_calculate_block_top -----------------------------------------------

local function dw_calculate_block_top(view_center, active_idx, layout, total_height)
    local lh_mul = Options.dw_line_height_mul
    local base_h = Options.font_base_height or 1080
    local center_y = base_h / 2
    local edge_margin = Options.dw_edge_margin or 0

    local block_top = center_y - (total_height / 2)

    if total_height > base_h - 2 * edge_margin then
        local offset_y = 0
        local found_center = false
        for layout_i, entry in ipairs(layout) do
            if entry.sub_idx == view_center then
                offset_y = offset_y + (entry.height / 2)
                found_center = true
                break
            else
                offset_y = offset_y + entry.height
                if layout_i < #layout then
                    local is_active = (entry.sub_idx == active_idx)
                    local line_fs = Options.dw_font_size
                        * (is_active and Options.dw_active_size_mul or Options.dw_context_size_mul)
                    offset_y = offset_y + calculate_sub_gap("dw", line_fs, lh_mul, Options.dw_vsp)
                end
            end
        end
        if found_center then
            block_top = center_y - offset_y
        end

        if block_top > edge_margin then
            block_top = edge_margin
        elseif block_top + total_height < base_h - edge_margin then
            block_top = base_h - edge_margin - total_height
        end
    end

    return block_top
end

-- --- format_tooltip_card_event --------------------------------------------

local function format_tooltip_card_event(
    style_ctx,
    rect_left,
    rect_top,
    rect_w,
    rect_h,
    rect_bg_alpha
)
    return string.format(
        "{\\pos(%g, %g)}{\\an7}{\\bord%g}{\\shad%g}{\\3c&H%s&}{\\4c&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\1c&H%s&}{\\1a&H%s&}{\\p1}m 0 0 l %g 0 l %g %g l 0 %g{\\p0}",
        rect_left,
        rect_top,
        style_ctx.bord,
        style_ctx.shad,
        style_ctx.bg_color,
        style_ctx.bg_color,
        style_ctx.bg_alpha,
        style_ctx.bg_alpha,
        style_ctx.bg_color,
        rect_bg_alpha,
        rect_w,
        rect_w,
        rect_h,
        rect_h
    )
end

-- --- format_tooltip_text_event --------------------------------------------

local function format_tooltip_text_event(style_ctx, anchor_x, line_center_y, line_text)
    local neutralize_bgbox = style_ctx.neutralize_inband and "{\\3a&HFF&}{\\4a&HFF&}" or ""
    return string.format(
        "{\\pos(%g, %g)}{\\an6}{\\bord%g}{\\shad%g}{\\3c&H%s&}{\\4c&H%s&}{\\3a&H%s&}{\\4a&H%s&}{\\q2}%s%s",
        anchor_x,
        line_center_y,
        style_ctx.bord,
        style_ctx.shad,
        style_ctx.bg_color,
        style_ctx.bg_color,
        style_ctx.bg_alpha,
        style_ctx.bg_alpha,
        neutralize_bgbox,
        line_text
    )
end

-- --- module exports --------------------------------------------------------

M.compose_term_smart = compose_term_smart
M.calculate_highlight_stack = calculate_highlight_stack
M.populate_token_meta = populate_token_meta
M.format_highlighted_word = format_highlighted_word
M.dw_get_str_width_proportional = dw_get_str_width_proportional
M.dw_get_str_width = dw_get_str_width
M.calculate_sub_gap = calculate_sub_gap
M.wrap_tokens = wrap_tokens
M.calculate_osd_line_meta = calculate_osd_line_meta
M.dw_build_layout = dw_build_layout
M.dw_calculate_block_top = dw_calculate_block_top
M.dw_vline_height = dw_vline_height
M.format_tooltip_card_event = format_tooltip_card_event
M.format_tooltip_text_event = format_tooltip_text_event

return M
