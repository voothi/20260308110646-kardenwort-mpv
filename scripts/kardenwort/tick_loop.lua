-- ============================================================================
-- tick_loop.lua — Core timing, scheduling, rendering, and immersion loop
-- Contains master_tick, tick_dw, tick_drum, tick_autopause, and loops.
-- Reads/writes FSM/Options/Tracks at call time via injected singletons.
-- ============================================================================

local mp = require("mp")
local subtitle_parser = require("subtitle_parser")
local dw_navigation = require("dw_navigation")
local mouse_input = require("mouse_input")
local subtitle_window = require("subtitle_window")

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
    assert(helpers.protect_internal_replay_seek, "FATAL: helper 'protect_internal_replay_seek' missing")
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

-- Import subtitle_parser aliases
local get_center_index = subtitle_parser.get_center_index
local get_effective_boundaries = subtitle_parser.get_effective_boundaries

local function dw_ensure_visible(line_idx, scroll_to_top)
    dw_navigation.dw_ensure_visible(line_idx, scroll_to_top)
end

-- 1. tick_dw
local function tick_dw(time_pos, active_idx)
    if FSM.DRUM_WINDOW == "OFF" then
        if _helpers.dw_osd.data ~= "" then
            _helpers.dw_osd.data = ""
            _helpers.dw_osd:update()
        end
        return
    end
    local subs = Tracks.pri.subs
    if #subs == 0 or not active_idx or active_idx == -1 then
        return
    end

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

    _helpers.dw_osd.data = subtitle_window.draw_dw(subs, FSM.DW_VIEW_CENTER, active_idx)
    _helpers.dw_osd:update()

    mouse_input.dw_tooltip_mouse_update()
end

-- 2. tick_drum
local function tick_drum(time_pos, pri_use_osd, sec_use_osd)
    -- Don't render Drum Mode OSD while Drum Window is open (they overlap)
    if FSM.DRUM_WINDOW ~= "OFF" then
        if _helpers.drum_osd.data ~= "" then
            _helpers.drum_osd.data = ""
            _helpers.drum_osd:update()
        end
        return
    end

    local is_drum = (FSM.DRUM == "ON")

    -- If no tracks are requested for OSD, clear and return
    if not pri_use_osd and not sec_use_osd then
        if _helpers.drum_osd.data ~= "" then
            _helpers.drum_osd.data = ""
            _helpers.drum_osd:update()
        end
        return
    end

    local ass_text = ""
    local font_size = is_drum
            and (Options.drum_font_size > 0 and Options.drum_font_size or mp.get_property_number(
                "sub-font-size",
                44
            ))
        or (
            Options.srt_font_size > 0 and Options.srt_font_size
            or mp.get_property_number("sub-font-size", 44)
        )

    local pri_pos = mp.get_property_number("sub-pos", 95)
    local sec_pos = mp.get_property_number("secondary-sub-pos", 10)

    local context_lines = is_drum and Options.drum_context_lines or 0

    if sec_pos > 50 then
        local max_lines = Options.drum_active_size_mul
            + (2 * context_lines * Options.drum_context_size_mul)
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
    if
        is_drum
        and FSM.DW_FOLLOW_PLAYER
        and FSM.BOOK_MODE
        and not FSM.DW_SEEKING_MANUALLY
        and #Tracks.pri.subs > 0
    then
        local pri_active_idx = get_center_index(Tracks.pri.subs, time_pos)
        if pri_active_idx and pri_active_idx ~= -1 then
            if FSM.DW_VIEW_CENTER == -1 then
                FSM.DW_VIEW_CENTER = pri_active_idx
            end
            dw_ensure_visible(pri_active_idx, true)
        end
    end

    local pri_active_idx = (#Tracks.pri.subs > 0) and get_center_index(Tracks.pri.subs, time_pos)
        or -1
    local sec_active_idx = (#Tracks.sec.subs > 0) and get_center_index(Tracks.sec.subs, time_pos)
        or -1

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
    if pri_view_center == -1 then
        pri_view_center = pri_active_idx
    end

    -- Draw Primary FIRST, Secondary SECOND (so Secondary is on top in Z-order)
    if pri_use_osd and #Tracks.pri.subs > 0 then
        local active_idx = pri_active_idx
        local view_center = pri_view_center

        local pri_plain = is_drum and not Options.drum_pri_highlighting
            or not Options.srt_pri_highlighting
        ass_text = ass_text
            .. subtitle_window.draw_drum(
                Tracks.pri.subs,
                view_center,
                active_idx,
                pri_pos,
                time_pos,
                font_size,
                FSM.DRUM_HIT_ZONES,
                pri_plain,
                true
            )
    end

    if sec_use_osd and #Tracks.sec.subs > 0 then
        local active_idx = sec_active_idx
        -- Secondary track mirrors primary viewport offset in all follow modes.
        local view_center = active_idx
        if pri_active_idx ~= -1 and pri_view_center ~= -1 then
            local offset = pri_view_center - pri_active_idx
            view_center = math.max(1, math.min(#Tracks.sec.subs, active_idx + offset))
        end

        local sec_plain = is_drum and not Options.drum_sec_highlighting
            or not Options.srt_sec_highlighting
        ass_text = ass_text
            .. subtitle_window.draw_drum(
                Tracks.sec.subs,
                view_center,
                active_idx,
                sec_pos,
                time_pos,
                font_size,
                FSM.DRUM_HIT_ZONES,
                sec_plain,
                false
            )
    end

    _helpers.drum_osd.data = ass_text
    _helpers.drum_osd:update()
end

-- 3. tick_autopause
local function tick_autopause(time_pos)
    if FSM.AUTOPAUSE ~= "ON" or FSM.SPACEBAR ~= "IDLE" then
        return
    end
    if FSM.SCHEDULED_REPLAY_START or FSM.LOOP_MODE == "ON" then
        return
    end
    if FSM.MEDIA_STATE == "NO_SUBS" then
        return
    end

    local subs = Tracks.pri.subs
    if not subs or #subs == 0 then
        return
    end

    -- Hardened Autopause via Sticky Focus
    -- Use the Sentinel (ACTIVE_IDX) to determine exactly when the audible tail ends.
    local active_idx = FSM.ACTIVE_IDX
    if active_idx == -1 or not subs[active_idx] then
        -- Fallback if sentinel is lost
        active_idx = get_center_index(subs, time_pos)
    end
    if active_idx == -1 then
        return
    end

    -- Skip autopause while transiting through the rewind zone after Shift+A/D.
    -- Uses <= so the exact boundary tick is still suppressed; the inhibit is cleared
    -- only after jerk-back has also been evaluated (see end of main tick function).
    -- [20260510193230] Special case: within-subtitle rewind should still allow autopause at end.
    local in_rewind_transit = FSM.TIMESEEK_INHIBIT_UNTIL and time_pos <= FSM.TIMESEEK_INHIBIT_UNTIL
    local within_subtitle_rewind = in_rewind_transit
        and FSM.REWIND_START_IDX
        and active_idx == FSM.REWIND_START_IDX

    -- Suppress autopause only during cross-subtitle rewind transit
    if in_rewind_transit and FSM.REWIND_TRANSIT_CROSS_CARD and not within_subtitle_rewind then
        return
    end

    local _, sub_end = get_effective_boundaries(subs, subs[active_idx], active_idx)
    if not sub_end then
        return
    end

    -- Check if we've reached the end of the padded window
    -- Use an inclusive check to ensure we don't skip the pause frame.
    local diff = sub_end - time_pos
    if diff > Options.pause_padding then
        return
    end

    if diff < -Options.autopause_overshoot then
        if
            FSM._prev_time_pos
            and FSM._prev_time_pos < sub_end
            and mp.get_time() > FSM.MANUAL_NAV_COOLDOWN
        then
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
    if FSM.last_paused_sub_end == sub_end then
        return
    end

    -- Ensure we are actually on a subtitle (using internal state rather than transient mpv visibility)
    -- This fixes the "Stops stopping" bug when text clears before the audio tail finishes.
    local raw_text_primary = subs[active_idx].text or ""
    local raw_text_secondary = (Tracks.sec.subs[active_idx] and Tracks.sec.subs[active_idx].text)
        or ""

    if raw_text_primary == "" and raw_text_secondary == "" then
        return
    end

    -- Karaoke Mode: Don't pause if we are in the middle of a phrase with highlights
    if FSM.KARAOKE == "PHRASE" then
        local has_karaoke = string.find(raw_text_primary, Options.karaoke_token, 1, true)
        if not has_karaoke then
            has_karaoke = string.find(raw_text_secondary, Options.karaoke_token, 1, true)
        end
        if has_karaoke then
            return
        end
    end

    mp.set_property_bool("pause", true)
    FSM.last_paused_sub_end = sub_end
end

-- 4. tick_loop_mode
local function tick_loop_mode(time_pos)
    if FSM.LOOP_MODE ~= "ON" then
        return
    end
    if not FSM.LOOP_START or not FSM.LOOP_END then
        return
    end

    if time_pos >= FSM.LOOP_END - Options.pause_padding then
        if FSM.LOOP_ARMED then
            FSM.LOOP_ARMED = false
            _helpers.protect_internal_replay_seek()

            if FSM.REPLAY_REMAINING > 1 then
                FSM.REPLAY_REMAINING = FSM.REPLAY_REMAINING - 1
                local pri_subs = Tracks.pri.subs
                if pri_subs and #pri_subs > 0 then
                    local idx = get_center_index(pri_subs, FSM.LOOP_START)
                    if idx ~= -1 then
                        FSM.ACTIVE_IDX = idx
                    end
                end
                local sec_subs = Tracks.sec.subs
                if sec_subs and #sec_subs > 0 then
                    local idx = get_center_index(sec_subs, FSM.LOOP_START)
                    if idx ~= -1 then
                        FSM.SEC_ACTIVE_IDX = idx
                    end
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

-- 5. tick_scheduled_replay
local function tick_scheduled_replay(time_pos)
    if not FSM.SCHEDULED_REPLAY_START or not FSM.SCHEDULED_REPLAY_END then
        return false
    end

    if time_pos >= FSM.SCHEDULED_REPLAY_END - Options.pause_padding then
        if FSM.REPLAY_REMAINING > 1 then
            FSM.REPLAY_REMAINING = FSM.REPLAY_REMAINING - 1
            _helpers.protect_internal_replay_seek()
            FSM.last_paused_sub_end = nil
            local pri_subs = Tracks.pri.subs
            if pri_subs and #pri_subs > 0 then
                local idx = get_center_index(pri_subs, FSM.SCHEDULED_REPLAY_START)
                if idx ~= -1 then
                    FSM.ACTIVE_IDX = idx
                end
            end
            local sec_subs = Tracks.sec.subs
            if sec_subs and #sec_subs > 0 then
                local idx = get_center_index(sec_subs, FSM.SCHEDULED_REPLAY_START)
                if idx ~= -1 then
                    FSM.SEC_ACTIVE_IDX = idx
                end
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

-- 6. master_tick
local function master_tick()
    local ok, err = xpcall(function()
        local time_pos = mp.get_property_number("time-pos")
        if not time_pos then
            return
        end

        -- Ghost Hold Recovery
        -- If Space is 'HOLDING' due to a suspected ghost event at 's' press,
        -- but no physical 'DOWN' event has refreshed it within 2 seconds, revert to IDLE.
        if
            FSM.SPACEBAR == "HOLDING"
            and FSM.GHOST_HOLD_EXPIRY
            and mp.get_time() > FSM.GHOST_HOLD_EXPIRY
        then
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
            local is_coarse_reporting = wall_delta > 0
                and (math.abs(time_pos - FSM.last_time_pos) / wall_delta) < 2.0
            local internal_replay_jump = FSM.INTERNAL_REPLAY_UNTIL
                and mp.get_time() < FSM.INTERNAL_REPLAY_UNTIL
            local ignore_jump = FSM.IGNORE_NEXT_JUMP
                or (FSM.IGNORE_NEXT_JUMP_UNTIL and mp.get_time() < FSM.IGNORE_NEXT_JUMP_UNTIL)
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
                            _helpers.show_osd("Loop: Line " .. idx)
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
            tick_loop_mode(time_pos)
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

                if
                    FSM.IMMERSION_MODE == "PHRASE"
                    and not phrase_space_movie_override
                    and mp.get_time() > FSM.MANUAL_NAV_COOLDOWN
                    and (not FSM.TIMESEEK_INHIBIT_UNTIL or not FSM.REWIND_TRANSIT_CROSS_CARD)
                then
                    if
                        FSM.ACTIVE_IDX ~= -1
                        and active_idx > FSM.ACTIVE_IDX
                        and active_idx <= FSM.ACTIVE_IDX + 5
                    then
                        local s_next, _ = get_effective_boundaries(
                            Tracks.pri.subs,
                            Tracks.pri.subs[active_idx],
                            active_idx
                        )
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
            if
                is_autopause_paused_sec
                and FSM.SEC_ACTIVE_IDX ~= -1
                and sec_idx ~= FSM.SEC_ACTIVE_IDX
            then
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
        local use_osd_for_srt = (
            Options.srt_font_name ~= ""
            or Options.srt_font_bold
            or Options.srt_font_size > 0
        )
        local dw_active = (FSM.DRUM_WINDOW ~= "OFF")

        -- Independent OSD render decisions:
        -- 1. Always use OSD if Drum Mode is ON.
        -- 2. Use OSD for SRT if custom fonts are configured.
        -- 3. [20260501163905] Force OSD if a highlight (Yellow Pointer or Pink Set) exists on the active line.
        -- 4. NEVER use OSD for ASS in Regular mode (to preserve styling/layout).
        local has_ptr = (FSM.DW_CURSOR_WORD ~= -1 and active_idx == FSM.DW_CURSOR_LINE)
        local has_pink = (next(FSM.DW_CTRL_PENDING_SET) ~= nil)
        local pri_effective_vis = FSM.native_sub_vis and not FSM.SEC_ONLY_MODE
        local sec_effective_vis = (FSM.native_sub_vis and FSM.native_sec_sub_vis)
            or FSM.SEC_ONLY_MODE
        local pri_use_osd = pri_effective_vis
            and (
                (FSM.DRUM == "ON")
                or (not Tracks.pri.is_ass and (use_osd_for_srt or has_ptr or has_pink))
            )
        local sec_use_osd = sec_effective_vis
            and (
                (FSM.DRUM == "ON")
                or (not Tracks.sec.is_ass and (use_osd_for_srt or has_ptr or has_pink))
            )

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
                if _helpers.drum_osd.data ~= "" then
                    _helpers.drum_osd.data = ""
                    _helpers.drum_osd:update()
                end
            end
        else
            -- Clear OSD if not rendering
            if _helpers.drum_osd.data ~= "" then
                _helpers.drum_osd.data = ""
                _helpers.drum_osd:update()
            end
            -- Restore native if user wants subs and we aren't using OSD
            if FSM.native_sub_vis then
                if not mp.get_property_bool("sub-visibility") then
                    mp.set_property_bool("sub-visibility", true)
                end
                -- Only restore secondary if it should be on
                if
                    FSM.native_sec_sub_vis and not mp.get_property_bool("secondary-sub-visibility")
                then
                    mp.set_property_bool("secondary-sub-visibility", true)
                elseif
                    not FSM.native_sec_sub_vis and mp.get_property_bool("secondary-sub-visibility")
                then
                    mp.set_property_bool("secondary-sub-visibility", false)
                end
            else
                if
                    mp.get_property_bool("sub-visibility")
                    or mp.get_property_bool("secondary-sub-visibility")
                then
                    mp.set_property_bool("sub-visibility", false)
                    mp.set_property_bool("secondary-sub-visibility", false)
                end
            end
        end

        -- Execute Drum Window
        if FSM.DRUM_WINDOW == "DOCKED" then
            tick_dw(time_pos, active_idx)
        elseif Options.osd_interactivity then
            mouse_input.dw_tooltip_mouse_update()
        end
    end, debug.traceback)
    if not ok then
        Diagnostic.error("master_tick crash: " .. tostring(err))
    end
end

M.tick_dw = tick_dw
M.tick_drum = tick_drum
M.tick_autopause = tick_autopause
M.tick_loop_mode = tick_loop_mode
M.tick_scheduled_replay = tick_scheduled_replay
M.master_tick = master_tick

return M
