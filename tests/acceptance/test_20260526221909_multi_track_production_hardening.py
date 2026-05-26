"""
Feature ZID: 20260526221909
Feature: Multi-track file switching production hardening
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


def _wait_until(condition, timeout=4.0, step=0.1):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if condition():
            return True
        time.sleep(step)
    return False


def _external_audio_names(track_list):
    names = set()
    for track in track_list or []:
        if track.get("type") == "audio" and track.get("external"):
            path = track.get("external-filename") or track.get("external_filename") or ""
            if path:
                names.add(Path(path).name.lower())
    return names


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


def test_cycle_audio_adds_companions_without_replacing_active_media():
    work = _new_scratch_dir("companion-audio-cycle")
    main = work / "sample.mp4"
    ru = work / "sample.ru.mp4"
    de = work / "sample.de.mp4"

    shutil.copy2(_FIXTURE_VIDEO, main)
    shutil.copy2(_FIXTURE_VIDEO, ru)
    shutil.copy2(_FIXTURE_VIDEO, de)

    session = MpvSession(video=str(main), extra_args=["--pause"])
    _start_or_skip(session)
    try:
        original_path = session.ipc.get_property("path")

        session.ipc.command(["script-binding", "kardenwort/cycle-audio"])

        def companions_attached():
            tracks = session.ipc.get_property("track-list")
            names = _external_audio_names(tracks)
            return "sample.ru.mp4" in names and "sample.de.mp4" in names

        assert _wait_until(companions_attached), "Companion audio tracks were not attached"
        assert session.ipc.get_property("path") == original_path

        before = _external_audio_names(session.ipc.get_property("track-list"))
        session.ipc.command(["script-binding", "kardenwort/cycle-audio"])
        time.sleep(0.25)
        after = _external_audio_names(session.ipc.get_property("track-list"))
        assert before == after
    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)


def test_cycle_audio_never_attaches_current_file_as_external_track():
    work = _new_scratch_dir("companion-audio-self-attach")
    main = work / "sample.mp4"
    ru = work / "sample.ru.mp4"
    de = work / "sample.de.mp4"

    shutil.copy2(_FIXTURE_VIDEO, main)
    shutil.copy2(_FIXTURE_VIDEO, ru)
    shutil.copy2(_FIXTURE_VIDEO, de)

    session = MpvSession(video=str(ru), extra_args=["--pause"])
    _start_or_skip(session)
    try:
        session.ipc.command(["script-binding", "kardenwort/cycle-audio"])

        def any_external():
            tracks = session.ipc.get_property("track-list")
            return len(_external_audio_names(tracks)) > 0

        assert _wait_until(any_external), "Expected at least one companion external audio track"
        names = _external_audio_names(session.ipc.get_property("track-list"))
        assert "sample.ru.mp4" not in names
    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)


def test_companion_audio_configuration_and_file_loaded_hook_are_declared():
    src = Path("scripts/kardenwort/main.lua").read_text(encoding="utf-8")
    conf = Path("mpv.conf").read_text(encoding="utf-8")

    assert "companion_audio_enabled = true" in src
    assert "companion_audio_attach_on_load = true" in src
    assert 'mp.register_event("file-loaded", function()' in src
    assert "if Options.companion_audio_attach_on_load ~= false then" in src

    assert "script-opts-append=kardenwort-companion_audio_enabled=yes" in conf
    assert "script-opts-append=kardenwort-companion_audio_attach_on_load=yes" in conf


def test_cycle_pair_memory_includes_off_slot():
    src = Path("scripts/kardenwort/main.lua").read_text(encoding="utf-8")

    assert "if current_aid ~= FSM.last_aid then" in src
    assert "if current_aid ~= 0 and current_aid ~= FSM.last_aid then" not in src
    assert "Slow tap: toggle between last two selected slots (including OFF)" in src
