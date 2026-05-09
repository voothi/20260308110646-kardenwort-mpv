"""
Feature ZID: 20260509180427
Test Creation ZID: 20260509180427
Feature: Tooltip Bootstrapping and SRT Parity
Tests that the tooltip cache is automatically populated from available external subtitles
at startup even if secondary subtitles are disabled, and verifies SRT OSD tooltip parity.
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
