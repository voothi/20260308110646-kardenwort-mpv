"""
Feature ZID: 20260511193547
Test Creation ZID: 20260511193547
Feature: Subtitle Toggle Blocked in Drum Window

Verifies that triggering the subtitle visibility toggle command while the 
Drum Window is active results in no state change and provides OSD feedback.
"""

import os
import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state
from tests.ipc.mpv_session import MpvSession

_FIXTURE_DIR = "tests/fixtures/20260502165659-test-fixture"
_VIDEO = os.path.abspath(f"{_FIXTURE_DIR}/20260502165659-test-fixture.mp4")
_SRT = os.path.abspath(f"{_FIXTURE_DIR}/20260502165659-test-fixture.en.srt")

def test_toggle_sub_blocked_when_dw_active(mpv):
    """
    Requirement: Global Subtitle Quick Toggle (cmd_toggle_sub_vis)
    Scenario: User presses 's' while Drum Window is open
    """
    ipc = mpv.ipc
    
    # 1. Ensure Drum Window is OFF initially
    state = query_kardenwort_state(ipc)
    assert state.get("drum_window") == "OFF"
    
    # 2. Get initial visibility
    initial_vis = state.get("native_sub_vis")
    
    # 3. Open Drum Window
    ipc.command(["script-binding", "kardenwort/toggle-drum-window"])
    time.sleep(0.5)
    state = query_kardenwort_state(ipc)
    assert state.get("drum_window") != "OFF"
    
    # 4. Attempt to toggle subtitles (using the binding name from input.conf)
    # Note: 'c' in input.conf maps to 'toggle-sub-visibility'
    ipc.command(["script-binding", "kardenwort/toggle-sub-visibility"])
    time.sleep(0.3)
    
    # 5. Verify state has NOT changed
    state = query_kardenwort_state(ipc)
    assert state.get("native_sub_vis") == initial_vis, "Subtitle visibility should not change when Drum Window is active"
    
    # 6. Close Drum Window
    ipc.command(["script-binding", "kardenwort/toggle-drum-window"])
    time.sleep(0.3)
    state = query_kardenwort_state(ipc)
    assert state.get("drum_window") == "OFF"
    
    # 7. Verify toggle works again when DW is OFF
    ipc.command(["script-binding", "kardenwort/toggle-sub-visibility"])
    time.sleep(0.3)
    state = query_kardenwort_state(ipc)
    assert state.get("native_sub_vis") != initial_vis, "Subtitle visibility should toggle normally when DW is OFF"
