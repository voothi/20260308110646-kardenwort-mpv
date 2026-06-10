"""
Feature ZID: 20260607194017
Feature: Support Audio-only (MP3) Subtitles and Interface Elements via Bundled Black Video Track

Validated against openspec spec: audio-only-media
"""

import shutil
import subprocess
import time
import uuid
from pathlib import Path

import pytest
from tests.ipc.mpv_session import MpvSession
from tests.ipc.mpv_ipc import query_kardenwort_render, query_kardenwort_state


_FIXTURE_VIDEO = Path(
    "tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.mp4"
)


def _wait_until(condition, timeout=4.0, step=0.1):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if condition():
            return True
        time.sleep(step)
    return False


def _get_video_tracks(track_list):
    videos = []
    for track in track_list or []:
        if track.get("type") == "video":
            videos.append(track)
    return videos


def _has_bundled_black_video(track_list):
    for video in _get_video_tracks(track_list):
        path = (
            video.get("external-filename") or
            video.get("external_filename") or
            video.get("path") or
            ""
        ).lower()
        if "black.mp4" in path:
            return True
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


def _create_mp3_only(src_video, dst_audio):
    cmd = ["ffmpeg", "-y", "-i", str(src_video), "-vn", "-acodec", "libmp3lame", str(dst_audio)]
    subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)


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


def _wait_for_rendered_subtitles(ipc):
    ipc.command(["seek", 2.0, "absolute+exact"])
    ipc.command(["set_property", "pause", True])

    render = ""
    def subtitles_rendered():
        nonlocal render
        render = query_kardenwort_render(ipc, "drum", timeout=1.0)
        return "Primary Subtitle Line" in render and "Secondary Subtitle Line" in render

    assert _wait_until(subtitles_rendered, timeout=4.0), (
        "Styled subtitle overlay did not render primary and secondary subtitles: "
        f"{render}"
    )
    assert "{\\pos(960, 1026)}{\\an2}" in render, (
        "Primary subtitle overlay was not bottom-positioned at sub-pos=95: "
        f"{render}"
    )
    assert "{\\pos(960, 108)}{\\an8}" in render, (
        "Secondary subtitle overlay was not top-positioned at secondary-sub-pos=10: "
        f"{render}"
    )


def test_audio_only_bundled_black_video():
    work = _new_scratch_dir("audio-only-bundled-black-video")
    media_mp3 = work / "sample.mp3"
    media_srt_pri = work / "sample.srt"
    media_srt_sec = work / "sample.en.srt"

    # Create dummy subtitle files
    subtitle_content_pri = """1
00:00:01,000 --> 00:00:04,000
Primary Subtitle Line
"""
    subtitle_content_sec = """1
00:00:01,000 --> 00:00:04,000
Secondary Subtitle Line
"""
    media_srt_pri.write_text(subtitle_content_pri, encoding="utf-8")
    media_srt_sec.write_text(subtitle_content_sec, encoding="utf-8")

    # Create a dummy MP3 audio file from the fixture video
    _create_mp3_only(_FIXTURE_VIDEO, media_mp3)

    session = MpvSession(
        video=str(media_mp3),
        subtitle=str(media_srt_pri),
        secondary_subtitle=str(media_srt_sec),
        extra_args=["--pause", "--sub-pos=95", "--secondary-sub-pos=10"]
    )
    _start_or_skip(session)
    try:
        # Wait until a video track is active
        def video_selected():
            vid = session.ipc.get_property("vid")
            return vid and vid != "no"

        assert _wait_until(video_selected, timeout=6.0), "Bundled black video track was not selected automatically"

        # Verify that the loaded video track is the bundled seekable black canvas
        tracks = session.ipc.get_property("track-list") or []
        vids = _get_video_tracks(tracks)

        assert len(vids) > 0, "No video tracks registered in track-list"
        assert _has_bundled_black_video(tracks), f"Bundled black video source was not loaded, tracks: {tracks}"

        # Verify that subtitles are loaded and selected
        def subs_selected():
            sid = session.ipc.get_property("sid")
            sec_sid = session.ipc.get_property("secondary-sid")
            return sid and sid != "no" and sec_sid and sec_sid != "no"

        assert _wait_until(subs_selected, timeout=3.0), "Subtitle tracks were not loaded or selected"

        # Check subtitle positioning properties are respected
        assert session.ipc.get_property("sub-pos") == 95, f"Expected sub-pos to be 95, got {session.ipc.get_property('sub-pos')}"
        assert session.ipc.get_property("secondary-sub-pos") == 10, f"Expected secondary-sub-pos to be 10, got {session.ipc.get_property('secondary-sub-pos')}"
        _wait_for_rendered_subtitles(session.ipc)

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)


def test_audio_only_autopause_on_phrase_stops_at_subtitle_end():
    """Regression test: Autopause ON + PHRASE mode must stop playback at the
    effective subtitle end when the media is an audio-only MP3 file backed by
    the bundled black.mp4 virtual video track (ZID 20260609113802).

    Timeline used:
      Sub 1: 1.000 – 2.000
      Sub 2: 3.000 – 4.000
      Sub 3: 5.000 – 6.000

    With default 200 ms padding (pad_end), PHRASE effective_end for Sub 2 is
    4.000 + 0.2 = 4.200 s.  The test seeks to Sub 2 start (3.0 s), unpauses,
    and verifies that autopause fires near 4.2 s.
    """
    work = _new_scratch_dir("audio-only-autopause")
    media_mp3 = work / "sample.mp3"
    media_srt = work / "sample.en.srt"

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

        # Wait until subtitles are parsed (SINGLE_SRT is fine – we only have one track)
        def subs_ready():
            state = query_kardenwort_state(ipc)
            return (
                state.get("pri_sub_count") == 3
                and state.get("playback_state") in ("SINGLE_SRT", "DUAL_SRT")
            )

        assert _wait_until(subs_ready, timeout=6.0), "Subtitles not loaded"

        # Enable autopause ON + PHRASE mode, zero padding for precision
        ipc.command(["script-message-to", "kardenwort", "autopause-set", "ON"])
        ipc.command(["script-message-to", "kardenwort", "immersion-mode-set", "PHRASE"])
        ipc.command(["script-message-to", "kardenwort", "test-set-option", "audio_padding_start", "0"])
        ipc.command(["script-message-to", "kardenwort", "test-set-option", "audio_padding_end", "200"])
        time.sleep(0.15)

        # Seek to Sub 2 start (3.0 s)
        ipc.command(["seek", 3.0, "absolute+exact"])
        time.sleep(0.25)

        # Unpause – let autopause do its job
        ipc.command(["set_property", "pause", False])

        # Wait for autopause to fire (player should pause near 4.2 s)
        paused = _wait_until(lambda: ipc.get_property("pause"), timeout=5.0)

        pos = ipc.get_property("time-pos")
        state = query_kardenwort_state(ipc)

        # Diagnostic dump
        print(f"DEBUG pos={pos:.3f} paused={paused}")
        print(f"DEBUG state={state}")
        print(f"DEBUG sid={ipc.get_property('sid')} vid={ipc.get_property('vid')}")
        print(f"DEBUG track_list={ipc.get_property('track-list')}")

        assert paused, (
            f"Autopause ON + PHRASE did NOT stop playback on MP3 + black.mp4 "
            f"(pos={pos:.3f}, state={state})"
        )

        lpe = state.get("last_paused_sub_end")

        # Sub 2 raw end = 4.000, pad_end = 200 ms → effective_end = 4.200
        assert lpe is not None, "last_paused_sub_end was not set (autopause did not fire)"
        assert abs(lpe - 4.2) < 0.15, (
            f"Expected last_paused_sub_end ≈ 4.200, got {lpe:.3f} (pos={pos:.3f})"
        )

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)


def test_audio_only_bundled_black_video_when_companion_fails():
    work = _new_scratch_dir("audio-only-bundled-black-video-fail")
    media_mp3 = work / "sample.mp3"
    media_srt_pri = work / "sample.srt"
    media_srt_sec = work / "sample.en.srt"
    corrupt_mp4 = work / "sample.mp4"

    # Create dummy subtitle files
    subtitle_content_pri = """1
00:00:01,000 --> 00:00:04,000
Primary Subtitle Line
"""
    subtitle_content_sec = """1
00:00:01,000 --> 00:00:04,000
Secondary Subtitle Line
"""
    media_srt_pri.write_text(subtitle_content_pri, encoding="utf-8")
    media_srt_sec.write_text(subtitle_content_sec, encoding="utf-8")

    # Create a dummy MP3 audio file from the fixture video
    _create_mp3_only(_FIXTURE_VIDEO, media_mp3)

    # Create a corrupt/empty companion video candidate
    corrupt_mp4.write_text("corrupt-invalid-video-data", encoding="utf-8")

    session = MpvSession(
        video=str(media_mp3),
        subtitle=str(media_srt_pri),
        secondary_subtitle=str(media_srt_sec),
        extra_args=["--pause", "--sub-pos=95", "--secondary-sub-pos=10"]
    )
    _start_or_skip(session)
    try:
        # Wait until a video track is active (should fall back to bundled black.mp4 after corrupt candidate fails)
        def video_selected():
            vid = session.ipc.get_property("vid")
            return vid and vid != "no"

        # Give it a bit more time because it has to fail-load first
        assert _wait_until(video_selected, timeout=8.0), "Bundled black video track was not selected after companion failure"

        # Verify that the loaded video track is the bundled seekable black canvas
        tracks = session.ipc.get_property("track-list") or []
        vids = _get_video_tracks(tracks)

        assert len(vids) > 0, "No video tracks registered in track-list"
        assert _has_bundled_black_video(tracks), f"Bundled black video source was not loaded, tracks: {tracks}"

        # Verify that subtitles are loaded and selected
        def subs_selected():
            sid = session.ipc.get_property("sid")
            sec_sid = session.ipc.get_property("secondary-sid")
            return sid and sid != "no" and sec_sid and sec_sid != "no"

        assert _wait_until(subs_selected, timeout=3.0), "Subtitle tracks were not loaded or selected"
        _wait_for_rendered_subtitles(session.ipc)

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)


def test_audio_only_companion_subtitles_selected_for_navigation_and_replay():
    work = _new_scratch_dir("audio-only-companion-nav")
    media_mp3 = work / "sample.mp3"
    media_srt_pri = work / "sample.en.srt"
    media_srt_sec = work / "sample.ru.srt"

    subtitle_content_pri = """1
00:00:01,000 --> 00:00:02,000
Primary Line 1

2
00:00:05,000 --> 00:00:06,000
Primary Line 2

3
00:00:09,000 --> 00:00:10,000
Primary Line 3
"""
    subtitle_content_sec = """1
00:00:01,000 --> 00:00:02,000
Secondary Line 1

2
00:00:05,000 --> 00:00:06,000
Secondary Line 2

3
00:00:09,000 --> 00:00:10,000
Secondary Line 3
"""
    media_srt_pri.write_text(subtitle_content_pri, encoding="utf-8")
    media_srt_sec.write_text(subtitle_content_sec, encoding="utf-8")
    _create_silent_mp3(media_mp3)

    session = MpvSession(video=str(media_mp3), extra_args=["--pause"])
    _start_or_skip(session)
    try:
        def subtitles_ready():
            sid = session.ipc.get_property("sid")
            sec_sid = session.ipc.get_property("secondary-sid")
            state = query_kardenwort_state(session.ipc)
            return (
                sid and sid != "no" and
                sec_sid and sec_sid != "no" and
                state.get("pri_sub_count") == 3 and
                state.get("sec_sub_count") == 3 and
                state.get("playback_state") == "DUAL_SRT"
            )

        assert _wait_until(subtitles_ready, timeout=6.0), (
            "MP3-only companion subtitles were attached but not selected for Kardenwort logic"
        )

        session.ipc.command(["script-message-to", "kardenwort", "test-set-option", "audio_padding_start", "0"])
        session.ipc.command(["script-message-to", "kardenwort", "test-set-option", "audio_padding_end", "0"])
        session.ipc.command(["seek", 9.4, "absolute+exact"])
        time.sleep(0.2)

        session.ipc.command(["script-message-to", "kardenwort", "test-seek-delta", "-1"])
        time.sleep(0.35)
        pos = session.ipc.get_property("time-pos")
        assert abs(pos - 5.0) < 0.15, f"Expected seek-prev to land on line 2 at 5.0s, got {pos:.3f}s"

        session.ipc.command(["script-message-to", "kardenwort", "test-set-option", "replay_msg_format", "Replay"])
        session.ipc.command(["script-message-to", "kardenwort", "test-set-option", "replay_count", "2"])
        session.ipc.command(["script-message-to", "kardenwort", "autopause-set", "OFF"])
        time.sleep(0.1)
        session.ipc.command(["script-message-to", "kardenwort", "test-replay"])
        time.sleep(0.3)
        osd = session.ipc.get_property("user-data/kardenwort/last_osd")
        assert osd == "Replay", f"Expected replay OSD parity, got: {osd}"

        time.sleep(0.7)
        osd_after = session.ipc.get_property("user-data/kardenwort/last_osd")
        assert not osd_after.startswith("Loop:"), f"Replay OSD was overwritten by loop re-anchor: {osd_after}"

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)


def test_mp3_phrase_active_idx_freezes_after_autopause():
    """Regression test: after autopause fires in PHRASE mode on MP3,
    the ACTIVE_IDX sentinel must stay on the subtitle we stopped on,
    NOT drift to the next subtitle because of coarse 1 fps ticks.
    The rendered subtitle must therefore remain the current one.
    """
    work = _new_scratch_dir("audio-only-phrase-freeze")
    media_mp3 = work / "sample.mp3"
    media_srt = work / "sample.en.srt"

    subtitle_content = """1
00:00:01,000 --> 00:00:02,000
Line One

2
00:00:05,000 --> 00:00:06,000
Line Two

3
00:00:09,000 --> 00:00:10,000
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

        def subs_ready():
            state = query_kardenwort_state(ipc)
            return (
                state.get("pri_sub_count") == 3
                and state.get("playback_state") in ("SINGLE_SRT", "DUAL_SRT")
            )

        assert _wait_until(subs_ready, timeout=6.0), "Subtitles not loaded"

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
        ipc.command(
            ["script-message-to", "kardenwort", "test-set-option",
             "autopause_overshoot", "0.05"]
        )
        time.sleep(0.15)

        ipc.command(["seek", 5.0, "absolute+exact"])
        time.sleep(0.25)
        ipc.command(["set_property", "pause", False])

        paused = _wait_until(lambda: ipc.get_property("pause"), timeout=5.0)
        pos = ipc.get_property("time-pos")
        state = query_kardenwort_state(ipc)

        print(f"DEBUG pos={pos:.3f} paused={paused}")
        print(f"DEBUG state={state}")

        assert paused, f"Autopause did NOT fire (pos={pos:.3f})"

        active_idx = state.get("active_sub_index")
        assert active_idx == 2, (
            f"ACTIVE_IDX drifted to {active_idx} after autopause; expected 2 "
            f"(pos={pos:.3f})"
        )

        render = query_kardenwort_render(ipc, "drum", timeout=1.0)
        assert "Line Two" in render, (
            f"Rendered subtitle does NOT contain 'Line Two': {render}"
        )
        assert "Line Three" not in render, (
            f"Rendered subtitle incorrectly contains 'Line Three': {render}"
        )

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)


def test_mp3_phrase_drift_adjacent_subs():
    """Regression test: after autopause fires in PHRASE mode on MP3,
    the ACTIVE_IDX sentinel must NOT drift to the next subtitle even if it
    is immediately adjacent (zero gap).
    """
    work = _new_scratch_dir("audio-only-phrase-drift-adjacent")
    media_mp3 = work / "sample.mp3"
    media_srt = work / "sample.en.srt"

    subtitle_content = """1
00:00:01,000 --> 00:00:02,000
Line One

2
00:00:02,000 --> 00:00:03,000
Line Two
"""
    media_srt.write_text(subtitle_content, encoding="utf-8")
    _create_silent_mp3(media_mp3, duration=10)

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
            return state.get("pri_sub_count") == 2

        assert _wait_until(subs_ready, timeout=6.0), "Subtitles not loaded"

        ipc.command(["script-message-to", "kardenwort", "autopause-set", "ON"])
        ipc.command(["script-message-to", "kardenwort", "immersion-mode-set", "PHRASE"])
        ipc.command(["script-message-to", "kardenwort", "test-set-option", "audio_padding_start", "0"])
        ipc.command(["script-message-to", "kardenwort", "test-set-option", "audio_padding_end", "0"])
        ipc.command(["script-message-to", "kardenwort", "test-set-option", "autopause_overshoot", "0.1"])
        time.sleep(0.15)

        ipc.command(["seek", 1.0, "absolute+exact"])
        time.sleep(0.25)
        ipc.command(["set_property", "pause", False])

        paused = _wait_until(lambda: ipc.get_property("pause"), timeout=5.0)
        pos = ipc.get_property("time-pos")
        state = query_kardenwort_state(ipc)

        print(f"DEBUG pos={pos:.3f} paused={paused}")
        print(f"DEBUG state={state}")

        assert paused, f"Autopause did NOT fire (pos={pos:.3f})"

        active_idx = state.get("active_sub_index")
        # With adjacent subs and 0.05 nav_tolerance, any pos >= 1.95 would cause a drift
        # to sub 2 without the PAUSE GUARD. Autopause happens at 2.0 (or slightly after).
        assert active_idx == 1, (
            f"ACTIVE_IDX drifted to {active_idx} after autopause; expected 1 "
            f"(pos={pos:.3f})"
        )

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)
