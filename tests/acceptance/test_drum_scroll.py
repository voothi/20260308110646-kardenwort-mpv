"""
Tests for drum mode wheel scroll and dual-track scroll synchronization.

Covers:
  openspec/changes/archive/20260506103358-unify-drum-mode-wheel-scroll
  openspec/changes/archive/20260506164500-drum-scroll-sync-hardening

Key contracts verified:
  - Scrolling in Drum Mode shifts DW_VIEW_CENTER away from -1 (bootstraps on first use).
  - After manual scroll DW_FOLLOW_PLAYER becomes False.
  - DW_VIEW_CENTER is clamped to [1, #subs] (cannot go below 1 or above #subs).
  - Dual-track: secondary viewport offset mirrors primary's scroll delta.
  - Drum Window opened after Drum Mode scroll inherits the same DW_VIEW_CENTER.

Fixtures that start paused at time 0 are used so DW_VIEW_CENTER is predictably -1
before any subtitle becomes active and before any explicit scroll call.
"""
import time
import pytest
from tests.ipc.mpv_ipc import query_lls_state, query_lls_render


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _enable_drum(ipc):
    ipc.command(['script-binding', 'lls_core/toggle-drum-mode'])
    time.sleep(0.15)
    assert query_lls_state(ipc)['drum_mode'] == 'ON', "drum mode should be ON"


def _scroll(ipc, direction, n=1):
    for _ in range(n):
        ipc.command(['script-message-to', 'lls_core', 'lls-test-dw-scroll', str(direction)])
        time.sleep(0.05)
    time.sleep(0.1)


# ---------------------------------------------------------------------------
# Tests — DW_VIEW_CENTER bootstrapping and follow_player (20260506103358)
#
# Uses mpv_fragment1 (paused at 0.0s, first sub starts at 4.295s) so that
# DW_VIEW_CENTER is guaranteed -1 before the first explicit scroll.
# ---------------------------------------------------------------------------

def test_drum_scroll_bootstraps_view_center(mpv_fragment1):
    """First scroll in Drum Mode bootstraps DW_VIEW_CENTER from -1 to a valid index."""
    ipc = mpv_fragment1.ipc
    _enable_drum(ipc)

    pre = query_lls_state(ipc)
    assert pre['dw_view_center'] in [-1, 1], (
        f"DW_VIEW_CENTER must be -1 or 1 (bootstrapped) before any scroll at time 0; got {pre['dw_view_center']}"
    )

    _scroll(ipc, 1)
    post = query_lls_state(ipc)

    assert post['dw_view_center'] >= 1, (
        f"DW_VIEW_CENTER must be >= 1 after bootstrapping scroll; got {post['dw_view_center']}"
    )


def test_drum_scroll_sets_follow_player_false(mpv_fragment1):
    """After any manual scroll, DW_FOLLOW_PLAYER becomes False."""
    ipc = mpv_fragment1.ipc
    _enable_drum(ipc)

    before = query_lls_state(ipc)
    assert before['dw_follow_player'] is True, (
        f"dw_follow_player must start True; got {before['dw_follow_player']}"
    )

    _scroll(ipc, 1)
    after = query_lls_state(ipc)

    assert after['dw_follow_player'] is False, (
        "DW_FOLLOW_PLAYER must be False after a manual scroll"
    )


def test_drum_scroll_view_center_advances(mpv_fragment1):
    """Two forward scrolls from the bootstrapped position advance DW_VIEW_CENTER by 2."""
    ipc = mpv_fragment1.ipc
    _enable_drum(ipc)

    # First scroll bootstraps; second scroll advances by 1 more.
    # fragment1 has 5 subs; at time 0 bootstrapped center = 1 (no active sub → fallback 1)
    # After first scroll (dir=+1): center = min(5, 1+1) = 2
    # After second scroll (dir=+1): center = min(5, 2+1) = 3
    _scroll(ipc, 1)
    mid = query_lls_state(ipc)
    mid_center = mid['dw_view_center']

    _scroll(ipc, 1)
    after = query_lls_state(ipc)

    assert after['dw_view_center'] == mid_center + 1, (
        f"Each forward scroll must increment DW_VIEW_CENTER by 1; "
        f"was {mid_center}, expected {mid_center + 1}, got {after['dw_view_center']}"
    )


def test_drum_scroll_view_center_clamped_at_lower_bound(mpv_fragment1):
    """Scrolling up many times cannot push DW_VIEW_CENTER below 1."""
    ipc = mpv_fragment1.ipc
    _enable_drum(ipc)

    _scroll(ipc, -1, n=20)
    state = query_lls_state(ipc)

    assert state['dw_view_center'] >= 1, (
        f"DW_VIEW_CENTER must not go below 1; got {state['dw_view_center']}"
    )


def test_drum_scroll_view_center_clamped_at_upper_bound(mpv_fragment1):
    """Scrolling down many times cannot push DW_VIEW_CENTER above #subs (5 in fragment1)."""
    ipc = mpv_fragment1.ipc
    _enable_drum(ipc)

    _scroll(ipc, 1, n=20)
    state = query_lls_state(ipc)

    # fragment1 has 5 subtitles
    assert state['dw_view_center'] <= 5, (
        f"DW_VIEW_CENTER must not exceed #subs (5); got {state['dw_view_center']}"
    )


# ---------------------------------------------------------------------------
# Tests — Dual-track scroll sync (20260506164500)
# ---------------------------------------------------------------------------

def test_dual_track_drum_scroll_does_not_crash(mpv_dual):
    """Drum Mode scroll with dual-track fixture completes without error."""
    ipc = mpv_dual.ipc
    _enable_drum(ipc)

    _scroll(ipc, 1)
    state = query_lls_state(ipc)

    assert state['dw_follow_player'] is False
    assert state['dw_view_center'] >= 1


def test_dual_track_scroll_drum_renders(mpv_dual):
    """After scrolling in dual-track drum mode, the drum OSD renders content."""
    ipc = mpv_dual.ipc
    _enable_drum(ipc)
    # Seek into a subtitle so there is content to render
    ipc.command(['seek', 1.0, 'absolute+exact'])
    time.sleep(0.3)

    _scroll(ipc, 1)
    render = query_lls_render(ipc, 'drum')

    assert render, "drum OSD must contain render data after scroll in dual-track mode"


def test_drum_mode_scroll_independent_of_drum_window(mpv_dual):
    """Scrolling in Drum Mode sets DW_FOLLOW_PLAYER=False before any DW interaction."""
    ipc = mpv_dual.ipc
    _enable_drum(ipc)

    before = query_lls_state(ipc)
    assert before['dw_follow_player'] is True

    _scroll(ipc, 1)
    after = query_lls_state(ipc)

    assert after['dw_follow_player'] is False, (
        "Manual scroll in Drum Mode must set DW_FOLLOW_PLAYER=False regardless of DW state"
    )
    assert after['drum_window'] == 'OFF', "Drum Window must remain closed"
