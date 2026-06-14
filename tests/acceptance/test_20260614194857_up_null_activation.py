"""
Feature ZID: 20260614194857
Test Creation ZID: 20260614194857
Feature: UP arrow null cursor activation from the middle of subtitle
"""

import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state

@pytest.mark.acceptance
def test_20260614194857_up_null_activation_paused(mpv_fragment1):
    ipc = mpv_fragment1.ipc

    # Ensure drum window is ON
    ipc.command(["script-message-to", "kardenwort", "test-dw-toggle"])
    time.sleep(0.2)

    # Seek to 12.0 seconds where subtitle 3 is active
    ipc.command(["seek", 12.0, "absolute+exact"])
    time.sleep(0.3)

    state = query_kardenwort_state(ipc)
    assert int(state["active_sub_index"]) == 3
    assert int(state["dw_cursor"]["word"]) == -1

    # Paused test
    ipc.command(["script-message-to", "kardenwort", "test-dw-key", "UP"])
    time.sleep(0.1)

    state = query_kardenwort_state(ipc)
    assert int(state["dw_cursor"]["word"]) != -1
    # Under new logic, UP always enters from middle, so cursor word should be 3
    assert int(state["dw_cursor"]["word"]) == 3

@pytest.mark.acceptance
def test_20260614194857_up_null_activation_playing(mpv_fragment1):
    ipc = mpv_fragment1.ipc

    # Ensure drum window is ON
    ipc.command(["script-message-to", "kardenwort", "test-dw-toggle"])
    time.sleep(0.2)

    # Seek to 12.0 seconds where subtitle 3 is active
    ipc.command(["seek", 12.0, "absolute+exact"])
    time.sleep(0.3)

    # Resume playback
    ipc.command(["set_property", "pause", False])
    time.sleep(0.1)

    state = query_kardenwort_state(ipc)
    assert int(state["active_sub_index"]) == 3
    assert int(state["dw_cursor"]["word"]) == -1

    # Playing test
    ipc.command(["script-message-to", "kardenwort", "test-dw-key", "UP"])
    time.sleep(0.1)

    state = query_kardenwort_state(ipc)
    assert int(state["dw_cursor"]["word"]) != -1
    assert int(state["dw_cursor"]["word"]) == 3
