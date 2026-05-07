import pytest
from tests.ipc.mpv_session import MpvSession


@pytest.fixture
def mpv():
    session = MpvSession(
        video='tests/fixtures/20260502165659-test-fixture.mp4',
        subtitle='tests/fixtures/20260502165659-test-fixture.en.srt',
    )
    session.start()
    yield session
    session.stop()
