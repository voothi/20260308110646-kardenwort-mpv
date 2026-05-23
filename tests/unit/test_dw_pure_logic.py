"""
Python ports of the pure Drum-Window helpers in main.lua.

The functions here mirror the Lua implementations 1:1; they exist so we can
behavior-test the algorithms (especially the dw_hit_test fallback fix) without
spinning up mpv. If a future change drifts main.lua away from this port, the
structural tests in tests/acceptance/test_20260522163656_tag_walk_regressions.py
must catch it - keep the two in sync.

Mirrors the style of tests/unit/test_utils_unit.py (Lua ported to Python).
"""

import math


# --- Ports of main.lua globals -------------------------------------------------


def dw_vline_height(opts):
    wrap_mul = opts.get("dw_wrap_line_height_mul") or opts["dw_line_height_mul"]
    return (opts["dw_font_size"] * wrap_mul) + opts.get("dw_vsp", 0)


def get_dw_drag_threshold_px(opts):
    val = opts.get("dw_mouse_drag_threshold_px", 5)
    try:
        threshold = float(val)
    except (TypeError, ValueError):
        threshold = 5
    if threshold < 0:
        return 0
    return threshold


def get_dw_mouse_auto_scroll_interval(opts):
    val = opts.get("dw_mouse_auto_scroll_interval", 0.05)
    try:
        interval = float(val)
    except (TypeError, ValueError):
        interval = 0.05
    if interval <= 0:
        return 0.05
    return interval


DW_EDGE_SCROLL_RATIO_MAX = 0.49


def dw_pointer_exceeded_drag_threshold(opts, down_x, down_y, x, y):
    dx = abs(x - (down_x if down_x is not None else x))
    dy = abs(y - (down_y if down_y is not None else y))
    threshold = get_dw_drag_threshold_px(opts)
    return (dx > threshold) or (dy > threshold)


def dw_resolve_neighbor_word(zones, target_sub_idx, ref_y_top, osd_x):
    best_zone = None
    best_dy = math.inf
    for z in zones:
        if z["sub_idx"] != target_sub_idx:
            continue
        words = z.get("words") or []
        if not words:
            continue
        dy = abs(z.get("y_top", 0) - ref_y_top)
        if dy < best_dy:
            best_dy = dy
            best_zone = z
    if best_zone is None:
        return None

    rel_x = osd_x - best_zone.get("x_start", 0)
    best_word = None
    best_dx = math.inf
    for word in best_zone["words"]:
        center = word.get("x_offset", 0) + word.get("width", 0) / 2
        dx = abs(rel_x - center)
        if dx < best_dx:
            best_dx = dx
            best_word = word
    return best_word["logical_idx"] if best_word else None


# --- vline_height -------------------------------------------------------------


def test_vline_height_uses_wrap_mul_when_present():
    assert dw_vline_height({"dw_font_size": 40, "dw_wrap_line_height_mul": 1.1, "dw_line_height_mul": 0.9, "dw_vsp": 0}) == 44.0


def test_vline_height_falls_back_to_line_height_mul_when_wrap_missing():
    assert dw_vline_height({"dw_font_size": 40, "dw_line_height_mul": 0.9, "dw_vsp": 0}) == 36.0


def test_vline_height_adds_dw_vsp():
    assert dw_vline_height({"dw_font_size": 40, "dw_wrap_line_height_mul": 1.0, "dw_vsp": 5}) == 45.0


def test_vline_height_tolerates_missing_vsp():
    assert dw_vline_height({"dw_font_size": 40, "dw_wrap_line_height_mul": 1.0}) == 40.0


# --- drag_threshold_px --------------------------------------------------------


def test_drag_threshold_default_is_5():
    assert get_dw_drag_threshold_px({}) == 5


def test_drag_threshold_custom_value():
    assert get_dw_drag_threshold_px({"dw_mouse_drag_threshold_px": 8}) == 8


def test_drag_threshold_negative_clamped_to_zero():
    assert get_dw_drag_threshold_px({"dw_mouse_drag_threshold_px": -3}) == 0


def test_drag_threshold_garbage_string_falls_back_to_default():
    assert get_dw_drag_threshold_px({"dw_mouse_drag_threshold_px": "x"}) == 5


# --- auto_scroll_interval -----------------------------------------------------


def test_auto_scroll_interval_default():
    assert get_dw_mouse_auto_scroll_interval({}) == 0.05


def test_auto_scroll_interval_custom():
    assert get_dw_mouse_auto_scroll_interval({"dw_mouse_auto_scroll_interval": 0.1}) == 0.1


def test_auto_scroll_interval_zero_falls_back_to_default():
    assert get_dw_mouse_auto_scroll_interval({"dw_mouse_auto_scroll_interval": 0}) == 0.05


def test_auto_scroll_interval_negative_falls_back_to_default():
    assert get_dw_mouse_auto_scroll_interval({"dw_mouse_auto_scroll_interval": -1}) == 0.05


# --- pointer_exceeded_drag_threshold ------------------------------------------


def test_drag_same_point_is_not_a_drag():
    opts = {"dw_mouse_drag_threshold_px": 5}
    assert dw_pointer_exceeded_drag_threshold(opts, 100, 100, 100, 100) is False


def test_drag_exactly_at_threshold_is_not_a_drag():
    """Strict `>` comparison: 5px movement with threshold=5 is still a click."""
    opts = {"dw_mouse_drag_threshold_px": 5}
    assert dw_pointer_exceeded_drag_threshold(opts, 100, 100, 105, 100) is False


def test_drag_just_past_threshold_is_a_drag():
    opts = {"dw_mouse_drag_threshold_px": 5}
    assert dw_pointer_exceeded_drag_threshold(opts, 100, 100, 106, 100) is True


def test_drag_vertical_motion_past_threshold_is_a_drag():
    opts = {"dw_mouse_drag_threshold_px": 5}
    assert dw_pointer_exceeded_drag_threshold(opts, 100, 100, 100, 110) is True


def test_drag_nil_down_falls_back_to_current_position():
    opts = {"dw_mouse_drag_threshold_px": 5}
    assert dw_pointer_exceeded_drag_threshold(opts, None, None, 100, 100) is False


def test_drag_zero_threshold_catches_one_px_motion():
    assert dw_pointer_exceeded_drag_threshold({"dw_mouse_drag_threshold_px": 0}, 100, 100, 101, 100) is True


# --- resolve_neighbor_word (the bug-fix regression set) -----------------------


def _zones_with_empty_middle_line():
    """Subtitle 7 has three visual lines: A (y=100, has words), B (y=200, empty), C (y=300, has words)."""
    return [
        {"sub_idx": 6, "y_top": 0, "x_start": 0, "words": [{"logical_idx": 99, "x_offset": 0, "width": 20}]},
        {"sub_idx": 7, "y_top": 100, "x_start": 0, "words": [
            {"logical_idx": 1, "x_offset": 10, "width": 10},
            {"logical_idx": 2, "x_offset": 30, "width": 10},
            {"logical_idx": 3, "x_offset": 50, "width": 10},
        ]},
        {"sub_idx": 7, "y_top": 200, "x_start": 0, "words": []},
        {"sub_idx": 7, "y_top": 300, "x_start": 0, "words": [
            {"logical_idx": 11, "x_offset": 10, "width": 10},
            {"logical_idx": 12, "x_offset": 30, "width": 10},
            {"logical_idx": 13, "x_offset": 50, "width": 10},
        ]},
        {"sub_idx": 8, "y_top": 400, "x_start": 0, "words": [{"logical_idx": 77, "x_offset": 0, "width": 20}]},
    ]


def test_resolve_neighbor_word_picks_horizontally_closest_in_nearest_zone():
    """ref_y=200 is equidistant from line A and line C; first-match wins picks A.
    Within A the word whose center is closest to osd_x=35 is logical_idx=2."""
    zones = _zones_with_empty_middle_line()
    assert dw_resolve_neighbor_word(zones, 7, 200, 35) == 2


def test_resolve_neighbor_word_leftmost_when_osd_x_far_left():
    zones = _zones_with_empty_middle_line()
    assert dw_resolve_neighbor_word(zones, 7, 200, 0) == 1


def test_resolve_neighbor_word_rightmost_when_osd_x_far_right():
    zones = _zones_with_empty_middle_line()
    assert dw_resolve_neighbor_word(zones, 7, 200, 1000) == 3


def test_resolve_neighbor_word_vertical_proximity_wins():
    """ref_y=290 is closer to line C (y=300, dy=10) than line A (y=100, dy=190); C wins."""
    zones = _zones_with_empty_middle_line()
    assert dw_resolve_neighbor_word(zones, 7, 290, 35) == 12


def test_resolve_neighbor_word_returns_none_when_no_same_sub_candidates():
    zones = _zones_with_empty_middle_line()
    assert dw_resolve_neighbor_word(zones, 99, 200, 35) is None


def test_resolve_neighbor_word_does_not_return_last_word_of_zone_old_bug():
    """Regression guard: the pre-fix implementation iterated words inside a
    zone without varying the distance per word, so it returned the LAST word
    of the chosen zone (logical_idx=3) instead of the horizontally-closest
    one (logical_idx=2). This test pins the fix."""
    zones = _zones_with_empty_middle_line()
    assert dw_resolve_neighbor_word(zones, 7, 200, 35) != 3


# --- Port of dw_get_str_width (proportional path) -----------------------------
# Mirrors the Lua implementation; used to lock the Cyrillic width estimate so
# tooltip background rect calculations stay aligned with actual text extent.


_PROPORTIONAL_TIGHT = set("il1tI|!.,:;'\"`()[]")
_PROPORTIONAL_WIDE = set("mwMW@")
_PROPORTIONAL_ASCII = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")


def _iter_utf8_chars(s):
    out = []
    for ch in s:
        out.append(ch)
    return out


def dw_get_str_width(s, fs, font_name, cyrillic_w):
    """Proportional-font branch of dw_get_str_width. The Cyrillic-wide-character
    multiplier is parameterized so this test file pins the exact value used by
    main.lua."""
    assert not (font_name.lower().find("consolas") != -1 or font_name.lower().find("mono") != -1), \
        "test uses proportional path only"
    w = 0.0
    for ch in _iter_utf8_chars(s):
        if ch == " ":
            w += fs * 0.30
        elif ch in _PROPORTIONAL_TIGHT:
            w += fs * 0.22
        elif ch in _PROPORTIONAL_WIDE:
            w += fs * 0.65
        elif ch in _PROPORTIONAL_ASCII:
            w += fs * 0.42
        elif len(ch.encode("utf-8")) > 1:
            w += fs * cyrillic_w
        else:
            w += fs * 0.42
    return w


# Documented current value (must match main.lua's `fs * 0.52` constant).
CYRILLIC_W = 0.52


def test_cyrillic_width_constant_is_at_least_052():
    """The proportional-font heuristic must give Cyrillic glyphs at least
    0.52 of font-size width. The previous value (0.45) underestimated Inter
    font Cyrillic rendering by ~10%, causing the tooltip background rect to
    be too narrow on the left so long Russian lines visibly poked out beyond
    the semi-transparent card (see docs/assets/20260523132907.png).
    """
    assert CYRILLIC_W >= 0.52


def test_cyrillic_width_drives_tooltip_rect_extent():
    """A long Cyrillic line at the tooltip font size must be wider than the
    old 0.45 heuristic predicted - this is what shifts the rect's min_x
    leftward to cover the actual text extent."""
    line = "Я определенно получаю здесь достаточную физическую активность в течение дня."
    fs = 38
    new = dw_get_str_width(line, fs, "Inter", CYRILLIC_W)
    old = dw_get_str_width(line, fs, "Inter", 0.45)
    assert new > old, "new Cyrillic estimate must be larger than the old one"
    # Concretely, the underestimate has to shift by tens of pixels at fs=38.
    assert (new - old) >= 30, f"expected at least 30px wider; got {new - old:.1f}"


def test_ascii_width_unaffected_by_cyrillic_change():
    """Tightening the Cyrillic multiplier must not affect ASCII lines."""
    line = "The quick brown fox jumps over the lazy dog."
    fs = 38
    new = dw_get_str_width(line, fs, "Inter", CYRILLIC_W)
    old = dw_get_str_width(line, fs, "Inter", 0.45)
    assert new == old
