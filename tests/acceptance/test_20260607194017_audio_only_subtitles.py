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

        # Verify that the loaded video track is indeed the av://lavfi generator
        tracks = session.ipc.get_property("track-list") or []
        vids = _get_video_tracks(tracks)

        assert len(vids) > 0, "No video tracks registered in track-list"

        found_virtual = False
        for v in vids:
            # mpv may report external-filename or path
            p = v.get("external-filename") or v.get("external_filename") or v.get("path") or ""
            if "lavfi" in p.lower():
                found_virtual = True
                break
        assert found_virtual, f"Virtual video track source was not lavfi color generator, tracks: {tracks}"

        # Verify that subtitles are loaded and selected
        def subs_selected():
            sid = session.ipc.get_property("sid")
            sec_sid = session.ipc.get_property("secondary-sid")
            return sid and sid != "no" and sec_sid and sec_sid != "no"

        assert _wait_until(subs_selected, timeout=3.0), "Subtitle tracks were not loaded or selected"

        # Check subtitle positioning properties are respected
        assert session.ipc.get_property("sub-pos") == 95, f"Expected sub-pos to be 95, got {session.ipc.get_property('sub-pos')}"
        assert session.ipc.get_property("secondary-sub-pos") == 10, f"Expected secondary-sub-pos to be 10, got {session.ipc.get_property('secondary-sub-pos')}"

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)
