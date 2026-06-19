-- ===============================================================================
-- osd_cards.lua — OSD card rendering (show_osd + show_seek_osd)
-- show_osd and show_seek_osd are kept DISTINCT (do NOT merge — they differ in
-- overlay target and test-contract side effects; see design / task 1.3).
-- Reads FSM/Options at call time via injected references (never copied).
-- ===============================================================================

local mp = require 'mp'

local M = {}

local FSM, Options, Tracks, Diagnostic

function M.init(fsm, opts, tracks, diagnostic)
    FSM = fsm
    Options = opts
    Tracks = tracks
    Diagnostic = diagnostic
end

-- seek_osd overlay + seek_timer are module-local state, created at setup time
-- (after Options is available). FSM.notice_osd is created by main.lua before
-- M.init() is called and accessed via the FSM reference.
-- seek_osd is exposed on M so main.lua's script-opts observer and render-query
-- probe can reference the same overlay instance.
local seek_osd
local seek_timer
M.seek_osd = nil

local function show_osd(msg, dur)
    local text = tostring(msg or "")
    -- IPC diagnostics contract used by acceptance tests
    mp.set_property("user-data/kardenwort/last_osd", text)
    local duration = dur or Options.osd_duration

    local ry = Options.font_base_height
    local fs = Options.seek_font_size
    local pad_x = math.max(16, math.floor(fs * 0.4))
    local pad_y = math.max(8, math.floor(fs * 0.2))

    local char_count = 0
    for _ in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        char_count = char_count + 1
    end
    local box_w = math.max(160, math.floor(char_count * fs * 0.55 + 2 * pad_x))
    local box_h = fs + 2 * pad_y

    local center_y = math.floor(ry / 2)
    local left_x = 40
    local top_y = center_y - math.floor(box_h / 2)
    local text_x = left_x + pad_x

    local bg_rect = string.format(
        "{\\an7}{\\pos(%d,%d)}{\\bord0}{\\shad0}{\\3a&HFF&}{\\4a&HFF&}{\\1c&H%s&}{\\1a&H%s&}{\\p1}m 0 0 l %d 0 l %d %d l 0 %d{\\p0}",
        left_x, top_y, Options.seek_bg_color, Options.seek_bg_opacity, box_w, box_w, box_h, box_h
    )
    local text_event = string.format(
        "{\\an4}{\\pos(%d,%d)}{\\fn%s}{\\fs%d}{\\b%d}{\\1c&H%s&}{\\3a&HFF&}{\\4a&HFF&}{\\bord0}{\\shad0}%s",
        text_x, center_y,
        Options.seek_font_name, Options.seek_font_size, (Options.seek_font_bold and 1 or 0),
        Options.seek_color, text
    )
    FSM.notice_osd.data = bg_rect .. "\n" .. text_event
    FSM.notice_osd:update()

    if FSM.notice_timer then FSM.notice_timer:kill() end
    FSM.notice_timer = mp.add_timeout(duration, function()
        FSM.notice_osd.data = ""
        FSM.notice_osd:update()
    end)
end

local function setup_seek_osd()
    seek_osd = mp.create_osd_overlay("ass-events")
    seek_osd.res_y = Options.font_base_height
    seek_osd.res_x = math.floor(seek_osd.res_y * 16 / 9)
    seek_osd.z = Options.seek_osd_layer
    seek_timer = nil
    M.seek_osd = seek_osd
end

local function show_seek_osd(msg, alignment)
    local ry = Options.font_base_height
    local rx = math.floor(ry * 16 / 9)
    local fs = Options.seek_font_size
    local pad_x = math.max(16, math.floor(fs * 0.4))
    local pad_y = math.max(8, math.floor(fs * 0.2))

    local char_count = 0
    for _ in msg:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        char_count = char_count + 1
    end
    local box_w = math.max(160, math.floor(char_count * fs * 0.55 + 2 * pad_x))
    local box_h = fs + 2 * pad_y

    local center_y = math.floor(ry / 2)
    local top_y = center_y - math.floor(box_h / 2)

    local left_x, text_x, text_align
    if alignment == 4 then
        left_x = 40
        text_x = left_x + pad_x
        text_align = 4
    else
        left_x = rx - 40 - box_w
        text_x = rx - 40 - pad_x
        text_align = 6
    end

    local bg_rect = string.format(
        "{\\an7}{\\pos(%d,%d)}{\\bord0}{\\shad0}{\\3a&HFF&}{\\4a&HFF&}{\\1c&H%s&}{\\1a&H%s&}{\\p1}m 0 0 l %d 0 l %d %d l 0 %d{\\p0}",
        left_x, top_y, Options.seek_bg_color, Options.seek_bg_opacity, box_w, box_w, box_h, box_h
    )
    local text_event = string.format(
        "{\\an%d}{\\pos(%d,%d)}{\\fn%s}{\\fs%d}{\\b%d}{\\1c&H%s&}{\\3a&HFF&}{\\4a&HFF&}{\\bord0}{\\shad0}%s",
        text_align, text_x, center_y,
        Options.seek_font_name, Options.seek_font_size, (Options.seek_font_bold and 1 or 0),
        Options.seek_color, msg
    )
    seek_osd.data = bg_rect .. "\n" .. text_event
    seek_osd:update()

    if seek_timer then seek_timer:kill() end
    seek_timer = mp.add_timeout(Options.seek_osd_duration, function()
        seek_osd.data = ""
        seek_osd:update()
    end)
end

-- Late setup: main.lua calls M.setup() after Options is fully constructed so
-- the seek_osd overlay can read font_base_height/seek_osd_layer at creation.
function M.setup()
    setup_seek_osd()
end

M.show_osd = show_osd
M.show_seek_osd = show_seek_osd

return M
