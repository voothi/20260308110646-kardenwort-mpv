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


@pytest.fixture
def mpv_fragment1():
    """Real 25fps video fragment, DE primary + RU secondary, paused.

    Duration: 20.045s  Video: 25fps (keyframe every 0.040s)

    Sub timeline (DE = RU timestamps):
      1: 4.295 → 5.295   gap_after=1.260s
      2: 6.555 → 11.088  gap_after=0.087s  ← below default 200ms padding
      3: 11.175 → 12.722 gap_after=0.040s  ← tight overlap zone
      4: 12.762 → 15.117 gap_after=0.599s
      5: 15.716 → 20.049
    """
    session = MpvSession(
        video='tests/fixtures/20260507164826-fragment1.mp4',
        subtitle='tests/fixtures/20260507164826-fragment1.de.srt',
        secondary_subtitle='tests/fixtures/20260507164826-fragment1.ru.srt',
        extra_args=['--pause'],
    )
    session.start()
    yield session
    session.stop()


@pytest.fixture
def mpv_fragment2():
    """Real 25fps video fragment, DE primary + RU secondary, paused.

    Duration: 18.649s  Video: 25fps (keyframe every 0.040s)

    Sub timeline (DE = RU timestamps):
      1: 0.661 → 1.793   gap_after=0.368s
      2: 2.161 → 6.028   gap_after=0.092s  ← below default 200ms padding
      3: 6.120 → 8.871   gap_after=0.040s  ← tight overlap zone
      4: 8.911 → 11.236  gap_after=1.165s
      5: 12.401 → 14.381 gap_after=0.040s  ← tight overlap zone
      6: 14.421 → 18.620
    """
    session = MpvSession(
        video='tests/fixtures/20260507164826-fragment2.mp4',
        subtitle='tests/fixtures/20260507164826-fragment2.de.srt',
        secondary_subtitle='tests/fixtures/20260507164826-fragment2.ru.srt',
        extra_args=['--pause'],
    )
    session.start()
    yield session
    session.stop()
