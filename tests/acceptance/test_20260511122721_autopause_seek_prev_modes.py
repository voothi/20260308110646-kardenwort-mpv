"""
Feature ZID: 20260511122721
Test Creation ZID: 20260511122721
Feature: Autopause timing after `a` (seek prev) in PHRASE vs MOVIE.

Scenario under test:
  - Autopause ON
  - audio_padding_start=1000ms
  - audio_padding_end=1000ms
  - press `a` (kardenwort-seek_prev path => cmd_seek_with_repeat -> cmd_dw_seek_delta(-1))

Expected current behavior:
  1) Seek target start for previous subtitle is identical in both modes:
       effective_start = sub.start_time - pad_start
  2) Playback stop boundary differs by immersion mode:
       PHRASE: effective_end = sub.end_time + pad_end
       MOVIE : effective_end = min(next.start_time - pad_start, clamped to >= sub.end_time)
               (with fragment1 Sub3 -> Sub4 and 1000ms start padding, clamp forces raw end)
"""

import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state


def _state(ipc, retries=8):
    for _ in range(retries):
        s = query_kardenwort_state(ipc)
        if s and "options" in s:
            return s
        time.sleep(0.2)
    return query_kardenwort_state(ipc)


def _seek(ipc, pos):
    ipc.command(["seek", pos, "absolute+exact"])
    time.sleep(0.2)


def _setup(ipc, mode):
    ipc.command(["script-message-to", "kardenwort", "kardenwort-autopause-set", "ON"])
    ipc.command(["script-message-to", "kardenwort", "kardenwort-immersion-mode-set", mode])
    ipc.command(["set_property", "options/kardenwort-audio_padding_start", "1000"])
    ipc.command(["set_property", "options/kardenwort-audio_padding_end", "1000"])
    ipc.command(["set_property", "pause", True])
    time.sleep(0.2)


def _seek_prev_a_path(ipc):
    # Exact path used by key `a` bindings in this project.
    ipc.command(["script-message-to", "kardenwort", "kardenwort-test-seek-delta", "-1"])
    time.sleep(0.25)


@pytest.mark.acceptance
@pytest.mark.parametrize("mode", ["PHRASE", "MOVIE"])
def test_seek_prev_lands_on_same_effective_start_in_phrase_and_movie(mpv_fragment1, mode):
    """
    `a` seeks to previous subtitle effective start in both modes.
    Fragment1 sub3 raw start = 11.175, with pad_start=1.0 => expected seek = 10.175.
    """
    ipc = mpv_fragment1.ipc
    _setup(ipc, mode)

    # Position on sub4, then press `a` once -> target sub3.
    _seek(ipc, 14.0)
    _seek_prev_a_path(ipc)

    pos = ipc.get_property("time-pos")
    assert abs(pos - 10.175) < 0.08, (
        f"{mode}: expected seek-prev landing near 10.175s, got {pos:.3f}s"
    )


@pytest.mark.acceptance
@pytest.mark.parametrize(
    "mode,expected_end",
    [
        ("PHRASE", 13.722),  # sub3 raw end 12.722 + 1.0s pad_end
        ("MOVIE", 12.722),   # handover would be 11.762, clamped to raw end 12.722
    ],
)
def test_seek_prev_autopause_end_differs_between_phrase_and_movie(mpv_fragment1, mode, expected_end):
    """
    After `a`, playback continues from previous subtitle start and autopause fires at mode-specific end.
    This locks in current behavior with 1000/1000 padding.
    """
    ipc = mpv_fragment1.ipc
    _setup(ipc, mode)

    _seek(ipc, 14.0)
    _seek_prev_a_path(ipc)

    # Start playback and wait for autopause to fire.
    ipc.command(["set_property", "pause", False])
    deadline = time.time() + 6.5
    while time.time() < deadline:
        if ipc.get_property("pause"):
            break
        time.sleep(0.05)
    ipc.command(["set_property", "pause", True])

    s = _state(ipc)
    lpe = s.get("last_paused_sub_end")
    assert lpe is not None, f"{mode}: autopause did not fire after seek-prev playback"
    assert abs(lpe - expected_end) < 0.08, (
        f"{mode}: expected last_paused_sub_end ~{expected_end:.3f}, got {lpe}"
    )




