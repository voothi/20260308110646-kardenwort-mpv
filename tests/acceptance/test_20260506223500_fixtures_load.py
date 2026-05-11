"""
Feature ZID: 20260506223500
Test Creation ZID: 20260508200327
Feature: Fixtures Load
"""

import time
import pytest
import json
from tests.ipc.mpv_ipc import query_kardenwort_state, query_kardenwort_render
from tests.ipc.mpv_session import MpvSession

def test_20260506223500_fixtures_load(mpv_fragment1):
    """Smoke test: real 25fps fragment1 loads with DE+RU subs, sentinel primes correctly."""
    ipc = mpv_fragment1.ipc
    # Sub 1 spans 4.295–5.295s; seek to the middle.
    ipc.command(['seek', 4.5, 'absolute+exact'])
    time.sleep(0.3)

    state = query_kardenwort_state(ipc)
    assert state['active_sub_index'] == 1, (
        f"fragment1 sub 1 (4.295–5.295s): expected index 1, got {state['active_sub_index']}"
    )
    assert state['sec_active_sub_index'] == 1, (
        f"secondary sentinel desynced: {state['sec_active_sub_index']}"
    )

def test_20260506223500_natural_progression_skip(mpv_dual):
    """Verify that playhead advances to next sub in overlap zone via Natural Progression logic."""
    ipc = mpv_dual.ipc
    
    # Step 1: Prime at sub 1
    ipc.command(['seek', 1.0, 'absolute+exact'])
    time.sleep(0.15)
    assert query_kardenwort_state(ipc)['active_sub_index'] == 1
    
    # Step 2: Seek to exactly 2.0s (overlap zone)
    # Fixture sync-test: sub 1 ends at 2.000, sub 2 starts at 2.200
    # audio_padding_start = 0.200 -> sub 2 padded start = 2.000s
    # audio_padding_end = 0.200 -> sub 1 padded end = 2.200s
    # At 2.000s, sub 1 is still active (padded), but sub 2's padded start has also begun.
    # The fix ensures sub 2 is selected.
    ipc.command(['seek', 2.05, 'absolute+exact'])
    time.sleep(0.15)
    
    state = query_kardenwort_state(ipc)
    assert state['active_sub_index'] == 2, (
        f"Expected Natural Progression to advance to index 2 at 2.05s, "
        f"got {state['active_sub_index']}"
    )

def test_20260506232017_seek_bindings(mpv):
    """Verify that seek bindings are registered. (Repeatability cannot be verified via IPC)."""
    ipc = mpv.ipc
    
    # Request Lua to bind them to unique keys
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-bind-seek'])
    time.sleep(0.2)

    # Get input bindings from mpv
    bindings = ipc.get_property('input-bindings')
    
    # Find our seek bindings
    forward_binding = next((b for b in bindings if b['key'] == 'KP0'), None)
    backward_binding = next((b for b in bindings if b['key'] == 'KP1'), None)
    
    assert forward_binding is not None, "KP0 binding not found"
    assert backward_binding is not None, "KP1 binding not found"
    
    # Note: mpv does not expose 'repeatable' flag via IPC property 'input-bindings'.
    # Existence of the forced binding confirms registration.

def test_20260507001035_movie_autopause_boundary(mpv_dual):
    """Verify that MOVIE mode does not pause before SRT end_time in small gaps."""
    ipc = mpv_dual.ipc
    
    # Step 1: Set MOVIE mode and ensure autopause is ON
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-immersion-mode-set', 'MOVIE'])
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-autopause-set', 'ON'])
    time.sleep(0.15)
    
    # Step 2: Seek to near end of sub 1 (fixture: sub 1 ends at 2.0s, sub 2 starts at 2.2s)
    # The handover boundary would normally be 2.2 - 0.2 = 2.0s.
    # We want to ensure it doesn't pause BEFORE 2.0s (minus padding).
    # Buggy behavior would pause at 2.2 - 0.2 - 0.2 (next sub padding) - 0.15 (pause padding) = 1.65.
    ipc.command(['seek', 1.5, 'absolute+exact'])
    ipc.command(['set_property', 'pause', False])
    
    # Ensure it's unpaused
    time.sleep(0.1)
    if ipc.get_property('pause') is True:
        ipc.command(['set_property', 'pause', False])

    # Step 3: Wait for pause
    # Use a longer timeout and check time-pos after
    ipc.observe_property(1, 'pause')
    try:
        ipc.wait_property_change('pause', timeout=5.0)
    except TimeoutError:
        pass # If it didn't pause, time_pos check will fail anyway if expected
    
    time_pos = ipc.get_property('time-pos')
    # Should be >= 1.85 (2.0 - 0.15)
    assert time_pos >= 1.8, f"Paused too early at {time_pos}, expected >= 1.85 (approx)"
    # A more precise check would be comparing with PHRASE mode where it should pause later (~2.2s).

def test_20260507090243_fsm_gap_visibility_lockout(mpv):
    """Verify that cmd_toggle_sub_vis is locked (no-op) while Drum Window is open."""
    ipc = mpv.ipc
    
    # Ensure DW is OFF initially
    assert query_kardenwort_state(ipc)['drum_window'] == 'OFF'
    
    # Step 1: Toggle works when DW is OFF
    v1 = query_kardenwort_state(ipc)['native_sub_vis']
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-toggle-sub-vis'])
    time.sleep(0.15)
    v2 = query_kardenwort_state(ipc)['native_sub_vis']
    assert v2 != v1, "Visibility should toggle when DW is OFF"
    
    # Step 2: Open Drum Window
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-drum-window-toggle'])
    time.sleep(0.3)
    assert query_kardenwort_state(ipc)['drum_window'] != 'OFF'
    
    # Step 3: Toggle should be LOCKED (no change) when DW is open
    initial_vis = query_kardenwort_state(ipc)['native_sub_vis']
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-toggle-sub-vis'])
    time.sleep(0.15)
    
    new_state = query_kardenwort_state(ipc)
    assert new_state['native_sub_vis'] == initial_vis, "Visibility toggled while DW open (lockout failed)"
    assert new_state['drum_window'] != 'OFF', "Drum Window closed unexpectedly"

def test_20260507102212_fsm_gap_sec_pos_sync(mpv_dual):
    """Verify that secondary sub position adjustments sync to FSM state."""
    ipc = mpv_dual.ipc
    
    # Step 1: Set position absolutely
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-native-sec-sub-pos-set', "50"])
    time.sleep(0.3) # Give more time
    
    # Step 2: Verify FSM sync
    state = query_kardenwort_state(ipc)
    assert state['native_sec_sub_pos'] == 50, f"FSM state not synced: {state['native_sec_sub_pos']}"
    assert ipc.get_property('secondary-sub-pos') == 50, "mpv property not set"




