r"""
Feature ZID: 20260521133435
Test Creation ZID: 20260521133435
Feature: Drum Window Top-Alignment & Cutoff Prevention

This test verifies:
1. When the total visual height of subtitles in Drum Window (DW) mode exceeds the screen height (1080p),
   the layout successfully clamps `block_top` and utilizes dynamic top-centered alignment (`{\pos(960, block_top)}{\an8}`).
2. Specifically, at the start of the file, `block_top` clamps to `0`, placing the top of the subtitle block
   exactly at the top of the screen (`{\pos(960, 0.000000)}{\an8}` or similar).
3. Under playback or follow-player seeking, the viewport `view_center` updates, shifting `block_top`
   dynamically to reflect the new active subtitle context.
"""

import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state, query_kardenwort_render


def test_dw_top_alignment_when_overflows(mpv):
    """
    Verify that DW renders with top-centered alignment an8 and clamps to y=0 when layout overflows.
    """
    ipc = mpv.ipc

    # 1. Enable Drum Window (z)
    state = query_kardenwort_state(ipc)
    assert state.get("drum_window") == "OFF"
    
    ipc.command(["script-binding", "kardenwort/toggle-drum-window"])
    time.sleep(0.3)
    state = query_kardenwort_state(ipc)
    assert state.get("drum_window") != "OFF"

    # 2. Set an extremely large font size (e.g. 400) to force total layout height (even with 3 subtitles)
    # to exceed 1080 pixels (each subtitle height will be ~400 * 1.35 = 540 pixels, total > 1620)
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_font_size", "400"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_lines_visible", "15"])
    time.sleep(0.3)

    # 3. Query the rendered OSD text for the drum window
    render = query_kardenwort_render(ipc, "dw")
    
    # Under overflow at the start of the file, block_top must clamp to 0
    # Thus, the generated OSD string must contain {\pos(960, 0)} (or 0.0, etc.) and {\an8}
    assert "{\\pos(960, 0" in render or "{\\pos(960, -0" in render or "pos(960, 0" in render, f"Expected pos(960, 0) under layout overflow, got: {render}"
    assert "{\\an8}" in render, f"Expected top-centered alignment an8, got: {render}"


def test_dw_scrolling_shifts_block_top(mpv):
    """
    Verify that seeking/playback with follow player active shifts block_top dynamically.
    """
    ipc = mpv.ipc

    # Ensure fully booted
    state = query_kardenwort_state(ipc)
    assert state.get("drum_window") == "OFF"

    # 1. Enable Drum Window
    ipc.command(["script-binding", "kardenwort/toggle-drum-window"])
    time.sleep(0.3)

    # Keep follow player to ON (default) so seeking to subtitle 3 updates view_center
    state = query_kardenwort_state(ipc)
    assert state.get("dw_follow_player") is True

    # 2. Set large font size to overflow layout
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_font_size", "400"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_lines_visible", "15"])
    time.sleep(0.3)

    # Seek video/active subtitle to subtitle 3 (7.0s - 9.0s range, e.g., 8.0s)
    ipc.command(["seek", 8.0, "absolute+exact"])
    time.sleep(0.5)

    render = query_kardenwort_render(ipc, "dw")

    # Due to follow-player shifting focus to subtitle 3, block_top should have shifted upwards off-screen (negative value)
    # The alignment should still be top-centered {\an8}
    assert "{\\an8}" in render
    assert "{\\pos(960, 0)}" not in render and "{\\pos(960, 0.0)}" not in render, f"Block top should have scrolled and shifted away from 0, got: {render}"


def test_dw_bottom_clamping(mpv):
    """
    Verify that when focused on the last subtitle and overflowing, the layout
    correctly clamps block_top to the bottom of the screen (negative value representing 1080 - total_height).
    """
    import re
    ipc = mpv.ipc

    # Ensure fully booted
    state = query_kardenwort_state(ipc)
    assert state.get("drum_window") == "OFF"

    # 1. Enable Drum Window
    ipc.command(["script-binding", "kardenwort/toggle-drum-window"])
    time.sleep(0.3)

    # 2. Set large font size to overflow layout
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_font_size", "400"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_lines_visible", "15"])
    time.sleep(0.3)

    # 3. Seek to subtitle 3 (at 8.0s)
    ipc.command(["seek", 8.0, "absolute+exact"])
    time.sleep(0.5)

    render = query_kardenwort_render(ipc, "dw")
    assert "{\\an8}" in render

    # Parse block_top from {\pos(960, block_top)}
    match = re.search(r"\\pos\(960,\s*(-?[\d.]+)\)", render)
    assert match is not None, f"Could not find pos(960, y) in render: {render}"
    y_val = float(match.group(1))

    # The layout should clamp at the bottom of the screen, meaning block_top must be negative (shifted up)
    assert y_val < 0, f"Expected a negative block_top when focused at the end under overflow, got {y_val}"


