"""
Tests for Drum Mode tooltip key parity with Drum Window.

Covers:
  openspec/changes/archive/20260506195038-drum-mode-tooltip-key-parity

Key contracts:
  is_drum_tooltip_mode_eligible() == True  iff:
    FSM.DRUM == "ON"
    FSM.DRUM_WINDOW == "OFF"
    FSM.native_sub_vis == true
    MEDIA_STATE does not contain "ASS"
    Options.osd_interactivity is enabled (default True)

  Tooltip must NOT activate when:
    — Drum Mode is OFF
    — Drum Window is open (DW takes ownership)
    — ASS subtitle is loaded (drum mode is blocked entirely)
"""
import time
import pytest
from tests.ipc.mpv_ipc import query_lls_state, query_lls_render


# ---------------------------------------------------------------------------
# Eligibility preconditions (20260506195038)
# ---------------------------------------------------------------------------

def test_drum_tooltip_conditions_met_in_drum_mode(mpv):
    """With Drum Mode ON and Drum Window OFF, eligibility conditions are satisfied."""
    ipc = mpv.ipc
    ipc.command(['script-binding', 'lls_core/toggle-drum-mode'])
    time.sleep(0.15)
    state = query_lls_state(ipc)

    assert state['drum_mode'] == 'ON', "drum_mode must be ON"
    assert state['drum_window'] == 'OFF', "drum_window must be OFF"
    assert state['native_sub_vis'] is True, "native_sub_vis must be True"
    assert 'ASS' not in state['playback_state'], "playback_state must not be ASS"


def test_drum_tooltip_ineligible_when_drum_window_open(mpv):
    """Opening Drum Window while Drum Mode is ON moves tooltip ownership to DW."""
    ipc = mpv.ipc
    ipc.command(['script-binding', 'lls_core/toggle-drum-mode'])
    time.sleep(0.15)
    assert query_lls_state(ipc)['drum_mode'] == 'ON'

    ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
    time.sleep(0.15)
    state = query_lls_state(ipc)

    # is_drum_tooltip_mode_eligible() requires drum_window == "OFF"
    assert state['drum_window'] != 'OFF', "Drum Window must be open"
    # drum_mode is managed by Drum Window; the drum-tooltip path is not eligible
    # Verifiable: drum_mode == "ON" coexists with drum_window != "OFF"
    # (DW takes tooltip ownership when it's open)


def test_drum_tooltip_ineligible_when_sub_hidden(mpv):
    """Hiding subtitles makes is_drum_tooltip_mode_eligible() return False."""
    ipc = mpv.ipc
    ipc.command(['script-binding', 'lls_core/toggle-drum-mode'])
    time.sleep(0.15)

    # Hide native subtitles
    ipc.command(['script-message-to', 'lls_core', 'lls-toggle-sub-vis'])
    time.sleep(0.1)
    state = query_lls_state(ipc)

    assert state['native_sub_vis'] is False, "native_sub_vis must be False after toggle"
    assert state['drum_mode'] == 'ON', "drum_mode should still be ON"
    # With native_sub_vis=False, is_drum_tooltip_mode_eligible() returns False


def test_drum_tooltip_ineligible_when_ass_loaded(mpv_ass):
    """ASS gatekeeping prevents Drum Mode from enabling, so tooltip is unavailable."""
    ipc = mpv_ass.ipc
    state = query_lls_state(ipc)
    assert 'ASS' in state['playback_state']
    assert state['drum_mode'] == 'OFF', "Drum Mode blocked by ASS gatekeeping"

    # Attempting to enable drum mode must still fail
    ipc.command(['script-binding', 'lls_core/toggle-drum-mode'])
    time.sleep(0.15)
    state = query_lls_state(ipc)
    assert state['drum_mode'] == 'OFF', (
        "Drum Mode (and therefore drum tooltip) must remain OFF with ASS loaded"
    )


# ---------------------------------------------------------------------------
# Tooltip render path — drum mode vs drum window (20260506195038)
# ---------------------------------------------------------------------------

def test_drum_mode_tooltip_render_initially_empty(mpv):
    """Tooltip OSD starts empty; no spurious content in Drum Mode without activation."""
    ipc = mpv.ipc
    ipc.command(['script-binding', 'lls_core/toggle-drum-mode'])
    time.sleep(0.15)

    render = query_lls_render(ipc, 'tooltip')
    assert render == '', (
        f"Tooltip OSD must be empty before any activation; got {render[:80]!r}"
    )


def test_drum_window_tooltip_render_initially_empty(mpv):
    """Tooltip OSD starts empty when Drum Window opens without activation."""
    ipc = mpv.ipc
    ipc.command(['script-message-to', 'lls_core', 'lls-drum-window-toggle'])
    time.sleep(0.15)

    render = query_lls_render(ipc, 'tooltip')
    assert render == '', (
        f"Tooltip OSD must be empty before activation in Drum Window; got {render[:80]!r}"
    )
