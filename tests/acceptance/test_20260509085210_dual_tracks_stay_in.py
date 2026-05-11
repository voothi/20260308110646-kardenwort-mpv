"""
Feature ZID: 20260509085210
Test Creation ZID: 20260509085637
Feature: Dual Tracks Stay In
"""

# Scenario: Primary and secondary subtitle tracks stay in sync across two failure modes:
#
# 1. PLAYBACK DESYNC (padded overlap zone)
#    Fixtures have a 200ms gap: sub 1 ends at 2.000s, sub 2 starts at 2.200s.
#    Default Options: audio_padding_end=200ms, audio_padding_start=200ms.
#    Overlap zone at 2.000s: secondary's Overlap Priority fires while primary's Sticky
#    Sentinel still holds — causing 1-index desync during continuous playback.
#    Fix: FSM.SEC_ACTIVE_IDX sentinel mirrors ACTIVE_IDX logic for the secondary track.
#
# 2. NAVIGATION DESYNC (a/d key seek with large padding)
#    When cmd_dw_seek_delta explicitly sets FSM.ACTIVE_IDX = target_idx but does not
#    update FSM.SEC_ACTIVE_IDX, the secondary sentinel holds at the old sub when its
#    padded window still contains the new seek position (e.g. short sub with 1s padding).
#    Fix: set FSM.SEC_ACTIVE_IDX = target_idx wherever ACTIVE_IDX is explicitly assigned.
import time
from tests.ipc.mpv_ipc import query_kardenwort_state


def test_dual_tracks_stay_in_sync_through_padded_overlap(mpv_dual):
    ipc = mpv_dual.ipc

    # Step 1: Land inside sub 1 at exactly 1.0s (integer keyframe) to prime both sentinels.
    ipc.command(['seek', 1.0, 'absolute+exact'])
    time.sleep(0.15)

    state = query_kardenwort_state(ipc)
    assert state['active_sub_index'] == 1, (
        f"expected sentinels primed at sub 1 (pri={state['active_sub_index']}, "
        f"sec={state['sec_active_sub_index']}) after seek to 1.0s"
    )
    assert state['sec_active_sub_index'] == 1

    # Step 2: seek(1.5) snaps to 2.0s in the 1fps fixture — the exact overlap zone.
    # Sub 1's padded end (2.200s) has not yet expired, so the sentinel must hold both
    # tracks at index 1. Without the fix, the secondary's Overlap Priority (triggered at
    # sub 2's padded start = 2.000s) would advance it to index 2.
    ipc.command(['seek', 1.5, 'absolute+exact'])
    time.sleep(0.15)

    state = query_kardenwort_state(ipc)
    assert state['active_sub_index'] == state['sec_active_sub_index'], (
        f"primary index {state['active_sub_index']} != "
        f"secondary index {state['sec_active_sub_index']} in padded overlap zone at ~2.0s"
    )
    assert state['active_sub_index'] == 1, (
        f"both tracks should stay on sub 1 (padded end 2.200s not yet expired at 2.000s), "
        f"got index {state['active_sub_index']}"
    )


def test_navigation_seek_syncs_both_sentinels(mpv_dual):
    """When d/a (cmd_dw_seek_delta) navigates to sub N, both sentinels must jump to N.

    Previously FSM.ACTIVE_IDX was set to target_idx but FSM.SEC_ACTIVE_IDX was not.
    With large padding the secondary sentinel's window still contained the new seek
    position, holding it at the old sub while primary showed the new one.
    """
    ipc = mpv_dual.ipc

    # Enable Drum Mode so the dw-seek-next binding is registered by manage_dw_bindings.
    ipc.command(['script-binding', 'kardenwort/toggle-drum-mode'])
    time.sleep(0.15)

    # Prime both sentinels at sub 1.
    ipc.command(['seek', 1.0, 'absolute+exact'])
    time.sleep(0.15)

    state = query_kardenwort_state(ipc)
    assert state['active_sub_index'] == 1
    assert state['sec_active_sub_index'] == 1

    # Navigate forward one subtitle (equivalent to pressing d).
    # Default dw_key_seek_next = "d в"; the binding name is dw-seek-next-1.
    ipc.command(['script-binding', 'kardenwort/dw-seek-next-1'])
    time.sleep(0.15)

    state = query_kardenwort_state(ipc)
    assert state['active_sub_index'] == state['sec_active_sub_index'], (
        f"after d-seek: primary={state['active_sub_index']} != "
        f"secondary={state['sec_active_sub_index']} — sentinels desynced"
    )
    assert state['active_sub_index'] == 2, (
        f"expected both sentinels at sub 2 after seek-next, got {state['active_sub_index']}"
    )




