-- ============================================================================
-- state.lua — Kardenwort FSM + Tracks tables
-- ============================================================================

local mp = require("mp")

local M = {}

function M.init(opts)
    assert(opts, "FATAL: opts dependency missing")
    M.FSM.AUTOPAUSE = opts.autopause_default and "ON" or "OFF"
    M.FSM.KARAOKE = opts.karaoke_every_word and "WORD" or "PHRASE"
    M.FSM.BOOK_MODE = opts.book_mode or false
    M.FSM.IMMERSION_MODE = (opts.immersion_mode_default == "MOVIE") and "MOVIE" or "PHRASE"
    M.FSM.native_sub_vis = mp.get_property_bool("sub-visibility", true)
    M.FSM.native_sec_sub_vis = mp.get_property_bool("secondary-sub-visibility", true)
    M.FSM.native_sec_sub_pos = mp.get_property_number("secondary-sub-pos", 10)
    M.FSM.osd_border_style = mp.get_property("osd-border-style")
end

M.FSM = {
    -- Media Context
    MEDIA_STATE = "NO_SUBS",

    -- Feature States
    AUTOPAUSE = "ON",
    KARAOKE = "PHRASE",
    SPACEBAR = "IDLE",
    DRUM = "OFF",
    COPY_MODE = "A",
    COPY_CONTEXT = "OFF",
    BOOK_MODE = false,
    OSC_VIS = 0,
    ACTIVE_IDX = -1,
    SEC_ACTIVE_IDX = -1,
    IMMERSION_MODE = "PHRASE",
    JUST_JERKED_TO = -1,
    MANUAL_NAV_COOLDOWN = 0,
    MANUAL_NAV_TARGET_IDX = nil,
    SEC_MANUAL_NAV_TARGET_IDX = nil,
    SEEK_ACCUMULATOR = 0,
    SEEK_LAST_TIME = 0,
    SEEK_PRESS_COUNT = 0,

    -- Transients
    last_paused_sub_end = nil,
    last_time_pos = nil,
    last_wall_time = nil,
    IGNORE_NEXT_JUMP = false,
    IGNORE_NEXT_JUMP_UNTIL = nil,
    INTERNAL_REPLAY_UNTIL = 0,
    TIMESEEK_INHIBIT_UNTIL = nil,
    REWIND_START_IDX = nil,
    REWIND_TRANSIT_CROSS_CARD = false,
    LOOP_MODE = "OFF",
    SEC_ONLY_MODE = false,
    LOOP_ARMED = false,
    LOOP_START = nil,
    LOOP_END = nil,
    SCHEDULED_REPLAY_START = nil,
    SCHEDULED_REPLAY_END = nil,
    REPLAY_REMAINING = 0,
    GHOST_HOLD_EXPIRY = nil,
    PHYSICAL_SPACE_HOLD = false,
    space_down_time = 0,
    space_up_time = 0,
    initial_pause_state = true,
    native_sub_vis = true,
    native_sec_sub_vis = true,
    native_sec_sub_pos = 10,
    SUB_VIS_COMBO_BEFORE_OFF = "both",

    -- Drum Window State
    DRUM_WINDOW = "OFF",
    DW_SAVED_SUB_VIS = nil,
    DW_SAVED_DRUM_STATE = nil,
    DW_CURSOR_LINE = -1,
    DW_CURSOR_WORD = -1,
    DW_CURSOR_X = nil,
    DW_ANCHOR_LINE = -1,
    DW_ANCHOR_WORD = -1,
    DW_POINTER_FSM = "POINTER_NULL_FOLLOW",
    DW_VIEW_CENTER = -1,
    DW_FOLLOW_PLAYER = true,
    DW_KEY_OVERRIDE = false,
    DW_MOUSE_DRAGGING = false,
    DW_MOUSE_PENDING_DRAG = false,
    DW_MOUSE_DOWN_X = nil,
    DW_MOUSE_DOWN_Y = nil,
    DW_CTRL_HELD = false,
    DW_CTRL_PENDING_SET = {},
    DW_CTRL_PENDING_LIST = {},
    DW_CTRL_PENDING_VERSION = 0,
    DW_MOUSE_SCROLL_TIMER = nil,
    DW_NATIVE_WINDOW_DRAGGING = nil,
    DW_PROTECTED_SELECTION = false,

    -- Performance Caches
    DW_LAYOUT_CACHE = nil,
    LAYOUT_VERSION = 0,
    -- Global Search State
    SEARCH_MODE = false,
    SEARCH_QUERY = "",
    SEARCH_RESULTS = {},
    SEARCH_SEL_IDX = 1,
    SEARCH_CURSOR = 0,
    SEARCH_ANCHOR = -1,
    SEARCH_CHAR_BINDINGS = {},
    SEARCH_BORDER_OVERRIDE = false,
    SEARCH_HIT_ZONES = nil,

    -- Transient UI State
    saved_osd_border_style = nil,
    ui_border_override_depth = 0,
    osd_border_style = nil,
    LAST_OSD_TIME = 0,
    LAST_TRIGGER_TIME = 0,
    DRUM_HIT_ZONES = nil,
    DW_HIT_ZONES = nil,

    -- Tooltip State
    DW_TOOLTIP_LINE = -1,
    DW_TOOLTIP_MODE = "CLICK",
    DW_TOOLTIP_HOLDING = false,
    DW_TOOLTIP_LOCKED_LINE = -1,
    DW_TOOLTIP_FORCE = false,
    DW_LINE_Y_MAP = {},
    DW_TOOLTIP_HIT_ZONES = nil,
    DW_ACTIVE_LINE = -1,
    DW_TOOLTIP_TARGET_MODE = "ACTIVE",
    DW_TOOLTIP_BORDER_OVERRIDE = false,
    DW_TOOLTIP_SEC_SUBS = {},
    DW_TOOLTIP_SEC_PATH = nil,
    DW_BLOCK_TOP = 0,
    DW_TOTAL_HEIGHT = 0,
    DW_SEEKING_MANUALLY = false,
    DW_SEEK_TARGET = -1,
    DW_MOUSE_LOCK_UNTIL = 0,
    DW_DRAG_IS_PRI = true,
    DW_ESC_NEUTRAL_ARMED = false,
    DW_NEUTRAL_LINE = -1,
    DW_NEUTRAL_WORD = -1,

    -- Repeat Timer
    SEEK_REPEAT_TIMER = nil,

    -- Anki Highlighter State
    ANKI_HIGHLIGHTS = {},
    ANKI_HIGHLIGHTS_SORTED = {},
    ANKI_VERSION = 0,
    ANKI_DB_PATH = nil,
    ANKI_DB_MTIME = 0,
    ANKI_DB_SIZE = 0,

    -- Help State
    HELP_MODE = false,
    HELP_SCROLL_OFFSET = 0,
    HELP_SCROLL_MAX = 0,

    -- notice_osd overlay (created by main.lua after Options is available)
    notice_osd = nil,
    notice_timer = nil,
}

M.Tracks = {
    pri = { id = 0, is_ass = false, path = nil, subs = {} },
    sec = { id = 0, is_ass = false, path = nil, subs = {} },
}

return M
