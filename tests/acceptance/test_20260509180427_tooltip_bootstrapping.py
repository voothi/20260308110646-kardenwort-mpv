"""
Feature ZID: 20260509180427
Test Creation ZID: 20260509180427
Feature: Tooltip Bootstrapping and SRT Parity
Tests that the tooltip cache is automatically populated from available external subtitles
at startup even if secondary subtitles are disabled, and verifies SRT OSD tooltip parity
and flicker-free track switching (Fix for anchor 20260509171136).
"""
import time
import pytest
from tests.ipc.mpv_ipc import query_lls_state, query_lls_render

def test_tooltip_bootstraps_at_startup(mpv_dual):
    """Tooltip cache should be non-empty even if secondary-sid=no."""
    ipc = mpv_dual.ipc
    
    # 1. Turn OFF secondary subs to trigger bootstrapping logic
    ipc.command(['set_property', 'secondary-sid', 'no'])
    time.sleep(0.3)
    
    # 2. Verify tooltip cache size is > 0 (probed from external tracks)
    state = query_lls_state(ipc)
    assert state['tooltip_cache_size'] > 0, "Tooltip cache should be bootstrapped from available tracks"

def test_srt_tooltip_activation_parity(mpv_dual):
    """Tooltip can be toggled in SRT mode (Drum Mode OFF)."""
    ipc = mpv_dual.ipc
    
    # 1. Ensure Drum Mode is OFF
    state = query_lls_state(ipc)
    assert state['drum_mode'] == 'OFF'
    
    # 2. Toggle tooltip ON in SRT mode
    # Ensure SRT OSD mode is active
    ipc.command(['script-message-to', 'lls_core', 'lls-test-set-option', 'srt_font_size', '40'])
    time.sleep(0.1)
    
    ipc.command(['script-message-to', 'lls_core', 'lls-test-dw-tooltip-toggle'])
    time.sleep(0.2)
    
    # 3. Verify tooltip is forced ON and rendered
    state = query_lls_state(ipc)
    assert state['tooltip_forced'] is True
    
    render = query_lls_render(ipc, 'tooltip')
    assert render != '', "Tooltip should be rendered in SRT mode after toggle"
    assert '{\\an6}' in render, "Tooltip should use standard alignment"

def test_tooltip_forced_state_sync(mpv_dual):
    """Verifies that FSM.DW_TOOLTIP_FORCE is correctly synced to the snapshot."""
    ipc = mpv_dual.ipc
    
    # Toggle ON
    ipc.command(['script-message-to', 'lls_core', 'lls-test-dw-tooltip-toggle'])
    time.sleep(0.15)
    state = query_lls_state(ipc)
    assert state['tooltip_forced'] is True
    
    # Toggle OFF
    ipc.command(['script-message-to', 'lls_core', 'lls-test-dw-tooltip-toggle'])
    time.sleep(0.15)
    state = query_lls_state(ipc)
    assert state['tooltip_forced'] is False

def test_srt_tooltip_eligibility_guards(mpv_dual):
    """Tooltip should NOT activate if SRT OSD is disabled."""
    ipc = mpv_dual.ipc
    
    # Disable SRT OSD styling completely
    ipc.command(['script-message-to', 'lls_core', 'lls-test-set-option', 'srt_font_size', '0'])
    ipc.command(['script-message-to', 'lls_core', 'lls-test-set-option', 'srt_font_name', ''])
    ipc.command(['script-message-to', 'lls_core', 'lls-test-set-option', 'srt_font_bold', 'no'])
    time.sleep(0.2)
    
    # Attempt to toggle tooltip
    ipc.command(['script-message-to', 'lls_core', 'lls-test-dw-tooltip-toggle'])
    time.sleep(0.2)
    
    # Verify tooltip is NOT ON and NOT rendered
    state = query_lls_state(ipc)
    assert state['tooltip_forced'] is False, "Tooltip should NOT be forced ON if mode is ineligible"
    assert query_lls_render(ipc, 'tooltip') == '', "Tooltip should NOT be rendered if mode is ineligible"

def test_srt_track_cycle_bootstrapping_and_twitch_suppression(mpv_dual):
    """
    Verifies that the OSD renders immediately on the FIRST track switch after start
    because of bootstrapping, and that native subs are suppressed synchronously.
    This specifically checks the problem described in anchor 20260509171136.
    """
    ipc = mpv_dual.ipc
    
    # 1. Enable SRT OSD mode
    ipc.command(['script-message-to', 'lls_core', 'lls-test-set-option', 'srt_font_size', '40'])
    time.sleep(0.1)
    
    # 2. Verify cache is bootstrapped before switching
    state = query_lls_state(ipc)
    assert state['tooltip_cache_size'] > 0, "Cache should be bootstrapped at startup"
    
    # 3. Cycle to secondary track (RU) for the FIRST time
    ipc.command(['script-message-to', 'lls_core', 'lls-cycle-sec-sid'])
    
    # 4. Immediate synchronous checks
    # Property suppression
    vis = ipc.get_property('secondary-sub-visibility')
    assert vis is False, "Native secondary visibility should be suppressed immediately during cycle"
    
    # OSD rendering (proves cache was ready and update() was called)
    render = query_lls_render(ipc, 'drum')
    assert render != '', "OSD should contain text immediately after the first track cycle (no twitch/flash)"
