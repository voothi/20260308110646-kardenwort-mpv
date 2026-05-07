import pytest
from tests.ipc.mpv_session import MpvSession


@pytest.fixture
def mpv():
    session = MpvSession(fixture='tests/fixtures/test_minimal.srt')
    session.start()
    yield session
    session.stop()
