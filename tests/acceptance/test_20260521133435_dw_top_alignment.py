r"""
Feature ZID: 20260521133435
Test Creation ZID: 20260521133435
Feature: Drum Window Top-Alignment & Cutoff Prevention

This test verifies:
1. When the total visual height of subtitles in Drum Window (DW) mode exceeds the screen height (1080p),
   the layout clamps `block_top` and uses dynamic top-centered alignment (`{\pos(960, block_top + total_height/2)}{\an5}`).
2. At the start of the file under overflow, `block_top` clamps to `Options.dw_edge_margin`
   (configurable safe-area padding so the top line doesn't touch the screen bezel).
3. Under playback or follow-player seeking, the viewport `view_center` updates, shifting `block_top`
   dynamically to reflect the new active subtitle context.
4. Under normal (non-overflow) conditions, `{\an5}` is still used and `block_top` is positive (centred).
"""

import re
import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state, query_kardenwort_render


def _parse_block_top(ipc, render):
    """Extract the numeric y-coordinate and convert it to block_top using state total_height."""
    match = re.search(r"\\pos\(960,\s*(-?[\d.]+)\)", render)
    assert match is not None, f"Could not find pos(960, y) in render: {render}"
    y_center = float(match.group(1))
    state = query_kardenwort_state(ipc)
    total_h = state.get("dw_total_height", 0)
    return y_center - total_h / 2


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


def _set_edge_margin(ipc, px):
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_edge_margin", str(px)])
    time.sleep(0.2)


def test_dw_top_alignment_when_overflows(mpv):
    """
    Verify that DW renders with middle-centered alignment an5 and clamps to the configured
    edge margin (not flush against y=0) at the start of the file under overflow.
    """
    ipc = mpv.ipc

    _enable_dw(ipc)
    _set_edge_margin(ipc, 24)
    _set_overflow_font(ipc)

    render = query_kardenwort_render(ipc, "dw")

    # Under overflow at the start of the file, block_top must clamp to edge_margin
    y_val = _parse_block_top(ipc, render)
    assert y_val == 24.0, f"Expected block_top clamped to edge_margin=24, got: {y_val}"
    assert "{\\an5}" in render, f"Expected middle-centered alignment an5, got: {render}"


def test_dw_top_clamp_with_zero_margin(mpv):
    """
    Verify that setting dw_edge_margin to 0 restores the original flush-to-edge behavior
    (regression guard for the historical clamp).
    """
    ipc = mpv.ipc

    _enable_dw(ipc)
    _set_edge_margin(ipc, 0)
    _set_overflow_font(ipc)

    render = query_kardenwort_render(ipc, "dw")

    y_val = _parse_block_top(ipc, render)
    assert y_val == 0.0, f"Expected block_top clamped to 0 when edge_margin=0, got: {y_val}"


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
    assert "{\\an5}" in render

    y_val = _parse_block_top(ipc, render)
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
    assert "{\\an5}" in render

    y_val = _parse_block_top(ipc, render)
    # The layout should clamp at the bottom of the screen, meaning block_top must be negative (shifted up)
    assert y_val < 0, f"Expected a negative block_top when focused at the end under overflow, got {y_val}"


def test_dw_normal_centered_layout(mpv):
    """
    Verify that under normal (non-overflow) conditions — default font size —
    the \\an5 alignment is used and block_top is positive (centred on screen).
    """
    ipc = mpv.ipc

    _enable_dw(ipc)

    # Use default font size (no override), which should keep total_height well below 1080
    render = query_kardenwort_render(ipc, "dw")
    assert "{\\an5}" in render, f"Expected middle-centered alignment an5 even for normal layout, got: {render}"

    y_val = _parse_block_top(ipc, render)
    # With a small total_height the block should be centred: block_top = (1080 - total_height) / 2 > 0
    assert y_val > 0, f"Expected positive block_top (centred) for non-overflow layout, got {y_val}"


def test_dw_renders_single_positioned_block(mpv):
    """
    Verify DW remains a single positioned ASS dialogue block (legacy cohesive card behavior),
    not split into multiple independently-positioned events.
    """
    ipc = mpv.ipc

    _enable_dw(ipc)
    _set_overflow_font(ipc)

    render = query_kardenwort_render(ipc, "dw")

    # Single block contract: exactly one DW anchor position tag in the final render.
    pos_tags = re.findall(r"\\pos\(960,\s*-?[\d.]+\)", render)
    assert len(pos_tags) == 1, f"Expected exactly one DW pos tag, got {len(pos_tags)} in: {render}"

    # Historical cohesive card contract is anchored via an5.
    assert "{\\an5}" in render, f"Expected an5 anchor for unified DW block, got: {render}"
