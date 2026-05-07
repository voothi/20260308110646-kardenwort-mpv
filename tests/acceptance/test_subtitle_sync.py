# Scenario: Primary and secondary subtitle tracks stay in sync during playback
# when padded windows overlap (audio_padding_end + audio_padding_start > inter-sub gap).
#
# Fixtures (sync-test.en/ru.srt) have a 200ms gap: sub 1 ends at 2.000s, sub 2 starts at 2.200s.
# Default Options: audio_padding_end=200ms, audio_padding_start=200ms.
#
# Overlap zone at time_pos=2.000s (the test fixture MP4 is 1fps; seek(1.5) → snaps to 2.0):
#   Sub 1 padded end   = 2.000 + 0.200 = 2.200s  (sentinel must hold both tracks here)
#   Sub 2 padded start = 2.200 - 0.200 = 2.000s  (Overlap Priority fires at exactly 2.000s)
#
# Old code: Primary (Sticky Sentinel) stayed at index 1; Secondary (binary search, no sentinel)
#           advanced to index 2 via Overlap Priority → 1-index desync.
# Fix: FSM.SEC_ACTIVE_IDX sentinel mirrors ACTIVE_IDX logic for the secondary track.
import time
from tests.ipc.mpv_ipc import query_lls_state


def test_dual_tracks_stay_in_sync_through_padded_overlap(mpv_dual):
    ipc = mpv_dual.ipc

    # Step 1: Land inside sub 1 at exactly 1.0s (integer keyframe) to prime both sentinels.
    ipc.command(['seek', 1.0, 'absolute+exact'])
    time.sleep(0.15)

    state = query_lls_state(ipc)
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

    state = query_lls_state(ipc)
    assert state['active_sub_index'] == state['sec_active_sub_index'], (
        f"primary index {state['active_sub_index']} != "
        f"secondary index {state['sec_active_sub_index']} in padded overlap zone at ~2.0s"
    )
    assert state['active_sub_index'] == 1, (
        f"both tracks should stay on sub 1 (padded end 2.200s not yet expired at 2.000s), "
        f"got index {state['active_sub_index']}"
    )
