"""
Feature ZID: 20260518225213
Test Creation ZID: 20260518225213
Feature: Configurable post-transition selection policy

Validates that Enter transition behavior is configurable via:
  kardenwort-dw_clear_selection_after_transition
and respects DW Esc mode follow policy.
"""

import time
from tests.ipc.mpv_ipc import query_kardenwort_state


def _press_enter_seek(ipc):
    # Default dw_key_seek is "ENTER KP_ENTER", resulting in numbered bindings.
    ipc.command(["script-binding", "kardenwort/dw-seek-1"])


def _double_click_line(ipc, line):
    ipc.command(["script-message-to", "kardenwort", "test-dw-double-click", str(line)])


def wait_for_state(ipc, key, value, timeout=2.0):
    start = time.time()
    while time.time() - start < timeout:
        state = query_kardenwort_state(ipc)
        if state.get(key) == value:
            return True
        time.sleep(0.1)
    return False


def test_20260518225213_enter_clears_selection_and_restores_follow_in_auto_mode(mpv):
    ipc = mpv.ipc
    ipc.command(["script-message-to", "kardenwort", "drum-window-toggle"])
    time.sleep(0.3)

    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_esc_mode", "auto_follow_current"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_clear_selection_after_transition", "yes"])
    ipc.command(["script-message-to", "kardenwort", "test-set-follow-player", "false"])
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", "1", "1"])
    ipc.command(["script-message-to", "kardenwort", "test-ctrl-toggle-word", "1", "1"])
    time.sleep(0.2)

    before = query_kardenwort_state(ipc)
    assert before["dw_selection_count"] >= 1
    assert before["dw_cursor"]["word"] == 1
    assert before["dw_follow_player"] is False

    _press_enter_seek(ipc)
    time.sleep(0.3)

    after = query_kardenwort_state(ipc)
    assert after["dw_cursor"]["word"] == -1
    assert after["dw_selection_count"] == 0
    assert after["dw_follow_player"] is True
    assert after["dw_esc_neutral_armed"] is False


def test_20260518225213_enter_clears_selection_but_stays_manual_in_neutral_mode(mpv):
    ipc = mpv.ipc
    ipc.command(["script-message-to", "kardenwort", "drum-window-toggle"])
    time.sleep(0.3)

    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_esc_mode", "neutral_last_selection"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_clear_selection_after_transition", "yes"])
    ipc.command(["script-message-to", "kardenwort", "test-set-follow-player", "true"])
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", "1", "1"])
    ipc.command(["script-message-to", "kardenwort", "test-ctrl-toggle-word", "1", "1"])
    time.sleep(0.2)

    _press_enter_seek(ipc)
    time.sleep(0.3)

    after = query_kardenwort_state(ipc)
    assert after["dw_cursor"]["word"] == -1
    assert after["dw_selection_count"] == 0
    assert after["dw_follow_player"] is False
    assert after["dw_esc_neutral_armed"] is False


def test_20260518225213_enter_clears_selection_but_stays_manual_in_neutral_current_mode(mpv):
    ipc = mpv.ipc
    ipc.command(["script-message-to", "kardenwort", "drum-window-toggle"])
    time.sleep(0.3)

    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_esc_mode", "neutral_current_subtitle"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_clear_selection_after_transition", "yes"])
    ipc.command(["script-message-to", "kardenwort", "test-set-follow-player", "true"])
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", "1", "1"])
    ipc.command(["script-message-to", "kardenwort", "test-ctrl-toggle-word", "1", "1"])
    time.sleep(0.2)

    _press_enter_seek(ipc)
    time.sleep(0.3)

    after = query_kardenwort_state(ipc)
    assert after["dw_cursor"]["word"] == -1
    assert after["dw_selection_count"] == 0
    assert after["dw_follow_player"] is False
    assert after["dw_esc_neutral_armed"] is False


def test_20260518225213_enter_preserves_selection_when_option_disabled(mpv):
    ipc = mpv.ipc
    ipc.command(["script-message-to", "kardenwort", "drum-window-toggle"])
    time.sleep(0.3)

    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_esc_mode", "auto_follow_current"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_clear_selection_after_transition", "no"])
    ipc.command(["script-message-to", "kardenwort", "test-set-follow-player", "false"])
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", "1", "1"])
    time.sleep(0.2)

    _press_enter_seek(ipc)
    time.sleep(0.3)

    after = query_kardenwort_state(ipc)
    assert after["dw_cursor"]["word"] == 1
    assert after["dw_selection_count"] == 0
    assert after["dw_follow_player"] is False
    assert after["dw_esc_neutral_armed"] is False

    # Esc clears pointer and should restore follow in auto mode.
    ipc.command(["script-message-to", "kardenwort", "test-dw-esc"])
    time.sleep(0.2)
    after_esc = query_kardenwort_state(ipc)
    assert after_esc["dw_cursor"]["word"] == -1
    assert after_esc["dw_follow_player"] is True


def test_20260518225213_double_click_clears_selection_and_restores_follow_in_auto_mode(mpv):
    ipc = mpv.ipc
    ipc.command(["script-message-to", "kardenwort", "drum-window-toggle"])
    time.sleep(0.3)

    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_esc_mode", "auto_follow_current"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_clear_selection_after_transition", "yes"])
    ipc.command(["script-message-to", "kardenwort", "test-set-follow-player", "false"])
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", "1", "1"])
    ipc.command(["script-message-to", "kardenwort", "test-ctrl-toggle-word", "1", "1"])
    time.sleep(0.2)

    _double_click_line(ipc, 2)
    assert wait_for_state(ipc, "active_sub_index", 2, timeout=2.0)

    after = query_kardenwort_state(ipc)
    assert after["dw_cursor"]["word"] == -1
    assert after["dw_selection_count"] == 0
    assert after["dw_follow_player"] is True
    assert after["dw_esc_neutral_armed"] is False


def test_20260518225213_enter_clear_yes_restores_follow_in_book_mode_auto_mode(mpv):
    ipc = mpv.ipc
    ipc.command(["script-message-to", "kardenwort", "drum-window-toggle"])
    time.sleep(0.3)

    ipc.command(["script-message-to", "kardenwort", "test-set-option", "book_mode", "yes"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_esc_mode", "auto_follow_current"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_clear_selection_after_transition", "yes"])
    ipc.command(["script-message-to", "kardenwort", "test-set-follow-player", "true"])
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", "1", "1"])
    ipc.command(["script-message-to", "kardenwort", "test-ctrl-toggle-word", "1", "1"])
    time.sleep(0.2)

    _press_enter_seek(ipc)
    time.sleep(0.3)

    after = query_kardenwort_state(ipc)
    assert after["dw_cursor"]["word"] == -1
    assert after["dw_selection_count"] == 0
    # Enter transition in auto mode explicitly resumes follow.
    assert after["dw_follow_player"] is True
    assert after["dw_esc_neutral_armed"] is False


def test_20260518225213_double_click_clear_yes_restores_follow_in_book_mode_auto_mode(mpv):
    ipc = mpv.ipc
    ipc.command(["script-message-to", "kardenwort", "drum-window-toggle"])
    time.sleep(0.3)

    ipc.command(["script-message-to", "kardenwort", "test-set-option", "book_mode", "yes"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_esc_mode", "auto_follow_current"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_clear_selection_after_transition", "yes"])
    ipc.command(["script-message-to", "kardenwort", "test-set-follow-player", "false"])
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", "1", "1"])
    ipc.command(["script-message-to", "kardenwort", "test-ctrl-toggle-word", "1", "1"])
    time.sleep(0.2)

    _double_click_line(ipc, 2)
    assert wait_for_state(ipc, "active_sub_index", 2, timeout=2.0)

    after = query_kardenwort_state(ipc)
    assert after["dw_cursor"]["word"] == -1
    assert after["dw_selection_count"] == 0
    assert after["dw_follow_player"] is True
    assert after["dw_esc_neutral_armed"] is False


def test_20260518225213_double_click_preserves_pointer_keeps_manual_until_esc(mpv):
    ipc = mpv.ipc
    ipc.command(["script-message-to", "kardenwort", "drum-window-toggle"])
    time.sleep(0.3)

    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_esc_mode", "auto_follow_current"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_clear_selection_after_transition", "no"])
    ipc.command(["script-message-to", "kardenwort", "test-set-follow-player", "true"])
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", "1", "1"])
    time.sleep(0.2)

    _double_click_line(ipc, 2)
    assert wait_for_state(ipc, "active_sub_index", 2, timeout=2.0)
    after = query_kardenwort_state(ipc)
    assert after["dw_cursor"]["word"] == 1
    assert after["dw_follow_player"] is False

    ipc.command(["script-message-to", "kardenwort", "test-dw-esc"])
    time.sleep(0.2)
    after_esc = query_kardenwort_state(ipc)
    assert after_esc["dw_cursor"]["word"] == -1
    assert after_esc["dw_follow_player"] is True
