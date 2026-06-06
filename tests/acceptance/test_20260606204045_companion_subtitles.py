"""
Feature ZID: 20260606204045
Feature: Companion Subtitle Auto-loading and Selection
"""

import shutil
import time
import uuid
from pathlib import Path

import pytest
from tests.ipc.mpv_session import MpvSession


_FIXTURE_VIDEO = Path(
    "tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.mp4"
)

# A minimal valid SRT subtitle file content
_DUMMY_SRT = (
    "1\n00:00:01,000 --> 00:00:05,000\nHello world\n\n"
)


def _wait_until(condition, timeout=4.0, step=0.1):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if condition():
            return True
        time.sleep(step)
    return False


def _get_subtitle_tracks(track_list):
    subs = []
    for track in track_list or []:
        if track.get("type") == "sub":
            subs.append(track)
    return subs


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


def test_companion_subtitles_loaded_and_selected():
    work = _new_scratch_dir("companion-subtitles")
    media_en = work / "sample.en.mp4"
    sub_en = work / "sample.en.srt"
    sub_de = work / "sample.de.srt"
    sub_ru = work / "sample.ru.srt"

    shutil.copy2(_FIXTURE_VIDEO, media_en)
    sub_en.write_text(_DUMMY_SRT, encoding="utf-8")
    sub_de.write_text(_DUMMY_SRT, encoding="utf-8")
    sub_ru.write_text(_DUMMY_SRT, encoding="utf-8")

    session = MpvSession(video=str(media_en), extra_args=["--pause", "--sub-auto=fuzzy"])
    _start_or_skip(session)
    try:
        # Wait until subtitle tracks are fully loaded and processed
        def all_subs_loaded():
            tracks = session.ipc.get_property("track-list") or []
            subs = _get_subtitle_tracks(tracks)
            titles = set()
            for s in subs:
                if s.get("title"):
                    titles.add(s["title"].upper())
                if s.get("lang"):
                    titles.add(s["lang"].upper())
            print(f"DEBUG TRACKS: {tracks}")
            print(f"DEBUG TITLES: {titles}")
            return "EN" in titles and "DE" in titles and "RU" in titles

        assert _wait_until(all_subs_loaded), "Not all companion subtitle tracks were loaded"

        # Verify that the active primary subtitle (sid) is the track matching the media postfix (en)
        def correct_sid_active():
            sid = session.ipc.get_property("sid")
            if not sid or sid == "no":
                return False
            tracks = session.ipc.get_property("track-list") or []
            for t in tracks:
                if t.get("type") == "sub" and t.get("id") == int(sid):
                    title = t.get("title") or t.get("lang") or ""
                    return title.upper() == "EN" or t.get("lang", "").lower() == "en"
            return False

        assert _wait_until(correct_sid_active), "Subtitle matching the language postfix 'en' was not selected as primary"

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)


def test_companion_subtitles_de_selected():
    work = _new_scratch_dir("companion-subtitles-de")
    media_de = work / "sample.de.mp4"
    sub_en = work / "sample.en.srt"
    sub_de = work / "sample.de.srt"
    sub_ru = work / "sample.ru.srt"

    shutil.copy2(_FIXTURE_VIDEO, media_de)
    sub_en.write_text(_DUMMY_SRT, encoding="utf-8")
    sub_de.write_text(_DUMMY_SRT, encoding="utf-8")
    sub_ru.write_text(_DUMMY_SRT, encoding="utf-8")

    session = MpvSession(video=str(media_de), extra_args=["--pause", "--sub-auto=fuzzy"])
    _start_or_skip(session)
    try:
        def all_subs_loaded():
            tracks = session.ipc.get_property("track-list") or []
            subs = _get_subtitle_tracks(tracks)
            titles = set()
            for s in subs:
                if s.get("title"):
                    titles.add(s["title"].upper())
                if s.get("lang"):
                    titles.add(s["lang"].upper())
            return "EN" in titles and "DE" in titles and "RU" in titles

        assert _wait_until(all_subs_loaded), "Not all companion subtitle tracks were loaded"

        def correct_sid_active():
            sid = session.ipc.get_property("sid")
            if not sid or sid == "no":
                return False
            tracks = session.ipc.get_property("track-list") or []
            for t in tracks:
                if t.get("type") == "sub" and t.get("id") == int(sid):
                    title = t.get("title") or t.get("lang") or ""
                    return title.upper() == "DE" or t.get("lang", "").lower() == "de"
            return False

        assert _wait_until(correct_sid_active), "Subtitle matching the language postfix 'de' was not selected as primary"

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)
