"""
Feature ZID: 20260512095351
Test Creation ZID: 20260512095351
Feature: DM selection geometry stability

Regression guard for DM ON mode where selecting text caused the visual boundary
between upper/lower subtitle windows to shift by a few pixels.
"""

import time
import pytest

from tests.ipc.mpv_ipc import query_kardenwort_state


def _query_drum_hit_zones(ipc):
    ipc.command(["script-message-to", "kardenwort", "test-query-hit-zones"])
    time.sleep(0.15)
    state = query_kardenwort_state(ipc)
    return state.get("test_data", {}).get("drum_hit_zones", [])


def _track_bounds(hit_zones, is_pri):
    zones = [z for z in hit_zones if bool(z.get("is_pri")) == is_pri]
    assert zones, f"No {'primary' if is_pri else 'secondary'} drum hit zones found"
    y_top = min(float(z["y_top"]) for z in zones)
    y_bottom = max(float(z["y_bottom"]) for z in zones)
    return y_top, y_bottom


def _inter_track_gap(pri_top, pri_bottom, sec_top, sec_bottom):
    if pri_top <= sec_top:
        upper_bottom = pri_bottom
        lower_top = sec_top
    else:
        upper_bottom = sec_bottom
        lower_top = pri_top
    return lower_top - upper_bottom


@pytest.mark.acceptance
def test_20260512095351_dm_selection_does_not_shift_track_bounds(mpv_fragment2):
    """
    In DM ON mode, selecting a word must not change the vertical envelope of either track.
    """
    ipc = mpv_fragment2.ipc

    ipc.command(["seek", "7.0", "absolute"])
    time.sleep(0.5)
    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    time.sleep(0.4)

    before = _query_drum_hit_zones(ipc)
    pri_top_0, pri_bottom_0 = _track_bounds(before, True)
    sec_top_0, sec_bottom_0 = _track_bounds(before, False)

    state = query_kardenwort_state(ipc)
    active_idx = int(state.get("active_sub_index") or 1)

    # Apply manual selection on active subtitle (word 1) to trigger highlight rendering.
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", str(active_idx), "1"])
    time.sleep(0.1)
    ipc.command(["script-message-to", "kardenwort", "test-ctrl-toggle-word", str(active_idx), "1"])
    time.sleep(0.3)

    after = _query_drum_hit_zones(ipc)
    pri_top_1, pri_bottom_1 = _track_bounds(after, True)
    sec_top_1, sec_bottom_1 = _track_bounds(after, False)

    assert pri_top_1 == pytest.approx(pri_top_0, abs=0.01)
    assert pri_bottom_1 == pytest.approx(pri_bottom_0, abs=0.01)
    assert sec_top_1 == pytest.approx(sec_top_0, abs=0.01)
    assert sec_bottom_1 == pytest.approx(sec_bottom_0, abs=0.01)


@pytest.mark.acceptance
def test_20260512095351_dm_selection_preserves_inter_track_gap(mpv_fragment2):
    """
    The vertical gap between DM upper/lower windows must remain constant after selection.
    """
    ipc = mpv_fragment2.ipc

    ipc.command(["seek", "7.0", "absolute"])
    time.sleep(0.5)
    ipc.command(["script-message-to", "kardenwort", "drum-mode-set", "ON"])
    time.sleep(0.4)

    before = _query_drum_hit_zones(ipc)
    pri_top_0, pri_bottom_0 = _track_bounds(before, True)
    sec_top_0, sec_bottom_0 = _track_bounds(before, False)

    # Determine upper/lower tracks by position, not by pri/sec semantics.
    gap_0 = _inter_track_gap(pri_top_0, pri_bottom_0, sec_top_0, sec_bottom_0)

    state = query_kardenwort_state(ipc)
    active_idx = int(state.get("active_sub_index") or 1)
    ipc.command(["script-message-to", "kardenwort", "test-set-cursor", str(active_idx), "1"])
    time.sleep(0.1)
    ipc.command(["script-message-to", "kardenwort", "test-ctrl-toggle-word", str(active_idx), "1"])
    time.sleep(0.3)

    after = _query_drum_hit_zones(ipc)
    pri_top_1, pri_bottom_1 = _track_bounds(after, True)
    sec_top_1, sec_bottom_1 = _track_bounds(after, False)

    gap_1 = _inter_track_gap(pri_top_1, pri_bottom_1, sec_top_1, sec_bottom_1)

    assert gap_1 == pytest.approx(gap_0, abs=0.01)
