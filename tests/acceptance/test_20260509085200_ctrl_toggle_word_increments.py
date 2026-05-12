"""
Feature ZID: 20260509085200
Test Creation ZID: 20260509085637
Feature: Ctrl Toggle Word Increments
Tests for selection priority hierarchy and DW_CTRL_PENDING_LIST consistency.

Covers:
  openspec/changes/archive/20260506090626-prioritize-selection-context-copy
  openspec/changes/archive/20260506095404-simplify-selection-logic

Priority hierarchy (highest first):
  1. Pink Set (Ctrl+Click multi-word)
  2. Yellow Range (Shift-extend selection)
  3. Yellow Pointer (single word cursor)
  4. Context Copy / Active line (fallback)

ESC stage contract:
  Stage 1: clear Pink Set   (leaves Yellow Pointer intact)
  Stage 3: clear Yellow Pointer
"""
import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state


def test_ctrl_toggle_word_increments_selection_count(mpv):
    """Ctrl-toggling a word adds it to Pink Set; dw_selection_count becomes 1."""
    ipc = mpv.ipc
    ipc.command(['script-message-to', 'kardenwort', 'test-ctrl-toggle-word', '1', '0'])
    time.sleep(0.1)
    state = query_kardenwort_state(ipc)
    assert state['dw_selection_count'] == 1, (
        f"Expected dw_selection_count=1 after one Ctrl+toggle, got {state['dw_selection_count']}"
    )


def test_ctrl_toggle_same_word_twice_removes_it(mpv):
    """Ctrl-toggling the same word twice removes it (toggle semantics); count returns to 0."""
    ipc = mpv.ipc
    ipc.command(['script-message-to', 'kardenwort', 'test-ctrl-toggle-word', '1', '0'])
    time.sleep(0.1)
    ipc.command(['script-message-to', 'kardenwort', 'test-ctrl-toggle-word', '1', '0'])
    time.sleep(0.1)
    state = query_kardenwort_state(ipc)
    assert state['dw_selection_count'] == 0, (
        f"Expected dw_selection_count=0 after double-toggle, got {state['dw_selection_count']}"
    )


def test_multiple_words_build_pending_list(mpv):
    """Adding three words via Ctrl-toggle builds a pending list of count 3."""
    ipc = mpv.ipc
    # Fixture sub 1: "Hello world" — word indices 0 and 1 exist.
    # Add word 0 from line 1 and words 0,1 from line 2 ("This is a test").
    ipc.command(['script-message-to', 'kardenwort', 'test-ctrl-toggle-word', '1', '0'])
    time.sleep(0.05)
    ipc.command(['script-message-to', 'kardenwort', 'test-ctrl-toggle-word', '2', '0'])
    time.sleep(0.05)
    ipc.command(['script-message-to', 'kardenwort', 'test-ctrl-toggle-word', '2', '1'])
    time.sleep(0.1)
    state = query_kardenwort_state(ipc)
    assert state['dw_selection_count'] == 3, (
        f"Expected dw_selection_count=3 after three toggles, got {state['dw_selection_count']}"
    )


def test_esc_stage1_clears_pink_set_leaves_pointer(mpv):
    """ESC Stage 1: clears Pink Set without touching the Yellow Pointer."""
    ipc = mpv.ipc
    # Establish Pink Set (word 0 of line 1) and Yellow Pointer (word 1 of line 1)
    ipc.command(['script-message-to', 'kardenwort', 'test-ctrl-toggle-word', '1', '0'])
    time.sleep(0.1)
    ipc.command(['script-message-to', 'kardenwort', 'test-set-cursor', '1', '1'])
    time.sleep(0.1)

    pre = query_kardenwort_state(ipc)
    assert pre['dw_selection_count'] == 1, "precondition: Pink Set must be non-empty"
    assert pre['dw_cursor']['word'] == 1, "precondition: Yellow Pointer must be set"

    ipc.command(['script-message-to', 'kardenwort', 'test-dw-esc'])
    time.sleep(0.1)

    post = query_kardenwort_state(ipc)
    assert post['dw_selection_count'] == 0, (
        "ESC Stage 1 must clear Pink Set"
    )
    assert post['dw_cursor']['word'] == 1, (
        "ESC Stage 1 must NOT clear Yellow Pointer"
    )


def test_esc_stage3_clears_pointer_when_no_pink(mpv):
    """ESC Stage 3: with no Pink Set and no range, clears the Yellow Pointer."""
    ipc = mpv.ipc
    ipc.command(['script-message-to', 'kardenwort', 'test-set-cursor', '1', '1'])
    time.sleep(0.1)

    pre = query_kardenwort_state(ipc)
    assert pre['dw_cursor']['word'] == 1, "precondition: Yellow Pointer must be set"
    assert pre['dw_selection_count'] == 0, "precondition: Pink Set must be empty"

    ipc.command(['script-message-to', 'kardenwort', 'test-dw-esc'])
    time.sleep(0.1)

    post = query_kardenwort_state(ipc)
    assert post['dw_cursor']['word'] == -1, (
        "ESC Stage 3 must clear Yellow Pointer (word returns to -1)"
    )
    assert post['dw_selection_count'] == 0


def test_two_esc_presses_clear_pink_then_pointer(mpv):
    """Two successive ESC presses clear Pink Set first, then Yellow Pointer."""
    ipc = mpv.ipc
    ipc.command(['script-message-to', 'kardenwort', 'test-ctrl-toggle-word', '1', '0'])
    time.sleep(0.1)
    ipc.command(['script-message-to', 'kardenwort', 'test-set-cursor', '1', '1'])
    time.sleep(0.1)

    # First ESC: clears Pink Set
    ipc.command(['script-message-to', 'kardenwort', 'test-dw-esc'])
    time.sleep(0.1)
    mid = query_kardenwort_state(ipc)
    assert mid['dw_selection_count'] == 0, "First ESC should clear Pink Set"
    assert mid['dw_cursor']['word'] == 1, "First ESC should leave Yellow Pointer"

    # Second ESC: clears Yellow Pointer
    ipc.command(['script-message-to', 'kardenwort', 'test-dw-esc'])
    time.sleep(0.1)
    final = query_kardenwort_state(ipc)
    assert final['dw_cursor']['word'] == -1, "Second ESC should clear Yellow Pointer"




