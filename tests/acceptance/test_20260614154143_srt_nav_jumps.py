"""
Feature ZID: 20260614154143
Test Creation ZID: 20260614154143
Feature: SRT mode navigation and manual scroll margin override stability
"""

import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state


@pytest.fixture
def mpv_long():
    from tests.ipc.mpv_session import MpvSession
    from tests.acceptance.conftest import _start_or_skip
    session = MpvSession(
        video='tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.mp4',
        subtitle='tests/fixtures/20260304233334-you-dont-need-saas/20260304233334-chapter2.1.en.srt',
        extra_args=['--pause', '--script-opts=kardenwort-companion_subtitle_attach_on_load=no'],
    )
    _start_or_skip(session)
    yield session
    session.stop()


@pytest.mark.acceptance
def test_20260614154143_srt_nav_no_jump(mpv_fragment1):
    """
    In SRT mode (FSM.DRUM == "OFF", FSM.DRUM_WINDOW == "OFF"), dw_ensure_visible
    must treat the viewport as having win_lines = 1 and margin = 0.
    Thus, when we navigate the active line, the viewport center dw_view_center
    should follow the cursor index exactly and not jump/scroll to satisfy
    outer scrolloff margins.
    """
    ipc = mpv_fragment1.ipc

    # Ensure drum window and drum mode are off (SRT mode)
    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "OFF"])
    time.sleep(0.1)
    state = query_kardenwort_state(ipc)
    assert state.get("drum_mode") == "OFF"
    assert state.get("drum_window") == "OFF"

    # Set some initial scrolloff options to non-zero to show that SRT mode ignores it
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_scrolloff", "3"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_lines_visible", "15"])
    time.sleep(0.1)

    # Let's seek to 12.0 seconds where subtitle 3 is active
    ipc.command(["seek", 12.0, "absolute+exact"])
    time.sleep(0.3)

    state = query_kardenwort_state(ipc)
    assert int(state["active_sub_index"]) == 3

    # Let's set cursor to line 3, word 1
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", "3", "1"])
    time.sleep(0.1)

    # Now, move the line down (which simulates navigating to next subtitle line 4)
    # Since we are in SRT mode, win_lines = 1, margin = 0.
    # So line_idx becomes 4, and view center should become 4 (following the cursor).
    ipc.command(["script-message-to", "kardenwort", "test-dw-line-move", "1", "no"])
    time.sleep(0.1)

    state = query_kardenwort_state(ipc)
    assert int(state["dw_cursor"]["line"]) == 4
    assert int(state["dw_view_center"]) == 4

    # Move line up back to 3
    ipc.command(["script-message-to", "kardenwort", "test-dw-line-move", "-1", "no"])
    time.sleep(0.1)

    state = query_kardenwort_state(ipc)
    assert int(state["dw_cursor"]["line"]) == 3
    assert int(state["dw_view_center"]) == 3


@pytest.mark.acceptance
def test_20260614154143_manual_scroll_margin_override(mpv_fragment1):
    """
    When the user has manually scrolled (FSM.DW_FOLLOW_PLAYER == false),
    dw_ensure_visible must set margin = 0.
    Moving the cursor within the visible viewport bounds should not force a scroll shift
    to satisfy scrolloff margins.
    """
    ipc = mpv_fragment1.ipc

    # Open the Drum Window (sets FSM.DRUM_WINDOW = "DOCKED")
    ipc.command(["script-message-to", "kardenwort", "test-dw-toggle"])
    time.sleep(0.1)
    state = query_kardenwort_state(ipc)
    assert state.get("drum_window") == "DOCKED"

    # Configure viewport: 3 lines visible, scrolloff of 1
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_lines_visible", "3"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_scrolloff", "1"])
    time.sleep(0.1)

    # Seek to 12.0 seconds where subtitle 3 is active
    ipc.command(["seek", 12.0, "absolute+exact"])
    time.sleep(0.3)

    state = query_kardenwort_state(ipc)
    assert int(state["active_sub_index"]) == 3

    # Let's set center to 3 using test-dw-scroll 0
    ipc.command(["script-message-to", "kardenwort", "test-dw-scroll", "0"])
    time.sleep(0.1)

    # Scroll by +1 to make FSM.DW_FOLLOW_PLAYER = false and FSM.DW_VIEW_CENTER = 4
    ipc.command(["script-message-to", "kardenwort", "test-dw-scroll", "1"])
    time.sleep(0.1)

    state = query_kardenwort_state(ipc)
    center = int(state["dw_view_center"])
    assert center == 4
    assert state["dw_follow_player"] is False

    # Since dw_view_center is 4 and win_lines = 3, the visible viewport is 3 to 5.
    # The margin is 1, so 3 and 5 are in the scrolloff margin.
    # Set cursor to 4
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", "4", "1"])
    time.sleep(0.1)

    # Ensure setting cursor directly didn't change view center from 4
    state = query_kardenwort_state(ipc)
    assert int(state["dw_cursor"]["line"]) == 4
    assert int(state["dw_view_center"]) == 4

    # Move cursor to 3 (within visible viewport, in margin)
    ipc.command(["script-message-to", "kardenwort", "test-dw-line-move", "-1", "no"])
    time.sleep(0.1)

    state = query_kardenwort_state(ipc)
    assert int(state["dw_cursor"]["line"]) == 3
    assert int(state["dw_view_center"]) == 4

    # Move cursor to 4 (within visible viewport)
    ipc.command(["script-message-to", "kardenwort", "test-dw-line-move", "1", "no"])
    time.sleep(0.1)

    state = query_kardenwort_state(ipc)
    assert int(state["dw_cursor"]["line"]) == 4
    assert int(state["dw_view_center"]) == 4

    # Move cursor to 5 (within visible viewport, in margin)
    ipc.command(["script-message-to", "kardenwort", "test-dw-line-move", "1", "no"])
    time.sleep(0.1)

    state = query_kardenwort_state(ipc)
    assert int(state["dw_cursor"]["line"]) == 5
    assert int(state["dw_view_center"]) == 4

    # Move cursor to 4, then to 3, then to 2 (outside visible viewport: 3..5)
    # This must scroll!
    ipc.command(["script-message-to", "kardenwort", "test-dw-line-move", "-1", "no"])
    time.sleep(0.1)
    ipc.command(["script-message-to", "kardenwort", "test-dw-line-move", "-1", "no"])
    time.sleep(0.1)
    ipc.command(["script-message-to", "kardenwort", "test-dw-line-move", "-1", "no"])
    time.sleep(0.1)

    state = query_kardenwort_state(ipc)
    assert int(state["dw_cursor"]["line"]) == 2
    # Viewport center must have scrolled to keep line 2 visible.
    # Since margin is 0, line 2 becomes the top visible line, so center = 2 + 1 = 3.
    assert int(state["dw_view_center"]) == 3
