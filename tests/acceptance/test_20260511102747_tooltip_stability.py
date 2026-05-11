import pytest
import time
import json
from tests.ipc.mpv_ipc import query_lls_state

"""
Feature ZID: 20260511102747
Test Creation ZID: 20260511115438
Feature: Cross-mode tooltip hold stability
Ensures hold-hover tooltip behavior is stable in both DRUM_WINDOW=OFF (drum mode)
and DRUM_WINDOW=DOCKED (dw mode).
"""


def _query_tooltip_state(ipc):
    ipc.command(["script-message", "lls-test-query-tooltip-state"])
    time.sleep(0.2)
    raw = ipc.get_property("user-data/lls-test-tooltip-state")
    return json.loads(raw) if raw else {}


def _assert_stable_hold_payload(ipc, x, y, samples=5):
    ipc.command(["script-message", "lls-test-dw-tooltip-pin-at", str(x), str(y), '{"event":"down"}'])
    time.sleep(0.5)
    first = _query_tooltip_state(ipc)
    assert first.get("holding") is True, f"Expected holding=True after down, got: {first}"
    payloads = [first.get("data", "")]
    for _ in range(samples - 1):
        time.sleep(0.2)
        payloads.append(_query_tooltip_state(ipc).get("data", ""))
    ipc.command(["script-message", "lls-test-dw-tooltip-pin-at", str(x), str(y), '{"event":"up"}'])
    time.sleep(0.1)
    released = _query_tooltip_state(ipc)
    assert released.get("holding") is False, f"Expected holding=False after up, got: {released}"
    assert payloads[0] != "", "Tooltip was not rendered during hold"
    assert len(set(payloads)) == 1, f"Tooltip payload changed during hold: {len(set(payloads))} variants"


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
    Verify rounded Y is stable enough to keep tooltip ASS output deterministic.
    """
    ipc = mpv_fragment2.ipc
    
    ipc.command(["script-message", "lls-test-dw-toggle"])
    time.sleep(2.0)
    ipc.command(["seek", "7.0", "absolute"])
    time.sleep(1.0)

    # Pin tooltip once and ensure subsequent polls return identical serialized ASS payload.
    ipc.command(["script-message", "lls-test-dw-tooltip-pin", '{"event":"down"}'])
    time.sleep(0.5)

    snapshots = []
    for _ in range(5):
        ipc.command(["script-message", "lls-test-query-tooltip-state"])
        time.sleep(0.2)
        state = json.loads(ipc.get_property("user-data/lls-test-tooltip-state"))
        snapshots.append(state.get("data", ""))

    ipc.command(["script-message", "lls-test-dw-tooltip-pin", '{"event":"up"}'])

    assert snapshots[0] != "", "Tooltip was not rendered for stability sampling"
    assert len(set(snapshots)) == 1, "Tooltip ASS payload changed across stable samples"


@pytest.mark.acceptance
def test_20260511115438_cross_mode_hold_hover_stability(mpv_fragment2):
    """
    Regression test: hold-hover tooltip must remain stable in both drum and dw modes.
    """
    ipc = mpv_fragment2.ipc

    ipc.command(["seek", "7.0", "absolute"])
    time.sleep(1.0)

    # Mode A: drum (DRUM_WINDOW=OFF, DRUM=ON)
    ipc.command(["script-message-to", "lls_core", "lls-drum-mode-set", "ON"])
    time.sleep(0.5)
    x, y = _pick_hit_zone_center(ipc)
    _assert_stable_hold_payload(ipc, x, y)

    # Mode B: dw (DRUM_WINDOW=DOCKED)
    ipc.command(["script-message-to", "lls_core", "lls-drum-mode-set", "OFF"])
    time.sleep(0.3)
    ipc.command(["script-message", "lls-test-dw-toggle"])
    time.sleep(1.0)
    x, y = _pick_hit_zone_center(ipc)
    _assert_stable_hold_payload(ipc, x, y)
def _pick_hit_zone_center(ipc):
    ipc.command(["script-message", "lls-test-query-hit-zones"])
    time.sleep(0.2)
    state = query_lls_state(ipc)
    zones = state.get("test_data", {}).get("drum_hit_zones", [])
    assert zones, "No drum hit-zones available"
    z = zones[0]
    x = z["x_start"] + (z["total_width"] / 2.0)
    y = (z["y_top"] + z["y_bottom"]) / 2.0
    return x, y
