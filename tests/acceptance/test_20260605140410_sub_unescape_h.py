"""
Feature ZID: 20260605140410
Feature: Unescape \\h formatting in subtitles

Verifies that any sequence of one or more backslashes followed by 'h'
is normalized into a space, and adjacent formatting spaces are handled cleanly,
and that this behavior can be disabled via the `unescape_tags` option.
"""
import time
import pytest
from tests.ipc.mpv_ipc import query_kardenwort_state
from tests.ipc.mpv_session import MpvSession

_FIXTURE_DIR = "tests/fixtures/20260502165659-test-fixture"
_VIDEO = f"{_FIXTURE_DIR}/20260502165659-test-fixture.mp4"

def _query_state_reliable(ipc, max_attempts: int = 6) -> dict:
    last_exc = None
    for _ in range(max_attempts):
        try:
            return query_kardenwort_state(ipc)
        except (RuntimeError, TimeoutError) as exc:
            last_exc = exc
            time.sleep(0.4)
    raise RuntimeError(f"kardenwort state not available after {max_attempts} attempts: {last_exc}")

@pytest.fixture
def unescape_session(tmp_path):
    dest_video = tmp_path / "test.mp4"
    dest_srt = tmp_path / "test.srt"
    import shutil
    shutil.copy2(_VIDEO, dest_video)
    
    with open(dest_srt, "w", encoding="utf-8") as f:
        f.write("1\n00:00:01,000 --> 00:00:05,000\nHello\\hworld\\h\\hthis\\\\h\\\\h\\\\his\\\\\\h\\\\\\h\\htest\n")
        
    session = MpvSession(
        video=str(dest_video),
        subtitle=str(dest_srt),
        extra_args=["--pause"]
    )
    session.start()
    yield session
    session.stop()

@pytest.fixture
def unescape_disabled_session(tmp_path):
    dest_video = tmp_path / "test_disabled.mp4"
    dest_srt = tmp_path / "test_disabled.srt"
    import shutil
    shutil.copy2(_VIDEO, dest_video)
    
    with open(dest_srt, "w", encoding="utf-8") as f:
        f.write("1\n00:00:01,000 --> 00:00:05,000\nHello\\hworld\\h\\hthis\\\\h\\\\h\\\\his\\\\\\h\\\\\\h\\htest\n")
        
    session = MpvSession(
        video=str(dest_video),
        subtitle=str(dest_srt),
        extra_args=["--pause", "--script-opts=kardenwort-unescape_tags=\\N \\n"]
    )
    session.start()
    yield session
    session.stop()

def test_unescape_h_formatting_enabled(unescape_session):
    ipc = unescape_session.ipc
    ipc.command(["seek", 2.0, "absolute+exact"])
    time.sleep(0.4)

    ipc.command(["script-message-to", "kardenwort", "test-get-sub-text", "pri", "1"])
    time.sleep(0.1)

    state = _query_state_reliable(ipc)
    text = state.get("test_data", {}).get("test_sub_text", "")
    print(f"DEBUG ENABLED SUB TEXT: {text}")
    assert "\\h" not in text
    assert "\\\\" not in text
    assert "Hello" in text
    assert "world" in text
    assert "this" in text
    assert "is" in text
    assert "test" in text

def test_unescape_h_formatting_disabled(unescape_disabled_session):
    ipc = unescape_disabled_session.ipc
    ipc.command(["seek", 2.0, "absolute+exact"])
    time.sleep(0.4)

    ipc.command(["script-message-to", "kardenwort", "test-get-sub-text", "pri", "1"])
    time.sleep(0.1)

    state = _query_state_reliable(ipc)
    text = state.get("test_data", {}).get("test_sub_text", "")
    print(f"DEBUG DISABLED SUB TEXT: {text}")
    # When disabled, the \h and backslashes should remain intact in the parsed text
    assert "\\h" in text
    assert "Hello\\hworld" in text
