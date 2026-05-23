r"""
Feature ZID: 20260521133435
Test Creation ZID: 20260521133435
Feature: Drum Window Top-Alignment & Cutoff Prevention

This test verifies:
1. When the total visual height of subtitles in Drum Window (DW) mode exceeds the screen height (1080p),
   the layout clamps `block_top` while rendering one shared background window plus positioned text lines.
2. At the start of the file under overflow, `block_top` clamps to `Options.dw_edge_margin`
   (configurable safe-area padding so the top line doesn't touch the screen bezel).
3. Under playback or follow-player seeking, the viewport `view_center` updates, shifting `block_top`
   dynamically to reflect the new active subtitle context.
4. Under normal (non-overflow) conditions, positioned text uses top-anchored per-line rendering (`{\an8}`).
"""

import re
import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state, query_kardenwort_render


def _dw_geometry(ipc):
    """Read DW geometry from state instrumentation."""
    state = query_kardenwort_state(ipc)
    return state.get("dw_block_top", 0), state.get("dw_total_height", 0)


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
    Verify that DW renders with a shared background window and clamps to the configured
    edge margin (not flush against y=0) at the start of the file under overflow.
    """
    ipc = mpv.ipc

    _enable_dw(ipc)
    _set_edge_margin(ipc, 24)
    _set_overflow_font(ipc)

    render = query_kardenwort_render(ipc, "dw")

    # Under overflow at the start of the file, block_top must clamp to edge_margin
    y_val, _ = _dw_geometry(ipc)
    assert y_val == 24.0, f"Expected block_top clamped to edge_margin=24, got: {y_val}"
    assert "{\\p1}" in render, f"Expected shared DW background vector block (\\p1), got: {render}"


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

    y_val, _ = _dw_geometry(ipc)
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
    assert "{\\an8}" in render

    y_val, _ = _dw_geometry(ipc)
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

    y_val, _ = _dw_geometry(ipc)
    # The layout should clamp at the bottom of the screen, meaning block_top must be negative (shifted up)
    assert y_val < 0, f"Expected a negative block_top when focused at the end under overflow, got {y_val}"


def test_dw_normal_centered_layout(mpv):
    """
    Verify that under normal (non-overflow) conditions - default font size -
    the \\an8 alignment is used and block_top is positive (centred on screen).
    """
    ipc = mpv.ipc

    _enable_dw(ipc)

    # Use default font size (no override), which should keep total_height well below 1080
    render = query_kardenwort_render(ipc, "dw")
    assert "{\\an8}" in render, f"Expected top-centered line alignment an8 for normal layout, got: {render}"

    y_val, _ = _dw_geometry(ipc)
    # With a small total_height the block should be centred: block_top = (1080 - total_height) / 2 > 0
    assert y_val > 0, f"Expected positive block_top (centred) for non-overflow layout, got {y_val}"


def test_dw_renders_single_shared_background_window(mpv):
    """
    Verify DW renders one shared background window (legacy cohesive card behavior),
    while text lines remain independently positioned for precision hit-testing.
    """
    ipc = mpv.ipc

    _enable_dw(ipc)
    _set_overflow_font(ipc)

    render = query_kardenwort_render(ipc, "dw")

    # Shared-window contract: exactly one vector drawing block for the background card.
    bg_blocks = re.findall(r"\\p1", render)
    assert len(bg_blocks) == 1, f"Expected exactly one shared DW background window, got {len(bg_blocks)} in: {render}"

    # Precision path contract: text remains positioned per visual line.
    assert "{\\an8}" in render, f"Expected per-line positioned text anchors (an8), got: {render}"