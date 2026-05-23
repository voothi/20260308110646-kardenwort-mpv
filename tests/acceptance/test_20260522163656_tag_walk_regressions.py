"""
Feature ZID: 20260522163656
Test Creation ZID: 20260522163656
Feature: Tag Walk Regression Coverage v1.82.24..v1.82.26

Structural guardrails for regressions that are hard to execute in headless CI:
- Copy Mode B fallback to cached tooltip secondary subtitles.
- Copy mode cycle lock when no true secondary source exists.
- DW interactive key guards that bypass native subtitle visibility only when DW is ON.
"""

from pathlib import Path


def _lua_source() -> str:
    return Path("scripts/kardenwort/main.lua").read_text(encoding="utf-8")


def _function_window(src: str, name: str, next_hint: str, span: int = 5000) -> str:
    start = src.find(name)
    assert start != -1, f"{name} not found"
    end = src.find(next_hint, start)
    if end == -1:
        end = start + span
    return src[start:end]

def _slice_from(src: str, marker: str, span: int = 1600) -> str:
    start = src.find(marker)
    assert start != -1, f"{marker} not found"
    return src[start:start + span]


def test_cycle_copy_mode_requires_real_secondary_or_cached_secondary():
    src = _lua_source()
    body = _function_window(src, "function cmd_cycle_copy_mode()", "local function get_copy_context_text")

    assert "local has_sec =" in body
    assert "Tracks.sec.id ~= 0" in body
    assert "FSM.DW_TOOLTIP_SEC_SUBS" in body
    assert "if not has_sec then" in body
    assert "Copy Mode: Fixed to Primary (Single Track)" in body


def test_copy_context_falls_back_to_cached_secondary_subs_when_track_missing():
    src = _lua_source()
    body = _function_window(src, "function get_copy_context_text", "local function cmd_copy_sub")

    assert "local function append(path, is_ass, explicit_idx, provided_subs)" in body
    assert "if not path and not provided_subs then return end" in body
    assert "local subs = provided_subs" in body
    assert "elseif FSM.DW_TOOLTIP_SEC_SUBS and #FSM.DW_TOOLTIP_SEC_SUBS > 0 then" in body
    assert "append(nil, false, nil, FSM.DW_TOOLTIP_SEC_SUBS)" in body


def test_prepare_export_text_mode_b_falls_back_to_cached_secondary_subs():
    src = _lua_source()
    body = _function_window(src, "local function prepare_export_text(params, options)", "local function build_target_time_anchors")

    assert 'if options.copy_mode == "B" then' in body
    assert "if Tracks.sec.subs and #Tracks.sec.subs > 0 then" in body
    assert "elseif FSM.DW_TOOLTIP_SEC_SUBS and #FSM.DW_TOOLTIP_SEC_SUBS > 0 then" in body
    assert "target_subs = FSM.DW_TOOLTIP_SEC_SUBS" in body


def test_visibility_guards_allow_dw_interaction_when_dw_window_on():
    src = _lua_source()

    guards = [
        "local function cmd_dw_tooltip_pin(tbl)",
        "local function cmd_toggle_dw_tooltip_hover()",
        "local function cmd_dw_tooltip_toggle()",
        "local function cmd_dw_add_smart()",
        "local function cmd_dw_toggle_pink(tbl, was_mouse)",
        "local function cmd_toggle_anki_global()",
        "local function cmd_toggle_drum()",
        "function cmd_toggle_search()",
    ]

    for fn in guards:
        body = _slice_from(src, fn, span=1300)
        assert 'if not FSM.native_sub_vis and FSM.DRUM_WINDOW == "OFF" then' in body, (
            f"Expected DW visibility bypass guard in {fn}"
        )


def test_tick_dw_follow_mode_keeps_viewport_centered_outside_book_mode():
    src = _lua_source()
    body = _function_window(src, "local function tick_dw(time_pos, active_idx)", "local function tick_drum")

    assert "if FSM.DW_FOLLOW_PLAYER then" in body
    assert "elseif not FSM.BOOK_MODE then" in body
    assert "FSM.DW_VIEW_CENTER = active_idx" in body


def test_dw_open_without_pointer_anchors_to_active_playback_line():
    src = _lua_source()
    body = _function_window(src, "function cmd_toggle_drum_window()", "function toggle_book_mode()", span=9000)

    assert "local has_pointer =" in body
    assert "local has_range =" in body
    assert "local has_pending =" in body
    assert "if has_pointer or has_range or has_pending then" in body
    assert "FSM.DW_CURSOR_LINE = active_idx" in body
    assert "FSM.DW_VIEW_CENTER = (FSM.DW_CURSOR_LINE and FSM.DW_CURSOR_LINE ~= -1) and FSM.DW_CURSOR_LINE or active_idx" in body


def test_dw_block_top_uses_stable_frame_when_not_overflowing():
    src = _lua_source()
    body = _function_window(src, "local function dw_calculate_block_top(view_center, active_idx, layout, total_height)", "-- draw_dw")

    assert "local block_top = center_y - (total_height / 2)" in body
    assert "if total_height > base_h - 2 * edge_margin then" in body
    assert "block_top = center_y - offset_y" in body


def test_dw_mouse_drag_starts_only_after_movement_threshold():
    src = _lua_source()
    update_body = _function_window(src, "local function dw_mouse_update_selection()", "local function dw_mouse_auto_scroll")
    auto_scroll_body = _function_window(src, "local function dw_mouse_auto_scroll()", "local function cmd_dw_tooltip_pin")
    handler_body = _function_window(src, "local function make_mouse_handler(is_shift, on_up_callback, on_down_callback, updates_selection)", "local cmd_dw_mouse_select")

    assert "if not FSM.DW_MOUSE_PENDING_DRAG then return end" in update_body
    assert "local drag_threshold_px = 5" in update_body
    assert "FSM.DW_MOUSE_PENDING_DRAG = false" in update_body
    assert "FSM.DW_MOUSE_DRAGGING = true" in update_body
    assert "dw_sync_cursor_to_mouse()" in update_body

    assert "FSM.DW_MOUSE_PENDING_DRAG = true" in handler_body
    assert "FSM.DW_MOUSE_DRAGGING = false" in handler_body
    assert "FSM.DW_MOUSE_SCROLL_TIMER = mp.add_periodic_timer(0.05, dw_mouse_auto_scroll)" in handler_body

    assert "dw_mouse_update_selection()" in auto_scroll_body
    assert "if not FSM.DW_MOUSE_DRAGGING then return end" in auto_scroll_body


def test_dw_binding_builder_never_registers_nil_mouse_callback():
    src = _lua_source()
    body = _function_window(src, "manage_dw_bindings = function(enable_mouse, enable_kb)", "-- =========================================================================")

    assert "elseif key_fn then" in body
    assert "if t and t.event == \"up\" then key_fn(t, true) end" in body
    assert "and type(k.fn) == \"function\"" in body
