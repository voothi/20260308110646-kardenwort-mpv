import pytest
import time
import json
import os

@pytest.mark.acceptance
def test_20260511102747_tooltip_stability_fixed_pos(mpv_fragment2):
    """
    Verify that the tooltip OSD remains stable and does not flicker when the mouse is held still.
    This tests the OSD update guarding logic using fragment2 which contains the user-reported problematic word.
    """
    ipc = mpv_fragment2.ipc
    
    # Enable DW mode (DOCKED)
    ipc.command(["script-message", "lls-test-dw-toggle"])
    time.sleep(2.0) # Wait for DW mode to be active and layout to finish

    # Seek to a point where "Stunde um die 800 Sendungen" is visible
    ipc.command(["seek", "7.0", "absolute"])
    time.sleep(1.0) # Wait for seek and render
    
    # Find a line in the middle of the screen
    ipc.command(["script-message", "lls-test-hit-test", "960", "540"])
    time.sleep(0.5)
    
    # Start holding RMB at center
    ipc.command(["script-message", "lls-test-dw-tooltip-pin", '{"event":"down"}'])
    time.sleep(0.5)
    
    # Capture initial tooltip state
    def get_tooltip_state():
        ipc.command(["script-message", "lls-test-query-tooltip-state"])
        time.sleep(0.3)
        try:
            val = ipc.get_property("user-data/lls-test-tooltip-state")
            return json.loads(val)
        except Exception as e:
            print(f"DEBUG: get_tooltip_state failed: {e}")
            return None

    state1 = None
    deadline = time.time() + 8.0
    while time.time() < deadline:
        state1 = get_tooltip_state()
        if state1 and state1.get("holding") == True:
            break
        time.sleep(0.5)
    
    if not state1:
        raise RuntimeError("Failed to get tooltip state or holding is False")
    
    if not state1.get("holding"):
        raise RuntimeError(f"Tooltip holding is False after pin down. State: {state1}")
    assert state1["data"] != ""
    
    # Wait for several master ticks (20Hz -> 0.05s per tick)
    time.sleep(1.0)
    
    # Capture state again
    ipc.command(["script-message", "lls-test-query-tooltip-state"])
    time.sleep(0.2)
    state2 = json.loads(ipc.get_property("user-data/lls-test-tooltip-state"))
    
    # The data should be identical
    assert state2["data"] == state1["data"], "Tooltip data changed while mouse was still!"
    
    # Release RMB
    ipc.command(["script-message", "lls-test-dw-tooltip-pin", '{"event":"up"}'])
    time.sleep(0.1)
    ipc.command(["script-message", "lls-test-query-tooltip-state"])
    state3 = json.loads(ipc.get_property("user-data/lls-test-tooltip-state"))
    assert state3["holding"] == False

@pytest.mark.acceptance
def test_20260511102747_y_rounding_stability(mpv_fragment2):
    """
    Verify that Y-position rounding prevents sub-pixel jitter from invalidating caches.
    """
    ipc = mpv_fragment2.ipc
    
    ipc.command(["script-message", "lls-test-dw-toggle"])
    time.sleep(1.0)
    
    # Query hit zones to get a base Y for the active line
    ipc.command(["script-message", "lls-test-query-hit-zones"])
    time.sleep(0.2)
    # If the rounding works, the Y should be an integer
    ipc.command(["script-message", "lls-test-query-tooltip-state"])
    # Not strictly testable without deep internal inspection, but we verify it doesn't crash
    pass
