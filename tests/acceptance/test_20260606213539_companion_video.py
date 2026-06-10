"""
Feature ZID: 20260606213539
Feature: Companion Video/Picture Track Auto-loading and Selection

Validated against openspec spec: audio-only-media
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


def _create_audio_only(src_video, dst_audio):
    cmd = ["ffmpeg", "-y", "-i", str(src_video), "-vn", "-acodec", "copy", str(dst_audio)]
    subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)


def test_companion_video_loaded_from_main():
    work = _new_scratch_dir("companion-video-main")
    media_main = work / "sample.mp4"
    media_ru = work / "sample.ru.mp4"

    # Main has video, RU is audio only
    shutil.copy2(_FIXTURE_VIDEO, media_main)
    _create_audio_only(_FIXTURE_VIDEO, media_ru)

    session = MpvSession(video=str(media_ru), extra_args=["--pause"])
    _start_or_skip(session)
    try:
        # Wait until a video track is active
        def video_selected():
            vid = session.ipc.get_property("vid")
            return vid and vid != "no"

        assert _wait_until(video_selected, timeout=6.0), "Video track was not selected"

        # Verify that the companion video track is loaded from the main file
        tracks = session.ipc.get_property("track-list") or []
        vids = _get_video_tracks(tracks)
        found_main = False
        for v in vids:
            p = v.get("external-filename") or v.get("external_filename") or ""
            if "sample.mp4" in p.lower() or "sample.mp4" in Path(p).name.lower():
                found_main = True
                break
        assert found_main, "Companion video track from main file was not loaded"

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)


def test_companion_video_loaded_from_other_companion():
    work = _new_scratch_dir("companion-video-other")
    media_main = work / "sample.mp4"
    media_ru = work / "sample.ru.mp4"
    media_de = work / "sample.de.mp4"

    # Main is audio-only, RU is audio-only, DE has video
    _create_audio_only(_FIXTURE_VIDEO, media_main)
    _create_audio_only(_FIXTURE_VIDEO, media_ru)
    shutil.copy2(_FIXTURE_VIDEO, media_de)

    session = MpvSession(video=str(media_ru), extra_args=["--pause"])
    _start_or_skip(session)
    try:
        # Wait until a video track is active
        def video_selected():
            vid = session.ipc.get_property("vid")
            return vid and vid != "no"

        assert _wait_until(video_selected, timeout=6.0), "Video track was not selected"

        # Verify that the companion video track is loaded from the DE companion file
        tracks = session.ipc.get_property("track-list") or []
        vids = _get_video_tracks(tracks)
        found_de = False
        for v in vids:
            p = v.get("external-filename") or v.get("external_filename") or ""
            if "sample.de.mp4" in p.lower() or "sample.de.mp4" in Path(p).name.lower():
                found_de = True
                break
        assert found_de, "Companion video track from DE file was not loaded"

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)


def test_companion_video_disabled():
    work = _new_scratch_dir("companion-video-disabled")
    media_main = work / "sample.mp4"
    media_ru = work / "sample.ru.mp4"

    shutil.copy2(_FIXTURE_VIDEO, media_main)
    _create_audio_only(_FIXTURE_VIDEO, media_ru)

    session = MpvSession(video=str(media_ru), extra_args=[
        "--pause",
        "--script-opts=kardenwort-companion_video_enabled=no"
    ])
    _start_or_skip(session)
    try:
        time.sleep(1.0)
        tracks = session.ipc.get_property("track-list") or []
        vids = _get_video_tracks(tracks)
        assert len(vids) == 0, "No video track should be loaded when companion_video_enabled is disabled"

        vid = session.ipc.get_property("vid")
        assert not vid or vid == "no"

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)
