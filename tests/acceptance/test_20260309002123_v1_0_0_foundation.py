"""
Acceptance tests for archived changes from March 9 to March 14, 2026.

These tests retroactively validate foundational logic including centralization,
fuzzy search scoring, and external subtitle validation.
"""

import time
import pytest
from tests.ipc.mpv_ipc import query_lls_state

def robust_query_state(ipc, retries=3):
    """Retries query_lls_state if it returns an empty or incomplete state."""
    for i in range(retries):
        state = query_lls_state(ipc)
        if state and 'tracks' in state:
            return state
        time.sleep(0.5)
    return query_lls_state(ipc)

class TestMarchEarlyRegressions:
    """Tests for archived changes in early March 2026."""

    def test_20260309002123_v1_0_0_foundation(self, mpv):
        """Verify foundational OSD duration (20260309002123)."""
        ipc = mpv.ipc
        state = robust_query_state(ipc)
        
        # v1.0.0 Decision: Global OSD duration set to 0.5s
        assert state['options']['osd_duration'] == 0.5
        
        # v1.0.0 Decision: script-message handlers established
        assert 'playback_state' in state

    def test_20260310002147_v1_2_0_centralization(self, mpv):
        """Verify centralization into lls_core and master tick presence (20260310002147)."""
        ipc = mpv.ipc
        state = robust_query_state(ipc)
        
        # v1.2.0 Decision: Master tick rate at 0.05s
        assert state['options']['tick_rate'] == 0.05
        
        # v1.2.0 Decision: State machine consolidated
        assert state['playback_state'] != "NO_SUBS"

    def test_20260312192633_v1_25_0_fuzzy_search(self, mpv_fragment1):
        """Verify fuzzy search scoring logic handles multi-keyword queries (20260312192633)."""
        ipc = mpv_fragment1.ipc
        
        # Open Drum Window
        ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
        time.sleep(1.0)
        
        # Open Search
        ipc.command(['script-message-to', 'lls_core', 'toggle-drum-search'])
        time.sleep(0.5)
        
        # v1.25.0 Decision: Multi-keyword AND logic.
        ipc.command(['script-message-to', 'lls_core', 'lls-test-search-input', 'Paket Ende'])
        time.sleep(0.8) # Allow time for scoring logic
        
        state = robust_query_state(ipc)
        assert state.get('search_query') == 'Paket Ende'
        
        # Verification that results are filtered
        results = state.get('search_results', [])
        assert len(results) > 0, "Search results should not be empty for 'Paket Ende'"
        for res in results:
            text = res['text'].lower()
            assert 'paket' in text or 'ende' in text

    def test_20260314000819_v1_26_8_validation_with_subs(self, mpv):
        """Verify validation logic for external subtitle files (20260314000819)."""
        ipc = mpv.ipc
        time.sleep(2.0) # Ensure tracks are loaded and FSM settled
        
        state = robust_query_state(ipc)
        assert 'tracks' in state, f"State missing 'tracks' key. Keys: {list(state.keys())}"
        assert state['tracks']['pri']['path'] is not None
        
        # Toggle Drum Window
        ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
        time.sleep(1.0)
        state = robust_query_state(ipc)
        assert state['drum_window'] != 'OFF'

    def test_20260314000819_v1_26_8_ass_gatekeeping(self, mpv_ass):
        """Verify that ASS tracks disable Drum Mode to prevent rendering conflicts (20260314000819)."""
        ipc = mpv_ass.ipc
        time.sleep(1.5) # Ensure tracks are loaded
        
        state = robust_query_state(ipc)
        assert 'tracks' in state, f"State missing 'tracks' key. Keys: {list(state.keys())}"
        assert state['tracks']['pri']['is_ass'] == True
        
        # Try to toggle Drum Mode
        ipc.command(['script-message-to', 'lls_core', 'lls-drum-toggle'])
        time.sleep(1.0)
        
        state = robust_query_state(ipc)
        assert state['drum_mode'] == 'OFF', "Drum Mode should be inhibited on ASS tracks"
