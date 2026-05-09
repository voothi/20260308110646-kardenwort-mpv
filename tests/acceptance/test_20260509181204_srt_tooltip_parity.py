"""
Feature ZID: 20260509181204
Test Creation ZID: 20260509181204
Feature: SRT Tooltip Parity
Tests that tooltips are available in standard SRT mode (Drum Mode OFF).
"""
import time
import pytest
from tests.ipc.mpv_ipc import query_lls_state, query_lls_render

def test_srt_tooltip_activation_parity(mpv_dual):
    """Tooltip can be toggled in SRT mode (Drum Mode OFF)."""
    ipc = mpv_dual.ipc
    
    # 1. Ensure Drum Mode is OFF and Drum Window is OFF
    state = query_lls_state(ipc)
    assert state['drum_mode'] == 'OFF'
    assert state['drum_window'] == 'OFF'
    assert 'SRT' in state['playback_state']
    
    # 2. Toggle tooltip with 'e' (keyboard force)
    ipc.command(['script-message-to', 'lls_core', 'lls-test-dw-tooltip-toggle'])
    time.sleep(0.15)
    
    # 3. Verify tooltip is rendered
    render = query_lls_render(ipc, 'tooltip')
    assert render != '', "Tooltip should be rendered in SRT mode after toggle"
    assert '{\\an6}' in render, "Tooltip should use standard \an6 alignment"
    assert '{\\pos' in render, "Tooltip should have a position tag"

def test_srt_tooltip_ineligible_without_osd_styling(mpv_dual):
    """Tooltip is NOT available in SRT mode if custom OSD styling is disabled."""
    ipc = mpv_dual.ipc
    
    # Disable SRT OSD styling
    ipc.command(['script-message-to', 'lls_core', 'lls-test-set-option', 'srt_font_size', '0'])
    ipc.command(['script-message-to', 'lls_core', 'lls-test-set-option', 'srt_font_name', ''])
    ipc.command(['script-message-to', 'lls_core', 'lls-test-set-option', 'srt_font_bold', 'no'])
    time.sleep(0.1)
    
    # Attempt to toggle tooltip
    ipc.command(['script-message-to', 'lls_core', 'lls-test-dw-tooltip-toggle'])
    time.sleep(0.15)
    
    # Verify tooltip is NOT rendered (cleared by eligibility check)
    render = query_lls_render(ipc, 'tooltip')
    state = query_lls_state(ipc)
    assert render == '', f"Tooltip should NOT be rendered when SRT OSD is inactive. State: {state}"

def test_srt_tooltip_dismiss_on_mode_change(mpv_dual):
    """Tooltip is dismissed when switching to an ineligible state (e.g. hiding subs)."""
    ipc = mpv_dual.ipc
    
    # Toggle tooltip ON in SRT mode
    ipc.command(['script-message-to', 'lls_core', 'lls-test-dw-tooltip-toggle'])
    time.sleep(0.15)
    assert query_lls_render(ipc, 'tooltip') != ''
    
    # Hide subtitles
    ipc.command(['script-message-to', 'lls_core', 'lls-toggle-sub-vis'])
    time.sleep(0.15)
    
    # Verify tooltip is cleared
    render = query_lls_render(ipc, 'tooltip')
    assert render == '', "Tooltip should be cleared after hiding subtitles"
