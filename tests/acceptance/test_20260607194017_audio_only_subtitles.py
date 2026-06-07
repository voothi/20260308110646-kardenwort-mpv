"""
Feature ZID: 20260607194017
Feature: Support Audio-only (MP3) Subtitles and Interface Elements via Virtual Video Track
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


def _has_virtual_black_video(track_list):
    for video in _get_video_tracks(track_list):
        path = (
            video.get("external-filename") or
            video.get("external_filename") or
            video.get("path") or
            ""
        ).lower()
        if "lavfi" in path or "black.mp4" in path:
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


def test_audio_only_fallback_virtual_video():
    work = _new_scratch_dir("audio-only-fallback")
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

        assert _wait_until(video_selected, timeout=6.0), "Virtual video track was not selected automatically"

        # Verify that the loaded video track is the bundled black canvas or lavfi fallback
        tracks = session.ipc.get_property("track-list") or []
        vids = _get_video_tracks(tracks)

        assert len(vids) > 0, "No video tracks registered in track-list"
        assert _has_virtual_black_video(tracks), f"Virtual black video source was not loaded, tracks: {tracks}"

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


def test_audio_only_fallback_when_companion_fails():
    work = _new_scratch_dir("audio-only-fallback-fail")
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
        # Wait until a video track is active (should fall back to lavfi after corrupt candidate fails)
        def video_selected():
            vid = session.ipc.get_property("vid")
            return vid and vid != "no"

        # Give it a bit more time because it has to fail-load first
        assert _wait_until(video_selected, timeout=8.0), "Virtual video track fallback was not selected after companion failure"

        # Verify that the loaded video track is the bundled black canvas or lavfi fallback
        tracks = session.ipc.get_property("track-list") or []
        vids = _get_video_tracks(tracks)

        assert len(vids) > 0, "No video tracks registered in track-list"
        assert _has_virtual_black_video(tracks), f"Virtual black video source was not loaded, tracks: {tracks}"

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
