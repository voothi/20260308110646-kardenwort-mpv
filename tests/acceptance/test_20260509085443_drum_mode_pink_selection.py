"""
Feature ZID: 20260509085443
Test Creation ZID: 20260509003208
Feature: Drum Mode Pink Selection
Acceptance test for Drum Mode paired selection visual feedback.
"""

import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state, query_kardenwort_render
from tests.ipc.mpv_session import MpvSession

class TestDrumPinkSelection:
    def test_drum_mode_pink_selection(self, mpv_fragment1):
        """Verify that paired selection (f key) in Drum Mode renders pink immediately."""
        ipc = mpv_fragment1.ipc
        
        # Seek to sub 2
        ipc.command(['seek', 7.0, 'absolute+exact'])
        time.sleep(0.5)
        
        # Ensure we are in SRT Mode
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-sub-visibility-set', 'ON'])
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-drum-mode-set', 'OFF'])
        time.sleep(0.3)
        
        # Move cursor to line 2, word 1
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-set-cursor', '2', '1'])
        time.sleep(0.3)
        
        # Query render to force cache to build with the new cursor position
        _ = query_kardenwort_render(ipc, 'drum')
        
        # Trigger toggle to add to pink set
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-ctrl-toggle-word', '2', '1'])
        time.sleep(0.3)
        
        # Verify visual state in drum_osd
        render = query_kardenwort_render(ipc, 'drum')
        assert render is not None
        # In kardenwort, the pink color code is FF88FF
        assert "FF88FF" in render, "Pink color not found in Drum OSD render after selection"




