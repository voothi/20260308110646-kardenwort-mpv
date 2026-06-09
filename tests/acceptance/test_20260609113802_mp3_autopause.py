"""
Feature ZID: 20260609113802
Regression test: Autopause ON + PHRASE mode must stop playback at the
effective subtitle end when the media is an audio-only MP3 file backed by
the bundled black.mp4 virtual video track.

This test is intentionally self-contained: it does NOT import from
test_20260607194017_audio_only_subtitles.py so the two tests can be moved
or refactored independently.

Validated against openspec spec: audio-only-media
(coarse-tick fallback scenario).

Timeline used by the embedded SRT:
    Sub 1: 1.000 - 2.000
    Sub 2: 3.000 - 4.000
    Sub 3: 5.000 - 6.000

With audio_padding_end = 200 ms and audio_padding_start = 0, the PHRASE
effective_end for Sub 2 is 4.000 + 0.2 = 4.200 s.  The test seeks to Sub 2
start (3.0 s), unpauses, and verifies that autopause fires with
last_paused_sub_end ~= 4.200 s.
"""

import shutil
import subprocess
import time
import uuid
from pathlib import Path

import pytest

from tests.ipc.mpv_ipc import query_kardenwort_state
from tests.ipc.mpv_session import MpvSession


# ---------------------------------------------------------------------------
# Local helpers (kept private to this file so other refactors don't break us)
# ---------------------------------------------------------------------------

def _wait_until(condition, timeout=4.0, step=0.1):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if condition():
            return True
        time.sleep(step)
    return False


def _new_scratch_dir(prefix):
    base = Path("scratch") / "acceptance"
    base.mkdir(parents=True, exist_ok=True)
    work = base / f"{prefix}-{uuid.uuid4().hex[:8]}"
    work.mkdir(parents=True, exist_ok=False)
    return work


def _start_or_skip(session):
    try:
        session.start()
    except TimeoutError as exc:
        session.stop()
        pytest.skip(f"mpv IPC unavailable in this environment: {exc}")


def _create_silent_mp3(dst_audio, duration=20):
    cmd = [
        "ffmpeg", "-y",
        "-f", "lavfi",
        "-i", "anullsrc=channel_layout=mono:sample_rate=44100",
        "-t", str(duration),
        "-c:a", "libmp3lame",
        "-b:a", "128k",
        str(dst_audio),
    ]
    subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)


# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------

def test_mp3_autopause_on_phrase_stops_at_subtitle_end():
    work = _new_scratch_dir("audio-only-autopause-mp3")
    media_mp3 = work / "audio.mp3"
    media_srt = work / "audio.en.srt"

    subtitle_content = """1
00:00:01,000 --> 00:00:02,000
Line One

2
00:00:03,000 --> 00:00:04,000
Line Two

3
00:00:05,000 --> 00:00:06,000
Line Three
"""
    media_srt.write_text(subtitle_content, encoding="utf-8")
    _create_silent_mp3(media_mp3, duration=20)

    session = MpvSession(
        video=str(media_mp3),
        subtitle=str(media_srt),
        extra_args=[
            "--pause",
            "--script-opts=kardenwort-companion_subtitle_attach_on_load=no",
        ],
    )
    _start_or_skip(session)
    try:
        ipc = session.ipc

        # 1. Wait until subtitles are parsed.
        def subs_ready():
            state = query_kardenwort_state(ipc)
            return (
                state.get("pri_sub_count") == 3
                and state.get("playback_state") in ("SINGLE_SRT", "DUAL_SRT")
            )

        assert _wait_until(subs_ready, timeout=6.0), (
            "Subtitles were not loaded - kardenwort did not report 3 primary "
            "subtitles in SINGLE_SRT/DUAL_SRT state."
        )

        # 2. Enable Autopause ON + PHRASE mode and set tight paddings.
        ipc.command(["script-message-to", "kardenwort", "autopause-set", "ON"])
        ipc.command(["script-message-to", "kardenwort", "immersion-mode-set", "PHRASE"])
        ipc.command(
            ["script-message-to", "kardenwort", "test-set-option",
             "audio_padding_start", "0"]
        )
        ipc.command(
            ["script-message-to", "kardenwort", "test-set-option",
             "audio_padding_end", "200"]
        )
        time.sleep(0.15)

        # 3. Seek to Sub 2 start and unpause - let autopause do its job.
        ipc.command(["seek", 3.0, "absolute+exact"])
        time.sleep(0.25)
        ipc.command(["set_property", "pause", False])

        # 4. Wait for autopause to fire (player should pause near 4.2 s).
        paused = _wait_until(lambda: ipc.get_property("pause"), timeout=5.0)

        pos = ipc.get_property("time-pos")
        state = query_kardenwort_state(ipc)

        # Diagnostic dump on failure paths.
        print(f"DEBUG pos={pos:.3f} paused={paused}")
        print(f"DEBUG state={state}")
        print(f"DEBUG sid={ipc.get_property('sid')} vid={ipc.get_property('vid')}")
        print(f"DEBUG track_list={ipc.get_property('track-list')}")

        assert paused, (
            "Autopause ON + PHRASE did NOT stop playback on MP3 + black.mp4 "
            f"(pos={pos:.3f}, state={state})"
        )

        # 5. Verify that the pause was triggered exactly at the PHRASE
        #    effective end of Sub 2 (raw end 4.000 + 0.2 pad = 4.200 s).
        lpe = state.get("last_paused_sub_end")
        assert lpe is not None, (
            "last_paused_sub_end was not set - autopause did not record a "
            f"subtitle boundary (state={state})"
        )
        assert abs(lpe - 4.2) < 0.15, (
            f"Expected last_paused_sub_end ~= 4.200 s, got {lpe:.3f} s "
            f"(pos={pos:.3f}, state={state})"
        )

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)


def test_mp3_autopause_on_phrase_near_subtitle_boundary():
    """Regression coverage: starting playback very close to a subtitle end
    on MP3 + black.mp4 can stress the autopause boundary detection.  Autopause
    must fire at one of the subtitle ends rather than running past them all.

    Subtitles:
        Sub 1: 1.000 – 2.000
        Sub 2: 3.000 – 4.000
        Sub 3: 5.000 – 20.000

    We seek to 1.90 s (100 ms before Sub 1 end).  With a 1 fps black.mp4
    track, time-pos may jump in coarse steps, but autopause should still
    catch a boundary instead of skipping through all subtitles.
    """
    work = _new_scratch_dir("audio-only-autopause-near-boundary")
    media_mp3 = work / "audio.mp3"
    media_srt = work / "audio.en.srt"

    subtitle_content = """1
00:00:01,000 --> 00:00:02,000
Line One

2
00:00:03,000 --> 00:00:04,000
Line Two

3
00:00:05,000 --> 00:00:20,000
Line Three
"""
    media_srt.write_text(subtitle_content, encoding="utf-8")
    _create_silent_mp3(media_mp3, duration=25)

    session = MpvSession(
        video=str(media_mp3),
        subtitle=str(media_srt),
        extra_args=[
            "--pause",
            "--script-opts=kardenwort-companion_subtitle_attach_on_load=no",
        ],
    )
    _start_or_skip(session)
    try:
        ipc = session.ipc

        def subs_ready():
            state = query_kardenwort_state(ipc)
            return (
                state.get("pri_sub_count") == 3
                and state.get("playback_state") in ("SINGLE_SRT", "DUAL_SRT")
            )

        assert _wait_until(subs_ready, timeout=6.0), (
            "Subtitles were not loaded - kardenwort did not report 3 primary "
            "subtitles in SINGLE_SRT/DUAL_SRT state."
        )

        # Enable Autopause ON + PHRASE, zero padding for a sharp boundary.
        ipc.command(["script-message-to", "kardenwort", "autopause-set", "ON"])
        ipc.command(["script-message-to", "kardenwort", "immersion-mode-set", "PHRASE"])
        ipc.command(
            ["script-message-to", "kardenwort", "test-set-option",
             "audio_padding_start", "0"]
        )
        ipc.command(
            ["script-message-to", "kardenwort", "test-set-option",
             "audio_padding_end", "0"]
        )
        time.sleep(0.15)

        # Seek to 1.90 s – inside Sub 1, only 100 ms before its end at 2.0 s.
        ipc.command(["seek", 1.9, "absolute+exact"])
        time.sleep(0.25)
        ipc.command(["set_property", "pause", False])

        # Wait for autopause to fire (must happen before Sub 3 end at 20 s).
        paused = _wait_until(lambda: ipc.get_property("pause"), timeout=8.0)

        pos = ipc.get_property("time-pos")
        state = query_kardenwort_state(ipc)

        # Diagnostic dump on failure paths.
        print(f"DEBUG pos={pos:.3f} paused={paused}")
        print(f"DEBUG state={state}")
        print(f"DEBUG sid={ipc.get_property('sid')} vid={ipc.get_property('vid')}")
        print(f"DEBUG track_list={ipc.get_property('track-list')}")

        assert paused, (
            "Autopause ON + PHRASE did NOT stop playback on MP3 + black.mp4 "
            f"near a coarse tick boundary (pos={pos:.3f}, state={state})"
        )

        # Accept pause at Sub 1 (2.0 s) or Sub 2 (4.0 s) – the coarse 1 fps
        # clock may skip Sub 1 and land on Sub 2 because the gap between
        # them (2.0 – 3.0 s) lets the 1 fps tick jump from ~1.95 s straight
        # into Sub 2's range.  Sub 3 (20.0 s) is intentionally excluded:
        # accepting it would also pass if the entire autopause mechanism
        # were broken and the player only paused at the very last subtitle.
        lpe = state.get("last_paused_sub_end")
        assert lpe is not None, (
            "last_paused_sub_end was not set - autopause did not record a "
            f"subtitle boundary (state={state})"
        )
        assert lpe in (2.0, 4.0), (
            f"Expected last_paused_sub_end to be Sub 1 end (2.0 s) or Sub 2 "
            f"end (4.0 s), got {lpe:.3f} s (pos={pos:.3f})"
        )
        assert abs(pos - lpe) < 0.50, (
            f"Player pos={pos:.3f} s deviates too far from "
            f"last_paused_sub_end={lpe:.3f} s"
        )

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)
