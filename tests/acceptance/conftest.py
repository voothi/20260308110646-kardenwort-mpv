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


@pytest.fixture
def mpv_dual():
    """Dual-subtitle session using fixtures with 200ms inter-subtitle gaps.

    The 200ms gap combined with the default 200ms audio_padding_start/end creates
    an overlap zone that previously caused the secondary track to desync by one index.
    """
    session = MpvSession(
        video='tests/fixtures/20260502165659-test-fixture.mp4',
        subtitle='tests/fixtures/20260507161504-sync-test.en.srt',
        secondary_subtitle='tests/fixtures/20260507161504-sync-test.ru.srt',
        extra_args=['--pause'],
    )
    session.start()
    yield session
    session.stop()
