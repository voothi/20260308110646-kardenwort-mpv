"""
Feature ZID: 20260516204609
Test Creation ZID: 20260516205202
Feature: DW Esc Mode Cycling
"""

import time
from tests.ipc.mpv_ipc import query_kardenwort_state


def _wait_for_osd(ipc, expected, timeout=1.5):
    """Wait until mpv OSD text contains expected substring."""
    start = time.time()
    while time.time() - start < timeout:
        msg1 = ipc.get_property('osd-msg1') or ""
        msg2 = ipc.get_property('osd-msg2') or ""
        if expected in msg1 or expected in msg2:
            return True
        time.sleep(0.05)
    return False

def test_dw_esc_mode_cycling_loop(mpv_dual):
    """
    2.1 **Cycling Loop Test**: Verify that the 'n' key cycles through all 3 modes.
    2.2 **OSD Parity Test**: Verify OSD labels for each mode.
    """
    ipc = mpv_dual.ipc
    
    # Open Drum Window first as these bindings are modal
    ipc.command(['script-binding', 'kardenwort/toggle-drum-window'])
    time.sleep(0.3)
    state = query_kardenwort_state(ipc)
    assert state['drum_window'] in [True, 'DOCKED', 'FLOATING']
    
    # Modes order as defined in main.lua:
    # 1. auto_follow_current
    # 2. neutral_last_selection
    # 3. neutral_current_subtitle
    
    expected_modes = [
        ("neutral_last_selection", "DW Esc Mode: NEUTRAL LAST SELECTION"),
        ("neutral_current_subtitle", "DW Esc Mode: NEUTRAL CURRENT SUBTITLE"),
        ("auto_follow_current", "DW Esc Mode: AUTO FOLLOW CURRENT"),
    ]
    
    # Initial state should be 'auto_follow_current' (default)
    assert state['options']['dw_esc_mode'] == "auto_follow_current"
    
    for mode_id, expected_osd in expected_modes:
        # Send 'n' key directly since it's a forced binding in DW mode
        ipc.command(['keypress', 'n'])
        time.sleep(0.2)
        
        state = query_kardenwort_state(ipc)
        assert state['options']['dw_esc_mode'] == mode_id
        assert _wait_for_osd(ipc, expected_osd), f"OSD mismatch for mode {mode_id}: expected '{expected_osd}'"
        
def test_dw_esc_mode_cyrillic_parity(mpv_dual):
    """
    2.3 **Cyrillic Parity Test**: Verify that the 'т' key works as 'n'.
    """
    ipc = mpv_dual.ipc
    
    # Open Drum Window
    ipc.command(['script-binding', 'kardenwort/toggle-drum-window'])
    time.sleep(0.3)
    
    # Send 'т' key.
    # Note: We simulate the binding by triggering the command if keypress fails,
    # but here we want to verify the mapping.
    ipc.command(['keypress', 'т'])
    time.sleep(0.2)
    state = query_kardenwort_state(ipc)
    
    # Strict parity check: Cyrillic key must cycle mode by itself.
    assert state['options']['dw_esc_mode'] == "neutral_last_selection"

def test_dw_esc_mode_persistence(mpv_dual):
    """
    2.4 **State Persistence Test**: Mode stays active after closing/reopening DW.
    """
    ipc = mpv_dual.ipc
    
    # Open Drum Window
    ipc.command(['script-binding', 'kardenwort/toggle-drum-window'])
    time.sleep(0.3)
    
    # Set to 'neutral_current_subtitle' using cycling
    # (n twice from default auto_follow_current)
    ipc.command(['keypress', 'n'])
    time.sleep(0.2)
    ipc.command(['keypress', 'n'])
    time.sleep(0.2)
    
    state = query_kardenwort_state(ipc)
    assert state['options']['dw_esc_mode'] == "neutral_current_subtitle"
    
    # Close Drum Window
    ipc.command(['script-binding', 'kardenwort/toggle-drum-window'])
    time.sleep(0.3)
    state = query_kardenwort_state(ipc)
    assert state['drum_window'] == 'OFF'
    assert state['options']['dw_esc_mode'] == "neutral_current_subtitle"
    
    # Reopen Drum Window
    ipc.command(['script-binding', 'kardenwort/toggle-drum-window'])
    time.sleep(0.3)
    state = query_kardenwort_state(ipc)
    assert state['drum_window'] in [True, 'DOCKED', 'FLOATING']
    assert state['options']['dw_esc_mode'] == "neutral_current_subtitle"
