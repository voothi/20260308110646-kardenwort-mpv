"""
Feature ZID: 20260606214513
Feature: Toggle/Cycle Secondary Subtitles on Shift+C (Option 1)
"""

import shutil
import time
import uuid
from pathlib import Path
from tests.ipc.mpv_session import MpvSession
from tests.ipc.mpv_ipc import query_kardenwort_state


_FIXTURE_VIDEO = Path(
    "tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.mp4"
)

_DUMMY_SRT = "1\n00:00:01,000 --> 00:00:05,000\nHello world\n\n"


def _new_scratch_dir(prefix):
    base = Path("scratch") / "acceptance"
    base.mkdir(parents=True, exist_ok=True)
    work = base / f"{prefix}-{uuid.uuid4().hex[:8]}"
    work.mkdir(parents=True, exist_ok=False)
    return work


def test_subtitle_cycling_toggle_and_cycle():
    """
    Verify that slow taps on cycle-sec-sid toggles between the last active track and OFF,
    and rapid taps cycle through all available tracks sequentially.
    """
    work = _new_scratch_dir("sub-cycling")
    media_de = work / "sample.de.mp4"
    sub_de = work / "sample.de.srt"
    sub_ru = work / "sample.ru.srt"

    shutil.copy2(_FIXTURE_VIDEO, media_de)
    sub_de.write_text(_DUMMY_SRT, encoding="utf-8")
    sub_ru.write_text(_DUMMY_SRT, encoding="utf-8")

    session = MpvSession(
        video=str(media_de.resolve()),
        subtitle=str(sub_de.resolve()),
        secondary_subtitle=str(sub_ru.resolve()),
        extra_args=["--pause"]
    )
    try:
        session.start()
        ipc = session.ipc

        # Wait until both tracks are loaded and active.
        def tracks_ready():
            sid = ipc.get_property("sid")
            sec_sid = ipc.get_property("secondary-sid")
            return sid and sec_sid and sid != "no" and sec_sid != "no" and int(sid) != int(sec_sid)

        deadline = time.time() + 5.0
        while time.time() < deadline:
            if tracks_ready():
                break
            time.sleep(0.1)

        sid = ipc.get_property("sid")
        sec_sid = ipc.get_property("secondary-sid")
        assert sid is not None and int(sid) == 1
        assert sec_sid is not None and int(sec_sid) == 2

        # 1. Slow tap (elapsed > threshold): toggle to OFF
        time.sleep(1.2)  # exceed threshold (1.0s)
        ipc.command(["script-binding", "kardenwort/cycle-sec-sid"])
        time.sleep(0.25)
        sec_sid = ipc.get_property("secondary-sid")
        # Should be OFF (0 or None or 'no')
        assert not sec_sid or sec_sid == "no" or int(sec_sid) == 0

        # 2. Slow tap again: toggle back to RU (2)
        time.sleep(1.2)
        ipc.command(["script-binding", "kardenwort/cycle-sec-sid"])
        time.sleep(0.25)
        sec_sid = ipc.get_property("secondary-sid")
        assert sec_sid is not None and int(sec_sid) == 2

        # 3. Rapid taps (elapsed <= threshold): cycle RU (2) -> OFF (0) -> RU (2)
        # Start with RU (2) active.
        # Tap 1: RU -> OFF
        ipc.command(["script-binding", "kardenwort/cycle-sec-sid"])
        time.sleep(0.15)
        sec_sid = ipc.get_property("secondary-sid")
        assert not sec_sid or sec_sid == "no" or int(sec_sid) == 0

        # Tap 2: OFF -> RU (2)
        ipc.command(["script-binding", "kardenwort/cycle-sec-sid"])
        time.sleep(0.15)
        sec_sid = ipc.get_property("secondary-sid")
        assert sec_sid is not None and int(sec_sid) == 2

    finally:
        session.stop()
        shutil.rmtree(work, ignore_errors=True)
