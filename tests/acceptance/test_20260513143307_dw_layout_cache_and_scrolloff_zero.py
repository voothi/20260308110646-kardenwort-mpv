"""
Feature ZID: 20260513143307
Test Creation ZID: 20260513143307
Feature: DW layout cache compatibility and scrolloff=0 stability

Regression guards for:
1) dw_build_layout() consuming partial/reduced subtitle layout cache entries.
2) zero-margin scroll behavior in tiny DM/DW viewports (no negative margin math).
"""

import time
from pathlib import Path

import pytest

from tests.ipc.mpv_ipc import query_kardenwort_state


def _read_last_run_log():
    return Path("tests/mpv_last_run.log").read_text(encoding="utf-8", errors="ignore")


def _assert_no_master_tick_crash():
    log = _read_last_run_log().lower()
    assert "master_tick crash" not in log, "master_tick crash found in mpv log"
    assert "attempt to perform arithmetic on field 'height'" not in log
    assert "attempt to index local 'entry'" not in log


@pytest.mark.acceptance
def test_20260513143307_dw_layout_cache_partial_entry_does_not_crash(mpv_fragment2):
    """
    Repro path: ensure_sub_layout() can populate sub.layout_cache in a reduced shape,
    then draw_dw() / dw_build_layout() must still render without crash.
    """
    ipc = mpv_fragment2.ipc

    ipc.command(["sub-add", "tests/fixtures/20260513104740-vscode-nav.srt", "select"])
    time.sleep(0.4)
    ipc.command(["script-message-to", "kardenwort", "test-dw-toggle"])
    time.sleep(0.4)

    # Force line-nav path that uses ensure_sub_layout() and then immediately render.
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", "3", "1"])
    time.sleep(0.1)
    ipc.command(["script-message-to", "kardenwort", "test-dw-line-move", "1", "no"])
    time.sleep(0.1)
    ipc.command(["script-message-to", "kardenwort", "test-dw-line-move", "-1", "no"])
    time.sleep(0.2)

    state = query_kardenwort_state(ipc)
    assert state.get("drum_window") == "DOCKED"
    cursor = state.get("dw_cursor", {})
    assert int(cursor.get("line", -1)) >= 1

    _assert_no_master_tick_crash()


@pytest.mark.acceptance
def test_20260513143307_zero_scrolloff_tiny_viewports_stable(mpv_fragment1):
    """
    With scrolloff=0 and minimal viewport sizes, repeated scroll must remain stable.
    """
    ipc = mpv_fragment1.ipc

    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_lines_visible", "1"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "dw_scrolloff", "0"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "drum_context_lines", "0"])
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "drum_scrolloff", "0"])
    time.sleep(0.2)

    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    time.sleep(0.3)

    for _ in range(20):
        ipc.command(["script-message-to", "kardenwort", "test-dw-scroll", "1"])
    for _ in range(20):
        ipc.command(["script-message-to", "kardenwort", "test-dw-scroll", "-1"])
    time.sleep(0.3)

    state = query_kardenwort_state(ipc)
    center = int(state.get("dw_view_center", -1))
    assert center >= 1

    _assert_no_master_tick_crash()

