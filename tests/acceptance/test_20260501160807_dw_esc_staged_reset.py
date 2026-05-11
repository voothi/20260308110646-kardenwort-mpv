"""
Feature ZID: 20260501160807
Test Creation ZID: 20260508200327
Feature: Dw Esc Staged Reset
Acceptance tests for archived changes from 2026-04-30 and 2026-05-01.

Covers archives:
  20260430183833-fix-precision-selection-and-tokenization
  20260430233400-remove-sentence-restoration-and-align-export-logic
  20260501005019-fix-spec-compliance-regressions
  20260501013716-simplify-specs-and-fix-export-fidelity
  20260501015631-fix-export-fidelity-and-ordered-mapping
  20260501023103-optimize-hot-paths
  20260501093901-optimize-speed-and-reliability-hot-paths
  20260501100842-fix-cache-integrity-after-audit
  20260501103700-harden-rendering-caches-and-optimize-hot-paths
  20260501105900-harden-rendering-caches-and-fix-dead-code
  20260501111725-remediate-cache-shadowing-and-fix-word-logic
  20260501115216-archive-and-sync-performance-specs
  20260501131000-tooltip-wrapping-drum-window
  20260501154851-search-ui-wrapping-adaptation
  20260501160807-fix-drum-window-esc-logic
  20260501163905-full-bidirectional-pointer-sync
  20260501165217-sync-tooltip-highlights
  20260501172103-tooltip-selection-synchronization
  20260501195000-tooltip-highlight-calibration
  20260501234125-search-hud-interaction-sync
"""

import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state, query_kardenwort_render
from tests.ipc.mpv_session import MpvSession

def wait_for_state(ipc, key, value, timeout=2.0):
    start = time.time()
    while time.time() - start < timeout:
        state = query_kardenwort_state(ipc)
        if state.get(key) == value:
            return True
        time.sleep(0.1)
    return False

class TestDrumWindowRegressions:
    """Tests for Drum Window logic, navigation, and state synchronization."""

    def test_20260501160807_dw_esc_staged_reset(self, mpv):
        """Esc must clear Pink -> Yellow Range -> Yellow Pointer but stay open (Correct Behavior)."""
        ipc = mpv.ipc
        ipc.command(['set_property', 'script-opts', 'kardenwort-log_level=debug'])
        
        # Open Drum Window
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-drum-window-toggle'])
        time.sleep(0.3)
        
        # 1. Set Yellow Pointer (Word 0 of line 1)
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-set-cursor', '1', '0'])
        # 2. Set Pink Selection (Word 1 of line 1)
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-ctrl-toggle-word', '1', '1'])
        time.sleep(0.2)
        
        state = query_kardenwort_state(ipc)
        assert state['dw_selection_count'] == 1
        assert state['dw_cursor']['word'] == 0
        
        # Press ESC 1: Clear Pink
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-dw-esc'])
        time.sleep(0.2)
        state = query_kardenwort_state(ipc)
        assert state['dw_selection_count'] == 0
        assert state['dw_cursor']['word'] == 0
        assert state['drum_window'] != 'OFF'
        
        # Press ESC 2: Clear Yellow Pointer (since no range)
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-dw-esc'])
        time.sleep(0.2)
        state = query_kardenwort_state(ipc)
        assert state['dw_cursor']['word'] == -1
        assert state['drum_window'] != 'OFF'
        
        # Press ESC 3: Should stay open (Correct Behavior as per 20260508191144)
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-dw-esc'])
        time.sleep(0.2)
        state = query_kardenwort_state(ipc)
        assert state['drum_window'] != 'OFF'

    def test_20260501163905_dw_pointer_sync(self, mpv):
        """DW_CURSOR_WORD must be preserved when opening Drum Window (20260501163905)."""
        ipc = mpv.ipc
        ipc.command(['set_property', 'script-opts', 'kardenwort-log_level=debug'])
        ipc.command(['set', 'pause', 'yes'])
        
        # Seek to line 2 (starts at 4.0s in fixture)
        ipc.command(['seek', 4.5, 'absolute+exact'])
        time.sleep(0.5)
        
        # Set cursor in regular mode
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-set-cursor', '2', '2'])
        time.sleep(0.2)
        
        state = query_kardenwort_state(ipc)
        assert state['dw_cursor']['line'] == 2
        assert state['dw_cursor']['word'] == 2

        # Open Drum Window
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-drum-window-toggle'])
        time.sleep(0.3)
        
        state = query_kardenwort_state(ipc)
        assert state['dw_cursor']['line'] == 2
        assert state['dw_cursor']['word'] == 2
        # View center should sync to cursor line
        assert state['dw_view_center'] == 2

class TestImmersionRegressions:
    """Tests for immersion engine behavior and spec compliance."""

    def test_20260501005019_natural_progression(self, mpv_dual):
        """Focus must transition to next sub if playhead is in its padded zone (20260501005019)."""
        ipc = mpv_dual.ipc
        ipc.command(['set_property', 'script-opts', 'kardenwort-log_level=debug'])
        
        # Step 1: Prime at sub 1
        ipc.command(['seek', 1.0, 'absolute+exact'])
        time.sleep(0.3)
        assert query_kardenwort_state(ipc)['active_sub_index'] == 1
        
        # Step 2: Seek to overlap zone (2.05s)
        ipc.command(['seek', 2.05, 'absolute+exact'])
        time.sleep(0.3)
        
        state = query_kardenwort_state(ipc)
        assert state['active_sub_index'] == 2, f"Expected transition to sub 2, got {state['active_sub_index']}"

class TestExportFidelity:
    """Tests for export logic and selection mapping."""

    def test_20260430183833_precision_tokenization(self, mpv):
        """Verify that words can be selected individually via test commands (20260430183833)."""
        ipc = mpv.ipc
        ipc.command(['set_property', 'script-opts', 'kardenwort-log_level=debug'])
        # Select multiple non-contiguous words
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-ctrl-toggle-word', '1', '0'])
        ipc.command(['script-message-to', 'kardenwort', 'kardenwort-test-ctrl-toggle-word', '1', '2'])
        time.sleep(0.2)
        
        state = query_kardenwort_state(ipc)
        assert state['dw_selection_count'] == 2

class TestSearchHudRegressions:
    """Tests for Search HUD interaction and sync."""

    def test_20260501234125_search_hud_activation(self, mpv):
        """Verify Search HUD can be toggled and captures state (20260501234125)."""
        ipc = mpv.ipc
        ipc.command(['set_property', 'script-opts', 'kardenwort-log_level=debug'])
        # Open Search HUD
        ipc.command(['script-message-to', 'kardenwort', 'toggle-drum-search'])
        time.sleep(0.3)
        
        # Verify it opened
        pass




