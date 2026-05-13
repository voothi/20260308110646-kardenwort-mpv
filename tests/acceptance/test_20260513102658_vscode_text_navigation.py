"""
Feature ZID: 20260513102658
Test Creation ZID: 20260513103119
Feature: VSCode-inspired text navigation and selection in DW/DM

Hardening tests for Arrow navigation, Shift selection, Ctrl jumps, and line transitions.
"""

import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state

def _set_cursor(ipc, line, word):
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", str(line), str(word)])
    time.sleep(0.1)

def _move_word(ipc, delta, shift=False):
    shift_val = "yes" if shift else "no"
    ipc.command(["script-message-to", "kardenwort", "test-dw-word-move", str(delta), shift_val])
    time.sleep(0.1)

def _move_line(ipc, delta, shift=False):
    shift_val = "yes" if shift else "no"
    ipc.command(["script-message-to", "kardenwort", "test-dw-line-move", str(delta), shift_val])
    time.sleep(0.1)

def _get_dw_state(ipc):
    state = query_kardenwort_state(ipc)
    return state.get("dw_cursor", {}), state.get("dw_anchor", {})

@pytest.mark.acceptance
def test_20260513102658_basic_token_movement(mpv_fragment2):
    """Task 2.1: Test basic token movement (Arrow Left/Right)."""
    ipc = mpv_fragment2.ipc
    # Load our specific fixture as a subtitle track
    ipc.command(["sub-add", "tests/fixtures/20260513104740-vscode-nav.srt", "select"])
    time.sleep(0.5)
    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    time.sleep(0.5)

    # Start at line 1, word 1 ("First")
    _set_cursor(ipc, 1, 1)
    
    # Move Right -> word 2 ("line")
    _move_word(ipc, 1)
    cursor, _ = _get_dw_state(ipc)
    assert cursor["line"] == 1
    assert cursor["word"] == 2

    # Move Right -> word 3 ("with")
    _move_word(ipc, 1)
    cursor, _ = _get_dw_state(ipc)
    assert cursor["word"] == 3

    # Move Left -> word 2
    _move_word(ipc, -1)
    cursor, _ = _get_dw_state(ipc)
    assert cursor["word"] == 2

@pytest.mark.acceptance
def test_20260513102658_line_to_line_transitions(mpv_fragment2):
    """Task 2.2: Test line-to-line transitions."""
    ipc = mpv_fragment2.ipc
    ipc.command(["sub-add", "tests/fixtures/20260513104740-vscode-nav.srt", "select"])
    time.sleep(0.5)
    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    time.sleep(0.5)

    # Line 1 has 5 words: First(1) line(2) with(3) multiple(4) words.(5)
    _set_cursor(ipc, 1, 5)
    
    # Move Right at end of line -> Line 2, word 1
    _move_word(ipc, 1)
    cursor, _ = _get_dw_state(ipc)
    assert cursor["line"] == 2
    assert cursor["word"] == 1

    # Move Left at start of line -> Line 1, word 5
    _move_word(ipc, -1)
    cursor, _ = _get_dw_state(ipc)
    assert cursor["line"] == 1
    assert cursor["word"] == 5

@pytest.mark.acceptance
def test_20260513102658_selection_extension_shift(mpv_fragment2):
    """Task 3.1: Test selection extension with Shift."""
    ipc = mpv_fragment2.ipc
    ipc.command(["sub-add", "tests/fixtures/20260513104740-vscode-nav.srt", "select"])
    time.sleep(0.5)
    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    time.sleep(0.5)

    _set_cursor(ipc, 1, 1)
    
    # Shift + Right -> Anchor=1.1, Cursor=1.2
    _move_word(ipc, 1, shift=True)
    cursor, anchor = _get_dw_state(ipc)
    assert anchor["line"] == 1
    assert anchor["word"] == 1
    assert cursor["word"] == 2

    # Shift + Right -> Cursor=1.3
    _move_word(ipc, 1, shift=True)
    cursor, anchor = _get_dw_state(ipc)
    assert anchor["word"] == 1
    assert cursor["word"] == 3

@pytest.mark.acceptance
def test_20260513102658_ctrl_jump_navigation(mpv_fragment2):
    """Task 3.3: Test jump movement with Ctrl."""
    ipc = mpv_fragment2.ipc
    ipc.command(["sub-add", "tests/fixtures/20260513104740-vscode-nav.srt", "select"])
    time.sleep(0.5)
    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    time.sleep(0.5)

    _set_cursor(ipc, 1, 1)
    
    # Ctrl + Right (delta=5) -> Should land on line 2 (since line 1 has 5 tokens)
    # Line 1 tokens: First(1), line(2), with(3), multiple(4), words.(5)
    # Moving by 5 from 1: 1->2->3->4->5->(Line 2, 1)
    _move_word(ipc, 5)
    cursor, _ = _get_dw_state(ipc)
    assert cursor["line"] == 2
    assert cursor["word"] == 1

@pytest.mark.acceptance
def test_20260513102658_vertical_movement_across_subtitles(mpv_fragment2):
    """Task 2.3: Test vertical movement across subtitles."""
    ipc = mpv_fragment2.ipc
    ipc.command(["sub-add", "tests/fixtures/20260513104740-vscode-nav.srt", "select"])
    time.sleep(0.5)
    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    time.sleep(0.5)

    # Start at line 1
    _set_cursor(ipc, 1, 1)
    
    # Down -> Line 2
    _move_line(ipc, 1)
    cursor, _ = _get_dw_state(ipc)
    assert cursor["line"] == 2
    
    # Up -> Line 1
    _move_line(ipc, -1)
    cursor, _ = _get_dw_state(ipc)
    assert cursor["line"] == 1

@pytest.mark.acceptance
def test_20260513102658_selection_collapse(mpv_fragment2):
    """Task 3.2: Test selection collapse."""
    ipc = mpv_fragment2.ipc
    ipc.command(["sub-add", "tests/fixtures/20260513104740-vscode-nav.srt", "select"])
    time.sleep(0.5)
    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    time.sleep(0.5)

    _set_cursor(ipc, 1, 1)
    _move_word(ipc, 1, shift=True)
    _, anchor = _get_dw_state(ipc)
    assert anchor["word"] != -1
    
    # Move without shift -> Anchor should collapse (-1)
    _move_word(ipc, 1, shift=False)
    cursor, anchor = _get_dw_state(ipc)
    assert anchor["line"] == -1
    assert anchor["word"] == -1
    assert cursor["word"] == 3

@pytest.mark.acceptance
def test_20260513102658_jump_selection_ctrl_shift(mpv_fragment2):
    """Task 3.4: Test jump selection with Ctrl + Shift."""
    ipc = mpv_fragment2.ipc
    ipc.command(["sub-add", "tests/fixtures/20260513104740-vscode-nav.srt", "select"])
    time.sleep(0.5)
    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    time.sleep(0.5)

    _set_cursor(ipc, 1, 1)
    
    # Ctrl + Shift + Right (delta=5)
    _move_word(ipc, 5, shift=True)
    cursor, anchor = _get_dw_state(ipc)
    assert anchor["line"] == 1
    assert anchor["word"] == 1
    assert cursor["line"] == 2
    assert cursor["word"] == 1

@pytest.mark.acceptance
def test_20260513102658_sticky_x_vertical_navigation(mpv_fragment2):
    """Task 4.1: Verify Sticky-X behavior."""
    ipc = mpv_fragment2.ipc
    ipc.command(["sub-add", "tests/fixtures/20260513104740-vscode-nav.srt", "select"])
    time.sleep(0.5)
    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    time.sleep(0.5)

    # Line 4 is "Short." (1 word)
    # Line 5 is "End of the test sequence." (5 words)
    
    # Start at Line 5, word 4 ("test")
    _set_cursor(ipc, 5, 4)
    # Trigger X capture by moving word once or just setting it?
    # FSM.DW_CURSOR_X is nil after _set_cursor.
    # Moving word once to set it.
    _move_word(ipc, 1) # word 5 ("sequence")
    
    # Move UP to Line 4 ("Short.")
    # Line 4 has only 1 word. It should land on word 1.
    _move_line(ipc, -1)
    cursor, _ = _get_dw_state(ipc)
    assert cursor["line"] == 4
    assert cursor["word"] == 1
    
    # Move DOWN to Line 5. It should land back on word 5 (or closest to captured X).
    _move_line(ipc, 1)
    cursor, _ = _get_dw_state(ipc)
    assert cursor["line"] == 5
    assert cursor["word"] == 5

@pytest.mark.acceptance
def test_20260513102658_multiline_subtitle_navigation(mpv_fragment2):
    """Task 2.4: Test multi-line subtitle navigation (Down within same subtitle)."""
    ipc = mpv_fragment2.ipc
    ipc.command(["sub-add", "tests/fixtures/20260513104740-vscode-nav.srt", "select"])
    time.sleep(0.5)
    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    # Set a large font to ensure wrapping
    ipc.command(["script-message-to", "kardenwort", "test-set-options", "dw_font_size=100"])
    time.sleep(0.5)

    # Line 3 is long. With font size 100, it will definitely wrap.
    _set_cursor(ipc, 3, 1) # "This"
    
    # Move DOWN. Should stay in line 3 but move to a word on the next visual line.
    _move_line(ipc, 1)
    cursor, _ = _get_dw_state(ipc)
    assert cursor["line"] == 3
    assert cursor["word"] > 1


@pytest.mark.acceptance
def test_20260513155650_scroll_preserves_selection_and_pink_set(mpv_fragment2):
    """Wheel/Ctrl-scroll must not collapse active selection or clear pink pending words."""
    ipc = mpv_fragment2.ipc
    ipc.command(["sub-add", "tests/fixtures/20260513104740-vscode-nav.srt", "select"])
    time.sleep(0.5)
    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    time.sleep(0.5)

    # Build a yellow range on line 1: words 1..3
    _set_cursor(ipc, 1, 1)
    _move_word(ipc, 1, shift=True)
    _move_word(ipc, 1, shift=True)

    # Add one pink pending word and remember baseline state.
    ipc.command(["script-message-to", "kardenwort", "test-ctrl-toggle-word", "2", "1"])
    time.sleep(0.15)
    before = query_kardenwort_state(ipc)
    before_cursor = before.get("dw_cursor", {})
    before_anchor = before.get("dw_anchor", {})
    before_pink = int(before.get("dw_selection_count") or 0)

    # Simulate Ctrl+Down/Up behavior through DW scroll command path.
    ipc.command(["script-message-to", "kardenwort", "test-dw-scroll", "1"])
    time.sleep(0.1)
    ipc.command(["script-message-to", "kardenwort", "test-dw-scroll", "-1"])
    time.sleep(0.1)

    after = query_kardenwort_state(ipc)
    after_cursor = after.get("dw_cursor", {})
    after_anchor = after.get("dw_anchor", {})
    after_pink = int(after.get("dw_selection_count") or 0)

    assert after_cursor.get("line") == before_cursor.get("line")
    assert after_cursor.get("word") == before_cursor.get("word")
    assert after_anchor.get("line") == before_anchor.get("line")
    assert after_anchor.get("word") == before_anchor.get("word")
    assert after_pink == before_pink
