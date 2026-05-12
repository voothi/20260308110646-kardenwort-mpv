"""
Feature ZID: 20260512222730
Test Creation ZID: 20260512223046
Feature: Shift+A/D seek-time immediate dual-track anchoring
"""

import time
from tests.ipc.mpv_ipc import query_kardenwort_state


def _src():
    with open("scripts/kardenwort/main.lua", encoding="utf-8") as f:
        return f.read()


def _cmd_seek_time_body():
    src = _src()
    start = src.find("local function cmd_seek_time(dir)")
    assert start != -1, "cmd_seek_time not found"
    end = src.find("\nlocal function ", start + 1)
    return src[start: end if end != -1 else start + 5000]


def test_cmd_seek_time_anchors_secondary_idx_structurally():
    """cmd_seek_time must immediately anchor SEC_ACTIVE_IDX to sec target index."""
    body = _cmd_seek_time_body()
    assert "local sec_target_idx" in body, "sec_target_idx computation missing in cmd_seek_time"
    assert "FSM.SEC_ACTIVE_IDX = sec_target_idx" in body, (
        "cmd_seek_time does not anchor FSM.SEC_ACTIVE_IDX immediately"
    )
    assert "FSM.ACTIVE_IDX = target_idx" in body, (
        "cmd_seek_time does not anchor FSM.ACTIVE_IDX immediately"
    )


def test_shift_ad_time_seek_syncs_both_indices_immediately(mpv_dual):
    """A/D time seek must move both primary and secondary indices without cooldown lag."""
    ipc = mpv_dual.ipc

    # Prime both sentinels on sub 1.
    ipc.command(["seek", 1.0, "absolute+exact"])
    time.sleep(0.15)
    state = query_kardenwort_state(ipc)
    assert state["active_sub_index"] == 1
    assert state["sec_active_sub_index"] == 1

    # Trigger Shift+D equivalent (time-based +2s seek) through test hook.
    ipc.command(["script-message-to", "kardenwort", "test-seek-time", "1"])
    time.sleep(0.08)

    # Assert immediate dual-track synchronization.
    state = query_kardenwort_state(ipc)
    assert state["active_sub_index"] == state["sec_active_sub_index"], (
        f"After time-seek forward: pri={state['active_sub_index']} sec={state['sec_active_sub_index']}"
    )
    assert state["active_sub_index"] == 2, (
        f"Expected both tracks to be anchored at sub 2 after +2s seek, got {state['active_sub_index']}"
    )

