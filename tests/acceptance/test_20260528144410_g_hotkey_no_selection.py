"""
Feature ZID: 20260528132406
Test Creation ZID: 20260528144410
Feature: Live Export Fallback & Universal Cursor Sync

Verifies:
1. Universal Cursor synchronization in Book Mode when follow player is true and no selection is active.
2. Anki export fallback resolving the target line dynamically using live time-pos when no selection is present.
"""

import time
import tempfile
from pathlib import Path
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state

def test_20260528144410_universal_cursor_sync_in_book_mode(mpv):
    ipc = mpv.ipc
    
    # 1. Enable Drum Window and Book Mode
    ipc.command(['script-message-to', 'kardenwort', 'drum-window-toggle'])
    time.sleep(0.3)
    
    ipc.command(['script-message-to', 'kardenwort', 'test-set-option', 'book_mode', 'yes'])
    time.sleep(0.2)
    
    state = query_kardenwort_state(ipc)
    assert state.get('book_mode') is True
    assert state.get('dw_follow_player') is True
    
    # 2. Seek playback to a new timestamp (4.5s) where active index is subtitle 2
    ipc.command(['seek', 4.5, 'absolute+exact'])
    time.sleep(0.3)
    
    state = query_kardenwort_state(ipc)
    # The active line should be index 2
    assert state.get('dw_active_line') == 2
    
    # Since follow player is active and there is no selection,
    # universal cursor synchronization MUST sync DW_CURSOR_LINE to active index 2
    # even in Book Mode.
    assert state.get('dw_cursor', {}).get('line') == 2
    assert state.get('dw_cursor', {}).get('word') == -1

def test_20260528144410_anki_export_fallback_uses_live_pos(mpv):
    ipc = mpv.ipc
    
    # Create a temporary TSV file to capture the exported TSV row
    fd, temp_name = tempfile.mkstemp(prefix="kardenwort-export-fallback-", suffix=".tsv")
    try:
        tsv_path = Path(temp_name)
        
        # Configure the TSV path and global highlight options
        ipc.command(['script-message-to', 'kardenwort', 'test-set-option', 'anki_record_file', str(tsv_path)])
        ipc.command(['script-message-to', 'kardenwort', 'test-set-option', 'anki_sync_period', '0.2'])
        time.sleep(0.2)
        
        # Seek playback to subtitle 2 (4.5s) and trigger export with no selection
        ipc.command(['seek', 4.5, 'absolute+exact'])
        time.sleep(0.3)
        
        # Verify no selection is active
        state = query_kardenwort_state(ipc)
        assert state.get('dw_anchor', {}).get('line') == -1
        assert state.get('dw_cursor', {}).get('word') == -1
        
        # Trigger export
        ipc.command(['script-message-to', 'kardenwort', 'test-export-selection'])
        time.sleep(0.5)
        
        # Verify that the correct subtitle line in its entirety is exported
        content = tsv_path.read_text(encoding="utf-8")
        assert "This is a test" in content
        
    finally:
        try:
            Path(temp_name).unlink(missing_ok=True)
        except Exception:
            pass
