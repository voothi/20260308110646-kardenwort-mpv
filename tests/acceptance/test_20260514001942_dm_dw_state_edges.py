"""
Feature ZID: 20260514001942
Test Creation ZID: 20260514001942
Feature: DM/DW state edge coverage (Esc live anchor + DM Book Mode parity guards)
"""

import time

from tests.ipc.mpv_ipc import query_kardenwort_state


def _src():
    with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
        return f.read()


def _fn_body(src: str, fn_name: str) -> str:
    start = src.find(f"function {fn_name}(")
    if start == -1:
        start = src.find(f"local function {fn_name}(")
    assert start != -1, f"{fn_name} not found"
    end = src.find("\nfunction ", start + 1)
    local_end = src.find("\nlocal function ", start + 1)
    if end == -1 or (local_end != -1 and local_end < end):
        end = local_end
    return src[start:end if end != -1 else start + 8000]


def test_esc_stage3_live_anchor_structural():
    """
    Stage 3 Esc path must resolve active line from live playback time before reset.
    This guards the stale pre-boundary regression.
    """
    body = _fn_body(_src(), "cmd_dw_esc")
    assert "local live_active_idx = get_center_index(Tracks.pri.subs, time_pos)" in body
    assert "FSM.DW_ACTIVE_LINE = live_active_idx" in body
    assert "FSM.DW_FOLLOW_PLAYER = true" in body


def test_esc_stage3_resets_pointer_to_current_active_line_runtime(mpv):
    """
    Runtime guard: after Stage 3 Esc, pointer is cleared and cursor line matches active playback line.
    """
    ipc = mpv.ipc

    ipc.command(["seek", 4.5, "absolute+exact"])
    time.sleep(0.25)
    state = query_kardenwort_state(ipc)
    assert int(state["active_sub_index"]) == 2

    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", "1", "1"])
    time.sleep(0.1)
    state = query_kardenwort_state(ipc)
    assert int(state["dw_cursor"]["line"]) == 1
    assert int(state["dw_cursor"]["word"]) == 1

    ipc.command(["script-message-to", "kardenwort", "test-dw-esc"])
    time.sleep(0.15)
    state = query_kardenwort_state(ipc)

    assert int(state["dw_cursor"]["word"]) == -1
    assert int(state["dw_cursor"]["line"]) == int(state["active_sub_index"])
    assert state["dw_follow_player"] is True


def test_toggle_book_mode_keeps_dm_without_forcing_dw_runtime(mpv):
    """
    When DM is active and DW is closed, enabling Book Mode must keep DM workflow in-place.
    """
    ipc = mpv.ipc

    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    time.sleep(0.15)
    state = query_kardenwort_state(ipc)
    assert state["drum_mode"] == "ON"

    if state["drum_window"] != "OFF":
        ipc.command(["script-message-to", "kardenwort", "drum-window-toggle"])
        time.sleep(0.15)
        state = query_kardenwort_state(ipc)
    assert state["drum_window"] == "OFF"

    if state.get("book_mode") is True:
        ipc.command(["script-message-to", "kardenwort", "toggle-book-mode"])
        time.sleep(0.15)
        state = query_kardenwort_state(ipc)
    assert state.get("book_mode") is False

    ipc.command(["script-message-to", "kardenwort", "toggle-book-mode"])
    time.sleep(0.2)
    state = query_kardenwort_state(ipc)

    assert state["book_mode"] is True
    assert state["drum_mode"] == "ON"
    assert state["drum_window"] == "OFF"


def test_dm_book_mode_paging_path_structural():
    """
    Structural guard for DM mini Book Mode parity: paged ensure-visible path must exist.
    """
    body = _fn_body(_src(), "tick_drum")
    assert "FSM.BOOK_MODE" in body
    assert "dw_ensure_visible(pri_active_idx, true)" in body
    assert "pri_view_center = (is_drum and FSM.BOOK_MODE) and FSM.DW_VIEW_CENTER or pri_active_idx" in body


def test_dm_secondary_viewport_uses_primary_offset_structural():
    """
    Secondary (upper) drum track must mirror the primary viewport offset in tick_drum.
    This prevents upper-track center locking when primary is paged/scrolled.
    """
    body = _fn_body(_src(), "tick_drum")
    assert "local pri_view_center = FSM.DW_VIEW_CENTER" in body
    assert "local offset = pri_view_center - pri_active_idx" in body
    assert "view_center = math.max(1, math.min(#Tracks.sec.subs, active_idx + offset))" in body


def test_dm_secondary_viewport_not_locked_to_center_in_follow_structural():
    """
    Guard against regression where secondary view_center was forced to active_idx
    while follow mode is on (which kept upper subtitles centered).
    """
    body = _fn_body(_src(), "tick_drum")
    assert "if FSM.DW_FOLLOW_PLAYER then\n            view_center = active_idx" not in body


def test_live_activation_reanchors_before_up_down_structural():
    """
    Pointer activation via UP/DOWN must re-anchor line selection from live time-pos.
    This guards boundary-tick stale cursor line grabs during MOVIE live playback.
    """
    body = _fn_body(_src(), "cmd_dw_line_move")
    assert "local live_active_idx = get_center_index(subs, time_pos)" in body
    assert "FSM.DW_ACTIVE_LINE = live_active_idx" in body
    assert "if FSM.DW_CURSOR_WORD == -1 and FSM.DW_ANCHOR_LINE == -1 and not FSM.BOOK_MODE" in body


def test_live_activation_reanchors_before_left_right_structural():
    """
    Pointer activation via LEFT/RIGHT must use the same live re-anchor contract
    to keep behavior consistent with UP/DOWN.
    """
    body = _fn_body(_src(), "cmd_dw_word_move")
    assert "local live_active_idx = get_center_index(subs, time_pos)" in body
    assert "FSM.DW_ACTIVE_LINE = live_active_idx" in body
    assert "if FSM.DW_CURSOR_WORD == -1 and FSM.DW_ANCHOR_LINE == -1 and not FSM.BOOK_MODE" in body


def test_arrow_activation_repeat_guard_structural():
    """
    After null-pointer activation, immediate key-repeat must be guarded so a single
    physical press does not perform a second unintended movement.
    """
    src = _src()
    line_body = _fn_body(src, "cmd_dw_line_move")
    word_body = _fn_body(src, "cmd_dw_word_move")
    assert "DW_NAV_ACTIVATION_GUARD_UNTIL" in src
    assert "if type(evt) == \"table\" and evt.event == \"repeat\" and FSM.DW_NAV_ACTIVATION_GUARD_UNTIL" in line_body
    assert "if type(evt) == \"table\" and evt.event == \"repeat\" and FSM.DW_NAV_ACTIVATION_GUARD_UNTIL" in word_body
    assert "FSM.DW_NAV_ACTIVATION_GUARD_UNTIL = mp.get_time() + 0.12" in line_body
    assert "FSM.DW_NAV_ACTIVATION_GUARD_UNTIL = mp.get_time() + 0.12" in word_body
