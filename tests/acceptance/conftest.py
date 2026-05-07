import pytest
from tests.ipc.mpv_session import MpvSession


@pytest.fixture
def mpv():
    session = MpvSession(
        video='tests/fixtures/test_video.mp4',
        subtitle='tests/fixtures/test_minimal.srt',
    )
    session.start()
    yield session
    session.stop()
