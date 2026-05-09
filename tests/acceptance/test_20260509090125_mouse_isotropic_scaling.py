"""
Feature ZID: 20260509090125
Test Creation ZID: 20260509091431
Feature: Mouse Isotropic Scaling
"""

import pytest
import time
import json

def wait_for_export(mpv, timeout=2.0):
    start = time.time()
    while time.time() - start < timeout:
        val = mpv.ipc.get_property("user-data/lls/last_export")
        if val and val != "":
            return json.loads(val)
        time.sleep(0.05)
    raise TimeoutError("Timed out waiting for last_export")

@pytest.mark.acceptance
def test_mouse_isotropic_scaling(mpv):
    """Verify that mouse coordinates are scaled isotropically based on height."""
    # 1. 1920x1080 (16:9)
    # Center click (960, 540) should map to (960, 540)
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-mouse-logic", "960", "540", "1920", "1080"])
    res = wait_for_export(mpv)
    assert abs(res['osd_x'] - 960) < 0.1
    assert abs(res['osd_y'] - 540) < 0.1

    # 2. 1080x1080 (1:1)
    # Center click (540, 540) should still map to (960, 540)
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-mouse-logic", "540", "540", "1080", "1080"])
    res = wait_for_export(mpv)
    assert abs(res['osd_x'] - 960) < 0.1
    assert abs(res['osd_y'] - 540) < 0.1
    
    # 3. 2160x1080 (2:1) - ultrawide
    # Center click (1080, 540) should map to (960, 540)
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-mouse-logic", "1080", "540", "2160", "1080"])
    res = wait_for_export(mpv)
    assert abs(res['osd_x'] - 960) < 0.1
    assert abs(res['osd_y'] - 540) < 0.1

@pytest.mark.acceptance
def test_drum_window_hit_test(mpv):
    """Verify hit-zone mapping in Drum Window mode."""
    # Enable Drum Window
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-set-option", "dw_lines_visible", "5"])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-set-option", "dw_pri_interactivity", "true"])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-drum-window-toggle"])
    
    # Set view center to line 2 ("This is a test")
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-set-cursor", "2", "1"])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-set-option", "dw_view_center", "2"])
    
    # Center of OSD (960, 540) should hit the center of the block.
    # Since view_center is 2, and we have 3 subs total, the block will be:
    # Line 1
    # Line 2 (center)
    # Line 3
    
    mpv.ipc.command(["set_property", "user-data/lls/last_export", ""])
    mpv.ipc.command(["script-message-to", "lls_core", "lls-test-mouse-logic", "960", "540", "1920", "1080"])
    res = wait_for_export(mpv)
    
    # Should hit line 2
    assert res['line'] == 2
    # word should be in the range [1, 4] (covering "This is a test")
    assert 1 <= res['word'] <= 4
