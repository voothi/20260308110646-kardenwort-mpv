"""
Feature ZID: 20260512223306
Test Creation ZID: 20260512223306
Feature: Repeated Replay preserves dual-track synchronization
"""

import time
from tests.ipc.mpv_ipc import query_kardenwort_state


def test_replay_repeat_keeps_dual_indices_synced_autopause_on(mpv_dual):
    ipc = mpv_dual.ipc
    ipc.command(["script-message-to", "kardenwort", "autopause-set", "ON"])
    ipc.command(["set_property", "options/kardenwort-replay_count", "2"])
    time.sleep(0.1)

    # Land in subtitle 2 so replay start falls into subtitle 1 window.
    ipc.command(["seek", 2.4, "absolute+exact"])
    time.sleep(0.2)

    for _ in range(5):
        ipc.command(["script-message-to", "kardenwort", "test-replay"])
        time.sleep(0.12)
        state = query_kardenwort_state(ipc)
        assert state["active_sub_index"] == state["sec_active_sub_index"], (
            f"Replay ON desync: pri={state['active_sub_index']} sec={state['sec_active_sub_index']}"
        )


def test_replay_repeat_keeps_dual_indices_synced_autopause_off(mpv_dual):
    ipc = mpv_dual.ipc
    ipc.command(["script-message-to", "kardenwort", "autopause-set", "OFF"])
    ipc.command(["set_property", "options/kardenwort-replay_count", "2"])
    time.sleep(0.1)

    ipc.command(["seek", 2.4, "absolute+exact"])
    time.sleep(0.2)

    for _ in range(5):
        ipc.command(["script-message-to", "kardenwort", "test-replay"])
        time.sleep(0.12)
        state = query_kardenwort_state(ipc)
        assert state["active_sub_index"] == state["sec_active_sub_index"], (
            f"Replay OFF desync: pri={state['active_sub_index']} sec={state['sec_active_sub_index']}"
        )

