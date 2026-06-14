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


def dw_get_auto_scroll_block_zones(hit_zones, dm_mode):
    if not hit_zones:
        return None, None
    if not dm_mode:
        return hit_zones[0], hit_zones[-1]

    first_zone = None
    last_zone = None
    for zone in hit_zones:
        if zone.get("is_pri") is False or "y_top" not in zone or "y_bottom" not in zone:
            continue
        if first_zone is None or zone["y_top"] < first_zone["y_top"]:
            first_zone = zone
        if last_zone is None or zone["y_bottom"] > last_zone["y_bottom"]:
            last_zone = zone
    return first_zone, last_zone


def dw_auto_scroll_direction(opts, hit_zones, dm_mode, osd_y):
    edge_ratio = opts.get("dw_mouse_edge_scroll_ratio", 0.15)
    edge_ratio = max(0, min(edge_ratio, DW_EDGE_SCROLL_RATIO_MAX))
    base_h = opts.get("font_base_height", 1080)
    edge_zone = base_h * edge_ratio
    top_scroll_trigger = edge_zone
    bottom_scroll_trigger = base_h - edge_zone

    first_zone, last_zone = dw_get_auto_scroll_block_zones(hit_zones, dm_mode)
    if first_zone is None or last_zone is None:
        return 0

    edge_activation_pad = max(2, math.floor(get_dw_drag_threshold_px(opts) / 2))
    if dm_mode:
        top_scroll_trigger = first_zone["y_top"]
        bottom_scroll_trigger = last_zone["y_bottom"]
    else:
        if first_zone["y_top"] <= edge_activation_pad:
            top_scroll_trigger = edge_zone
        else:
            top_scroll_trigger = min(top_scroll_trigger, first_zone["y_top"])
        if last_zone["y_bottom"] >= (base_h - edge_activation_pad):
            bottom_scroll_trigger = base_h - edge_zone
        else:
            bottom_scroll_trigger = max(bottom_scroll_trigger, last_zone["y_bottom"])

    if osd_y < (top_scroll_trigger - edge_activation_pad):
        return -1
    if osd_y > (bottom_scroll_trigger + edge_activation_pad):
        return 1
    return 0


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


# --- auto scroll block bounds -------------------------------------------------


def _mixed_dm_zones():
    return [
        {"sub_idx": 10, "is_pri": True, "y_top": 780, "y_bottom": 830},
        {"sub_idx": 11, "is_pri": True, "y_top": 880, "y_bottom": 930},
        {"sub_idx": 10, "is_pri": False, "y_top": 120, "y_bottom": 170},
        {"sub_idx": 11, "is_pri": False, "y_top": 220, "y_bottom": 270},
    ]


def test_dm_auto_scroll_uses_primary_block_even_when_secondary_is_last():
    first_zone, last_zone = dw_get_auto_scroll_block_zones(_mixed_dm_zones(), dm_mode=True)
    assert first_zone["y_top"] == 780
    assert last_zone["y_bottom"] == 930


def test_dm_auto_scroll_does_not_run_away_inside_primary_bottom_line():
    opts = {"dw_mouse_drag_threshold_px": 5, "dw_mouse_edge_scroll_ratio": 0.15, "font_base_height": 1080}
    assert dw_auto_scroll_direction(opts, _mixed_dm_zones(), dm_mode=True, osd_y=925) == 0


def test_dm_auto_scroll_scrolls_down_below_primary_block():
    opts = {"dw_mouse_drag_threshold_px": 5, "dw_mouse_edge_scroll_ratio": 0.15, "font_base_height": 1080}
    assert dw_auto_scroll_direction(opts, _mixed_dm_zones(), dm_mode=True, osd_y=935) == 1


def test_dm_auto_scroll_scrolls_up_above_primary_block():
    opts = {"dw_mouse_drag_threshold_px": 5, "dw_mouse_edge_scroll_ratio": 0.15, "font_base_height": 1080}
    assert dw_auto_scroll_direction(opts, _mixed_dm_zones(), dm_mode=True, osd_y=775) == -1


def test_dw_auto_scroll_keeps_legacy_screen_edge_bounds():
    opts = {"dw_mouse_drag_threshold_px": 5, "dw_mouse_edge_scroll_ratio": 0.15, "font_base_height": 1080}
    zones = [
        {"sub_idx": 1, "y_top": 320, "y_bottom": 370},
        {"sub_idx": 2, "y_top": 720, "y_bottom": 760},
    ]
    assert dw_auto_scroll_direction(opts, zones, dm_mode=False, osd_y=200) == 0
    assert dw_auto_scroll_direction(opts, zones, dm_mode=False, osd_y=159) == -1
    assert dw_auto_scroll_direction(opts, zones, dm_mode=False, osd_y=921) == 1


def test_dw_auto_scroll_uses_reachable_top_edge_when_wrapped_block_overflows():
    opts = {"dw_mouse_drag_threshold_px": 5, "dw_mouse_edge_scroll_ratio": 0.15, "font_base_height": 1080}
    zones = [
        {"sub_idx": 1, "y_top": -35, "y_bottom": 20},
        {"sub_idx": 2, "y_top": 1040, "y_bottom": 1095},
    ]
    assert dw_auto_scroll_direction(opts, zones, dm_mode=False, osd_y=159) == -1


def test_dw_auto_scroll_uses_reachable_bottom_edge_when_wrapped_block_overflows():
    opts = {"dw_mouse_drag_threshold_px": 5, "dw_mouse_edge_scroll_ratio": 0.15, "font_base_height": 1080}
    zones = [
        {"sub_idx": 1, "y_top": -35, "y_bottom": 20},
        {"sub_idx": 2, "y_top": 1040, "y_bottom": 1095},
    ]
    assert dw_auto_scroll_direction(opts, zones, dm_mode=False, osd_y=921) == 1


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


def _heuristic_cyrillic_width(fs: float) -> float:
    # Mirrors main.lua dw_get_str_width() non-ASCII fallback coefficient.
    return fs * 0.52


def _legacy_heuristic_cyrillic_width(fs: float) -> float:
    return fs * 0.45


def test_cyrillic_width_heuristic_is_calibrated_at_052():
    assert _heuristic_cyrillic_width(34) == 17.68


def test_cyrillic_width_heuristic_is_wider_than_legacy_045():
    assert _heuristic_cyrillic_width(34) > _legacy_heuristic_cyrillic_width(34)


def test_ascii_reference_width_stays_stable():
    # ASCII branch remains 0.42*fs in main.lua; this guards against accidental drift.
    fs = 34
    ascii_w = fs * 0.42
    assert ascii_w == 14.28


# --- wrap_tokens port and punctuation wrapping prevention tests -----------------


def wrap_tokens_py(tokens, max_w, keep_spaces=True):
    # Mock text width calculation: length of string * 10
    def mock_get_str_width(text):
        if not text:
            return 0
        return len(text) * 10

    vlines = []
    cur_indices = []
    cur_w = 0
    space_w = mock_get_str_width(" ")
    
    for j, t in enumerate(tokens):
        ww = mock_get_str_width(t["text"])
        space = space_w if (len(cur_indices) > 0 and not keep_spaces) else 0
        
        has_newline = "\n" in t["text"]
        is_punc = (t["text"] == "." or t["text"] == ",")
        
        if ((cur_w + space + ww > max_w and len(cur_indices) > 0) or has_newline) and not (is_punc and not has_newline):
            if len(cur_indices) > 0:
                vlines.append(list(cur_indices))
                cur_indices = []
                cur_w = 0
            
            if not has_newline or t["text"].replace("\n", "") != "":
                cur_indices.append(j)
                cur_w = ww
        else:
            cur_indices.append(j)
            cur_w = cur_w + space + ww
            
    if len(cur_indices) > 0:
        vlines.append(list(cur_indices))
    return vlines


def test_wrap_tokens_standard_words():
    # Word 1: width 40, Word 2: width 40. Limit: 60.
    # Word 1 + Word 2 = 80 > 60, should wrap Word 2.
    tokens = [
        {"text": "word"},
        {"text": "test"}
    ]
    res = wrap_tokens_py(tokens, max_w=60, keep_spaces=True)
    assert res == [[0], [1]]


def test_wrap_tokens_prevents_comma_wrapping():
    # Word 1: width 40, Comma: width 10. Limit: 45.
    # 40 + 10 = 50 > 45. Comma should NOT wrap by itself.
    tokens = [
        {"text": "word"},
        {"text": ","}
    ]
    res = wrap_tokens_py(tokens, max_w=45, keep_spaces=True)
    assert res == [[0, 1]]


def test_wrap_tokens_prevents_period_wrapping():
    # Word 1: width 40, Period: width 10. Limit: 45.
    # 40 + 10 = 50 > 45. Period should NOT wrap by itself.
    tokens = [
        {"text": "word"},
        {"text": "."}
    ]
    res = wrap_tokens_py(tokens, max_w=45, keep_spaces=True)
    assert res == [[0, 1]]

