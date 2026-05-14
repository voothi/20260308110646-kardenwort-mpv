"""
ZID: 20260514165416
Feature: Fix selection reset follow-state desync
Verifies that calling dw_reset_selection (via mining or Esc) restores FSM.DW_FOLLOW_PLAYER.
"""

import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state

def test_20260514165416_reset_restores_follow(mpv):
    ipc = mpv.ipc
    
    # 1. Open Drum Window
    ipc.command(['script-message-to', 'kardenwort', 'drum-window-toggle'])
    time.sleep(0.3)
    
    # 2. Force follow=false (simulates manual interaction)
    ipc.command(['script-message-to', 'kardenwort', 'test-set-follow-player', 'false'])
    time.sleep(0.2)
    state = query_kardenwort_state(ipc)
    assert state['dw_follow_player'] is False
    
    # 3. Call reset selection (e.g. via test-dw-esc)
    # We use test-dw-esc Stage 3 (needs a cursor to trigger stage 3 reset)
    ipc.command(['script-message-to', 'kardenwort', 'test-set-cursor', '1', '1'])
    time.sleep(0.1)
    
    # Trigger Esc (Stage 3)
    ipc.command(['script-message-to', 'kardenwort', 'test-dw-esc'])
    time.sleep(0.2)
    
    state = query_kardenwort_state(ipc)
    # Selection should be cleared
    assert state['dw_cursor']['word'] == -1
    # FOLLOW_PLAYER should be restored!
    assert state['dw_follow_player'] is True
    assert state['dw_seeking_manually'] is False

def test_20260514165416_export_restores_follow(mpv):
    """Verify that Anki export also restores follow state via dw_reset_selection."""
    ipc = mpv.ipc
    
    # 1. Open Drum Window
    ipc.command(['script-message-to', 'kardenwort', 'drum-window-toggle'])
    time.sleep(0.3)
    
    # 2. Set cursor and force follow=false
    ipc.command(['script-message-to', 'kardenwort', 'test-set-cursor', '1', '1'])
    ipc.command(['script-message-to', 'kardenwort', 'test-set-follow-player', 'false'])
    time.sleep(0.2)
    
    state = query_kardenwort_state(ipc)
    assert state['dw_follow_player'] is False
    
    # 3. Trigger Export (this calls dw_reset_selection)
    ipc.command(['script-message-to', 'kardenwort', 'test-export-selection'])
    time.sleep(0.5) # Export takes time
    
    state = query_kardenwort_state(ipc)
    # Selection should be cleared
    assert state['dw_cursor']['word'] == -1
    # FOLLOW_PLAYER should be restored!
    assert state['dw_follow_player'] is True
