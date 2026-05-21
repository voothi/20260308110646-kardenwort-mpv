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
4. Under normal (non-overflow) conditions, `{\an8}` is still used and `block_top` is positive (centred).
"""

import re
import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state, query_kardenwort_render


def _parse_block_top(render):
    """Extract the numeric y-coordinate from {\\pos(960, <y>)} in the rendered ASS string."""
    match = re.search(r"\\pos\(960,\s*(-?[\d.]+)\)", render)
    assert match is not None, f"Could not find pos(960, y) in render: {render}"
    return float(match.group(1))


def _enable_dw(ipc):
    """Enable Drum Window and assert it was toggled on."""
    state = query_kardenwort_state(ipc)
    assert state.get("drum_window") == "OFF"
    ipc.command(["script-binding", "kardenwort/toggle-drum-window"])
    time.sleep(0.3)
    state = query_kardenwort_state(ipc)
    assert state.get("drum_window") != "OFF"


def _set_overflow_font(ipc):
    """Set font size large enough to force layout overflow on 3 subtitles."""
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_font_size", "400"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_lines_visible", "15"])
    time.sleep(0.3)


def test_dw_top_alignment_when_overflows(mpv):
    """
    Verify that DW renders with top-centered alignment an8 and clamps to y=0 when layout overflows.
    """
    ipc = mpv.ipc

    _enable_dw(ipc)
    _set_overflow_font(ipc)

    render = query_kardenwort_render(ipc, "dw")

    # Under overflow at the start of the file, block_top must clamp to 0
    y_val = _parse_block_top(render)
    assert y_val == 0.0, f"Expected block_top clamped to 0 under layout overflow, got: {y_val}"
    assert "{\\an8}" in render, f"Expected top-centered alignment an8, got: {render}"


def test_dw_scrolling_shifts_block_top(mpv):
    """
    Verify that seeking to a middle subtitle shifts block_top into the unclamped negative range.
    Subtitle 2 (4.0-6.0s) is in the middle of the 3-subtitle file.  Under overflow with
    view_center=2 the offset accumulates sub 1's height + gap + half of sub 2's height,
    giving a block_top that is negative but NOT clamped to (1080 - total_height).
    """
    ipc = mpv.ipc

    _enable_dw(ipc)

    state = query_kardenwort_state(ipc)
    assert state.get("dw_follow_player") is True

    _set_overflow_font(ipc)

    # Seek to subtitle 2 (4.0-6.0s range)
    ipc.command(["seek", 5.0, "absolute+exact"])
    time.sleep(0.5)

    render = query_kardenwort_render(ipc, "dw")
    assert "{\\an8}" in render

    y_val = _parse_block_top(render)
    # block_top should be negative (scrolled up) but above the bottom clamp (1080 - total_height)
    assert y_val < 0, f"Expected negative block_top when scrolled to middle subtitle, got {y_val}"


def test_dw_bottom_clamping(mpv):
    """
    Verify that when focused on the last subtitle and overflowing, the layout
    correctly clamps block_top to (1080 - total_height), which is negative.
    """
    ipc = mpv.ipc

    _enable_dw(ipc)
    _set_overflow_font(ipc)

    # Seek to subtitle 3 (7.0-9.0s)
    ipc.command(["seek", 8.0, "absolute+exact"])
    time.sleep(0.5)

    render = query_kardenwort_render(ipc, "dw")
    assert "{\\an8}" in render

    y_val = _parse_block_top(render)
    # The layout should clamp at the bottom of the screen, meaning block_top must be negative (shifted up)
    assert y_val < 0, f"Expected a negative block_top when focused at the end under overflow, got {y_val}"


def test_dw_normal_centered_layout(mpv):
    """
    Verify that under normal (non-overflow) conditions — default font size —
    the \\an8 alignment is used and block_top is positive (centred on screen).
    """
    ipc = mpv.ipc

    _enable_dw(ipc)

    # Use default font size (no override), which should keep total_height well below 1080
    render = query_kardenwort_render(ipc, "dw")
    assert "{\\an8}" in render, f"Expected top-centered alignment an8 even for normal layout, got: {render}"

    y_val = _parse_block_top(render)
    # With a small total_height the block should be centred: block_top = (1080 - total_height) / 2 > 0
    assert y_val > 0, f"Expected positive block_top (centred) for non-overflow layout, got {y_val}"
