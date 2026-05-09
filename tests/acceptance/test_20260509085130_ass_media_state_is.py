"""
Feature ZID: 20260509085130
Test Creation ZID: 20260509085637
Feature: Ass Media State Is
Tests for ASS gatekeeping and FSM architecture hardening.

Covers:
  openspec/changes/archive/20260506190022-fsm-architecture-deficiency-remediation
    — ASS gatekeeping: Drum Mode and Drum Window forced OFF when ASS track loaded.
  openspec/changes/archive/20260506135440-fsm-architecture-specification-hardening
    — Sticky Focus Sentinel prevents "Padding Trap" premature subtitle handover.

ASS gatekeeping contract:
  When MEDIA_STATE matches "ASS":
    • FSM.DRUM  is forced to "OFF" at track-load time.
    • FSM.DRUM_WINDOW is forced to "OFF" at track-load time.
    • cmd_toggle_drum() refuses to enable Drum Mode.
"""
import time
import pytest
from tests.ipc.mpv_ipc import query_lls_state


# ---------------------------------------------------------------------------
# ASS Gatekeeping (20260506190022)
# ---------------------------------------------------------------------------

def test_ass_media_state_is_single_ass(mpv_ass):
    """Loading an ASS subtitle sets playback_state to SINGLE_ASS."""
    state = query_lls_state(mpv_ass.ipc)
    assert 'ASS' in state['playback_state'], (
        f"Expected playback_state to contain 'ASS', got {state['playback_state']!r}"
    )


def test_ass_gatekeeper_drum_mode_starts_off(mpv_ass):
    """Drum Mode is forced OFF when an ASS subtitle track is active."""
    state = query_lls_state(mpv_ass.ipc)
    assert state['drum_mode'] == 'OFF', (
        f"ASS gatekeeping must force drum_mode=OFF; got {state['drum_mode']!r}"
    )


def test_ass_gatekeeper_drum_window_starts_off(mpv_ass):
    """Drum Window is forced OFF when an ASS subtitle track is active."""
    state = query_lls_state(mpv_ass.ipc)
    assert state['drum_window'] == 'OFF', (
        f"ASS gatekeeping must force drum_window=OFF; got {state['drum_window']!r}"
    )


def test_ass_gatekeeper_blocks_drum_mode_toggle(mpv_ass):
    """Attempting to toggle Drum Mode with ASS loaded keeps it OFF."""
    ipc = mpv_ass.ipc
    ipc.command(['script-binding', 'lls_core/toggle-drum-mode'])
    time.sleep(0.15)
    state = query_lls_state(ipc)
    assert state['drum_mode'] == 'OFF', (
        f"cmd_toggle_drum must refuse to enable Drum Mode when ASS is loaded; "
        f"got {state['drum_mode']!r}"
    )


# ---------------------------------------------------------------------------
# Sticky Sentinel / Padding Trap (20260506135440)
# ---------------------------------------------------------------------------
# The canonical test_natural_progression_skip in test_archived_changes.py already
# covers the cross-sub handover via the overlap zone. The tests below complement
# it with boundary conditions from the specification.

def test_sentinel_primes_on_seek_into_sub(mpv_dual):
    """Seeking into the middle of a subtitle primes the sentinel and sets active_sub_index."""
    ipc = mpv_dual.ipc
    # Fixture sync-test: sub 1 spans 1.000–2.000s
    ipc.command(['seek', 1.5, 'absolute+exact'])
    time.sleep(0.2)
    state = query_lls_state(ipc)
    assert state['active_sub_index'] == 1, (
        f"Sentinel should select sub 1 at 1.5s; got {state['active_sub_index']}"
    )


def test_sentinel_remains_on_active_sub_before_srt_end(mpv_dual):
    """Primed sentinel keeps active_sub_index on sub 1 at a time within its SRT window."""
    ipc = mpv_dual.ipc
    # Prime at 1.0s (clearly in sub 1: 1.000–2.000s)
    ipc.command(['seek', 1.0, 'absolute+exact'])
    time.sleep(0.15)
    assert query_lls_state(ipc)['active_sub_index'] == 1

    # Seek to 1.8s — still inside sub 1's SRT window; active index must not advance
    ipc.command(['seek', 1.8, 'absolute+exact'])
    time.sleep(0.15)
    state = query_lls_state(ipc)
    assert state['active_sub_index'] == 1, (
        f"Active index must stay at 1 at 1.8s (sub 1 SRT window 1.0–2.0s); "
        f"got {state['active_sub_index']}"
    )


def test_secondary_sentinel_mirrors_primary(mpv_dual):
    """Secondary track sentinel stays in sync with primary after a seek."""
    ipc = mpv_dual.ipc
    ipc.command(['seek', 1.5, 'absolute+exact'])
    time.sleep(0.2)
    state = query_lls_state(ipc)
    assert state['active_sub_index'] == state['sec_active_sub_index'], (
        f"Primary and secondary sentinels must match at 1.5s; "
        f"pri={state['active_sub_index']}, sec={state['sec_active_sub_index']}"
    )
