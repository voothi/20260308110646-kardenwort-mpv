"""
Feature ZID: 20260509094816
Feature: BOM-Aware Parsing
Regression tests for BOM-Aware Parsing (ZID 20260509094816).

Verifies that UTF-8 files with a Byte Order Mark (BOM) are correctly loaded
and that subtitle index 1 is correctly identified despite the `\xEF\xBB\xBF` sequence.
"""
import os
import shutil
import time

import pytest
from tests.ipc.mpv_ipc import query_lls_state
from tests.ipc.mpv_session import MpvSession

_FIXTURE_DIR = "tests/fixtures/20260502165659-test-fixture"
_VIDEO = f"{_FIXTURE_DIR}/20260502165659-test-fixture.mp4"

def _query_state_reliable(ipc, max_attempts: int = 6) -> dict:
    last_exc = None
    for _ in range(max_attempts):
        try:
            return query_lls_state(ipc)
        except (RuntimeError, TimeoutError) as exc:
            last_exc = exc
            time.sleep(0.4)
    raise RuntimeError(f"lls state not available after {max_attempts} attempts: {last_exc}")

@pytest.fixture
def bom_session(tmp_path):
    dest_video = tmp_path / "test.mp4"
    dest_srt = tmp_path / "test.srt"
    shutil.copy2(_VIDEO, dest_video)
    
    # Write SRT with UTF-8 BOM
    with open(dest_srt, "w", encoding="utf-8-sig") as f:
        f.write("1\n00:00:01,000 --> 00:00:05,000\nHello BOM\n")
        
    session = MpvSession(
        video=str(dest_video),
        subtitle=str(dest_srt),
        extra_args=["--pause"]
    )
    session.start()
    yield session
    session.stop()

def test_bom_aware_parsing_index_1(bom_session):
    ipc = bom_session.ipc
    ipc.command(["seek", 2.0, "absolute+exact"])
    time.sleep(0.4)

    state = _query_state_reliable(ipc)
    assert state["active_sub_index"] == 1, (
        f"Expected sub 1 active at 2.0s, got index {state.get('active_sub_index')}"
    )

    # Verify the primary track was loaded (BOM didn't break the parser)
    tracks = state.get("tracks", {})
    pri = tracks.get("pri", {})
    assert pri.get("count", 0) >= 1, (
        f"Primary track count should be >= 1 (BOM subtitle loaded). "
        f"tracks: {tracks}"
    )

