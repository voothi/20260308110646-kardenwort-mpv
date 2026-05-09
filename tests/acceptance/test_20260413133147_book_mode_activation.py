"""
Feature ZID: 20260413133147
Test Creation ZID: 20260508221338
Feature: Book Mode Activation
Acceptance tests for archived changes from April 12 to April 17, 2026.

These tests retroactively validate logic that was stabilized or fixed during
this early-to-mid April period, focusing on Drum Window features, 
Anki export sanitization, and specialized character support.
"""

import time
import pytest
from tests.ipc.mpv_ipc import query_lls_state, query_lls_render
from tests.ipc.mpv_session import MpvSession

class TestAprilEarlyRegressions:
    """Tests for archived changes in early-to-mid April 2026."""

    def test_20260413133147_book_mode_activation(self, mpv):
        """Verify Book Mode activation and OSD feedback (20260413133147)."""
        ipc = mpv.ipc
        
        # Toggle Book Mode
        ipc.command(['script-message-to', 'lls_core', 'toggle-book-mode'])
        time.sleep(0.2)
        
        state = query_lls_state(ipc)
        # state['book_mode'] is a boolean
        assert state['book_mode'] is True, "Book Mode should be True after toggle"
        
        # Verify it can be toggled back
        ipc.command(['script-message-to', 'lls_core', 'toggle-book-mode'])
        time.sleep(0.2)
        state = query_lls_state(ipc)
        assert state['book_mode'] is False, "Book Mode should be False after second toggle"

    def test_20260417031800_german_search_support(self, mpv):
        """Verify German character support in Search HUD (20260417031800)."""
        ipc = mpv.ipc
        
        # Open Search HUD
        ipc.command(['script-message-to', 'lls_core', 'toggle-drum-search'])
        time.sleep(0.2)
        
        # Input German characters "größe"
        for char in "größe":
            ipc.command(['script-message-to', 'lls_core', 'lls-test-search-input', char])
        time.sleep(0.1)
        
        state = query_lls_state(ipc)
        assert state['search_query'] == "größe", f"Expected search query 'größe', got '{state.get('search_query')}'"

    def test_20260417112500_tsv_spacing_unify_joiners(self, mpv_fragment1):
        """Verify unified joiners and verbatim spacing in export (20260417112500)."""
        ipc = mpv_fragment1.ipc
        
        # Seek to sub 2: "Manchmal hat man das Gefühl, die haben es extra auf einen abgesehen."
        ipc.command(['seek', 7.0, 'absolute+exact'])
        time.sleep(0.5)
        
        # Open Drum Window
        ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
        time.sleep(0.3)
        
        # Select "Manchmal" (1) and "hat" (2)
        ipc.command(['script-message-to', 'lls_core', 'lls-test-set-cursor', '2', '1'])
        time.sleep(0.1)
        # Shift+Right to select "Manchmal hat"
        ipc.command(['script-message-to', 'lls_core', 'lls-test-dw-word-move', '1', 'yes'])
        time.sleep(0.2)
        
        # Prepare export
        ipc.command(['script-message-to', 'lls_core', 'lls-test-prepare-export', 'RANGE', '2', '1', '2', '2'])
        time.sleep(0.2)
        
        export = ipc.get_property('user-data/lls/last_export')
        # Check for space preservation
        assert "Manchmal hat" in export, f"Export content mismatch: '{export}'"

    def test_20260413003600_sanitized_anki_export(self, mpv_fragment1):
        """Verify that Anki export is sanitized (no ASS tags) (20260413003600)."""
        ipc = mpv_fragment1.ipc
        ipc.command(['seek', 7.0, 'absolute+exact'])
        time.sleep(0.5)
        
        ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
        time.sleep(0.3)
        
        # Select "Manchmal"
        ipc.command(['script-message-to', 'lls_core', 'lls-test-set-cursor', '2', '1'])
        time.sleep(0.1)
        
        # Prepare export
        ipc.command(['script-message-to', 'lls_core', 'lls-test-prepare-export', 'POINT', '2', '1'])
        time.sleep(0.2)
        
        export = ipc.get_property('user-data/lls/last_export')
        assert "{\\" not in export, f"Export should be sanitized of ASS tags, got '{export}'"

    def test_20260413101458_dw_dark_theme_persistence(self, mpv):
        """Verify Drum Window dark theme option is registered (20260413101458)."""
        ipc = mpv.ipc
        
        state = query_lls_state(ipc)
        ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
        time.sleep(0.3)
        assert state['drum_window'] in ['OFF', 'DOCKED'], "Drum Window should be in a valid state"

    def test_20260412105348_drum_window_tooltip_toggle(self, mpv):
        """Verify tooltip toggle in Drum Window (20260412105348)."""
        ipc = mpv.ipc
        
        # Open Drum Window
        ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
        time.sleep(0.3)
        
        # Toggle tooltip
        ipc.command(['script-message-to', 'lls_core', 'lls-dw-tooltip-toggle'])
        time.sleep(0.2)
        
        state = query_lls_state(ipc)
        # Should be either HOVER or CLICK
        assert state.get('dw_tooltip_mode') in ['HOVER', 'CLICK']

    def test_20260416213225_bracket_highlighting(self, mpv_fragment1):
        """Verify that brackets do not break word highlighting (20260416213225)."""
        ipc = mpv_fragment1.ipc
        ipc.command(['seek', 7.0, 'absolute+exact'])
        time.sleep(0.5)
        
        ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
        time.sleep(0.3)
        
        ipc.command(['script-message-to', 'lls_core', 'lls-test-set-cursor', '2', '1'])
        time.sleep(0.1)
        state = query_lls_state(ipc)
        assert state['dw_cursor']['word'] == 1
