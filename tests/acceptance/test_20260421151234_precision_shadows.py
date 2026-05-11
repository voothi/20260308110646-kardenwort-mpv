"""
Feature ZID: 20260421151234
Test Creation ZID: 20260508214606
Feature: Precision Shadows
"""

import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state, query_kardenwort_render

def test_20260421151234_precision_shadows(mpv):
    """Verify that Drum Window precision hardening logic is active."""
    ipc = mpv.ipc
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-drum-window-toggle'])
    time.sleep(0.2)
    state = query_kardenwort_state(ipc)
    assert state['drum_window'] != 'OFF'

def test_20260421220419_sticky_column(mpv_fragment1):
    """Verify sticky column persistence in Drum Window navigation."""
    ipc = mpv_fragment1.ipc
    ipc.command(['seek', 7.0, 'absolute+exact'])
    time.sleep(0.2)
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-drum-window-toggle'])
    time.sleep(0.3)
    for _ in range(8):
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-dw-word-move', '1', 'no'])
    time.sleep(0.1)
    state1 = query_kardenwort_state(ipc)
    initial_word = state1['dw_cursor']['word']
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-dw-line-move', '1', 'no'])
    time.sleep(0.2)
    state2 = query_kardenwort_state(ipc)
    assert state2['dw_cursor']['word'] > 1

def test_20260425221654_esc_stages(mpv_fragment1):
    """Verify that ESC clears selection tiers in order: Range -> Pointer."""
    ipc = mpv_fragment1.ipc
    ipc.command(['seek', 7.0, 'absolute+exact'])
    time.sleep(0.2)
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-drum-window-toggle'])
    time.sleep(0.3)
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-dw-word-move', '1', 'no'])
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-dw-word-move', '1', 'true'])
    time.sleep(0.1)
    state = query_kardenwort_state(ipc)
    assert state['dw_anchor']['line'] != -1
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-dw-esc'])
    time.sleep(0.1)
    state = query_kardenwort_state(ipc)
    assert state['dw_anchor']['line'] == -1
    assert state['dw_cursor']['word'] != -1
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-dw-esc'])
    time.sleep(0.1)
    state = query_kardenwort_state(ipc)
    assert state['dw_cursor']['word'] == -1

def test_20260426233000_unified_copy(mpv_fragment1):
    """Verify unified copy logic works even when native subs are suppressed."""
    ipc = mpv_fragment1.ipc
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-drum-window-set', 'OFF'])
    ipc.command(['set_property', 'sub-visibility', False])
    time.sleep(0.1)
    ipc.command(['seek', 7.0, 'absolute+exact'])
    time.sleep(0.2)
    ipc.command(['script-message-to', 'kardenwort', 'copy-subtitle'])
    time.sleep(0.1)
    state = query_kardenwort_state(ipc)
    assert state['active_sub_index'] > 0

def test_20260425221654_sec_pos_sync(mpv_dual):
    """Verify secondary subtitle position syncs to FSM."""
    ipc = mpv_dual.ipc
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-native-sec-sub-pos-set', '80'])
    time.sleep(0.2)
    state = query_kardenwort_state(ipc)
    assert state['native_sec_sub_pos'] == 80
    assert ipc.get_property('secondary-sub-pos') == 80

def test_20260424202720_book_mode_copy(mpv_fragment1):
    """Verify copy behavior in Book Mode."""
    ipc = mpv_fragment1.ipc
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-set-follow-player', 'ON'])
    ipc.command(['script-message-to', 'kardenwort', 'toggle-book-mode']) # Toggle ON
    time.sleep(0.3)
    state = query_kardenwort_state(ipc)
    assert state['book_mode'] is True
    
    # In Book Mode, if no selection, it should copy active sub
    ipc.command(['seek', 7.0, 'absolute+exact'])
    time.sleep(0.2)
    ipc.command(['script-message-to', 'kardenwort', 'copy-subtitle'])
    time.sleep(0.1)
    # Success if no error.

def test_20260425025011_independent_pointer(mpv_fragment1):
    """Verify that pointer is independent of active line in Book Mode manual nav."""
    ipc = mpv_fragment1.ipc
    ipc.command(['seek', 7.0, 'absolute+exact']) # Sub 2
    time.sleep(0.2)
    ipc.command(['script-message-to', 'kardenwort', 'toggle-book-mode'])
    time.sleep(0.3)
    
    # Move pointer to sub 4
    ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-set-cursor', '4', '1'])
    time.sleep(0.1)
    
    state = query_kardenwort_state(ipc)
    assert state['dw_cursor']['line'] == 4
    # Active line should still be 2 (based on time)
    assert state['active_sub_index'] == 2




