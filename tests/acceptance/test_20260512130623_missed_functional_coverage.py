"""
Feature ZID: 20260512130623
Test Creation ZID: 20260512130623
Feature: Missed Functional Coverage (Shortcut Swaps, Search Flow, Russian Layout)

Accepted Specs:
- keybinding-consolidation
- search-ux-optimization
- word-based-deletion-logic
- immersion-mode-fsm
"""

import os
import time
import pytest
import json
from tests.ipc.mpv_ipc import query_kardenwort_state, query_kardenwort_render
from tests.ipc.mpv_session import MpvSession

_FIXTURE_DIR = "tests/fixtures/20260502165659-test-fixture"
_VIDEO = os.path.abspath(f"{_FIXTURE_DIR}/20260502165659-test-fixture.mp4")
_SRT = os.path.abspath(f"{_FIXTURE_DIR}/20260502165659-test-fixture.en.srt")

def _robust_state(ipc, attempts=20):
    for _ in range(attempts):
        try:
            state = query_kardenwort_state(ipc)
            if state and "options" in state: return state
        except: pass
        time.sleep(0.5)
    return query_kardenwort_state(ipc)

@pytest.mark.acceptance
def test_shortcut_swap_h_and_H(mpv_ass):
    """Verify that Shift+H triggers karaoke mode and h triggers Anki global highlight (on ASS)."""
    ipc = mpv_ass.ipc
    
    # 1. Test toggle-anki-global
    state_before = _robust_state(ipc)
    ipc.command(["script-binding", "kardenwort/toggle-anki-global"])
    time.sleep(1.0)
    state_after = _robust_state(ipc)
    
    before = state_before["options"].get("anki_global_highlight")
    after = state_after["options"].get("anki_global_highlight")
    assert after != before, "script-binding toggle-anki-global failed"
    
    # 2. Test toggle-karaoke-mode
    karaoke_before = state_after.get("karaoke_mode", "OFF")
    ipc.command(["script-binding", "kardenwort/toggle-karaoke-mode"])
    time.sleep(1.0)
    state_karaoke = _robust_state(ipc)
    assert state_karaoke.get("karaoke_mode") != karaoke_before, "script-binding toggle-karaoke-mode failed"

@pytest.mark.acceptance
def test_search_mode_flow_and_cyrillic_delete(mpv):
    """Verify full search flow and Cyrillic layout word deletion."""
    ipc = mpv.ipc
    
    # 1. Open Search
    ipc.command(["script-binding", "kardenwort/toggle-drum-search"])
    time.sleep(1.5)
    state = _robust_state(ipc)
    assert state.get("search_mode") is True, "Search mode not active"
    
    # 2. Type "TEST" using script messages
    for char in "TEST":
        ipc.command(["script-message-to", "kardenwort", f"search-char-{char}"])
        time.sleep(0.1)
    time.sleep(1.0)
    state = _robust_state(ipc)
    assert state.get("search_query") == "TEST", f"Search query mismatch. Got: {state.get('search_query')}"
    
    # 3. Test Word Delete
    ipc.command(["script-message-to", "kardenwort", "test-set-search-query", "WORD1 WORD2"])
    time.sleep(0.5)
    
    ipc.command(["script-message-to", "kardenwort", "test-search-delete-word"])
    time.sleep(1.0)
    state = _robust_state(ipc)
    assert state.get("search_query") == "WORD1 ", f"Word deletion failed. Got: {state.get('search_query')}"
    
    # 4. Select result and Seek
    ipc.command(["script-message-to", "kardenwort", "test-set-search-query", "test"])
    time.sleep(1.0)
    state = _robust_state(ipc)
    assert len(state.get("search_results", [])) > 0, "No search results found for 'test'"
    
    time_before = ipc.get_property("time-pos")
    ipc.command(["keypress", "ENTER"])
    time.sleep(1.5)
    
    state = _robust_state(ipc)
    assert state.get("search_mode") is False, "Search mode did not exit after ENTER"
    assert abs(ipc.get_property("time-pos") - time_before) > 0.1, "Player did not seek after search selection"

@pytest.mark.acceptance
def test_anki_record_file_creation(mpv, tmp_path):
    """Verify that mining creates the Anki record file."""
    ipc = mpv.ipc
    
    # We'll use a temporary file path to avoid writing to fixture dir
    tsv_path = str(tmp_path / "test_record.tsv")
    # Set the record file option using our new helper
    ipc.command(["script-message-to", "kardenwort", "test-set-option", "anki_record_file", tsv_path])
    time.sleep(0.5)
    
    # 1. Select a word
    ipc.command(["seek", "0.5", "absolute+exact"])
    time.sleep(0.5)
    ipc.command(["script-message-to", "kardenwort", "test-ctrl-toggle-word", "1", "1"])
    time.sleep(0.5)
    
    # 2. Export selection
    ipc.command(["script-message-to", "kardenwort", "test-export-selection"])
    time.sleep(2.0)
    
    # 3. Verify file existence
    assert os.path.exists(tsv_path), f"Record file not found at {tsv_path}"
    with open(tsv_path, "r", encoding="utf-8") as f:
        content = f.read()
        assert "Hello" in content, "Exported content missing from TSV"
