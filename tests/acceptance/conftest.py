from pathlib import Path
import pytest
from tests.ipc.mpv_session import MpvSession

_PRIMARY_EXPORT_FIXTURE = Path(
    "tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.tsv"
)


@pytest.fixture(autouse=True)
def restore_primary_export_fixture(request):
    """Keep the primary TSV fixture git-clean across acceptance tests."""
    mpv_fixtures = {
        "mpv",
        "mpv_dual",
        "mpv_fragment1",
        "mpv_movie_startup",
        "mpv_ass",
        "mpv_fragment2",
        "mpv_merge_test",
    }
    needs_restore = any(name in request.fixturenames for name in mpv_fixtures)
    if not needs_restore or not _PRIMARY_EXPORT_FIXTURE.exists():
        yield
        return

    original = _PRIMARY_EXPORT_FIXTURE.read_bytes()
    try:
        yield
    finally:
        _PRIMARY_EXPORT_FIXTURE.write_bytes(original)


@pytest.fixture
def mpv():
    session = MpvSession(
        video='tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.mp4',
        subtitle='tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.en.srt',
        extra_args=['--pause'],
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
        video='tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.mp4',
        subtitle='tests/fixtures/20260507161504-sync-test/20260507161504-sync-test.en.srt',
        secondary_subtitle='tests/fixtures/20260507161504-sync-test/20260507161504-sync-test.ru.srt',
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
        video='tests/fixtures/20260507200612-paketzustellerin-in-der-vorweihnachtszeit/20260507164826-fragment1.mp4',
        subtitle='tests/fixtures/20260507200612-paketzustellerin-in-der-vorweihnachtszeit/20260507164826-fragment1.de.srt',
        secondary_subtitle='tests/fixtures/20260507200612-paketzustellerin-in-der-vorweihnachtszeit/20260507164826-fragment1.ru.srt',
        extra_args=['--pause'],
    )
    session.start()
    yield session
    session.stop()


@pytest.fixture
def mpv_movie_startup():
    """Single-subtitle session with MOVIE as the startup immersion mode.

    Used to verify immersion_mode_default=MOVIE option wiring.
    """
    session = MpvSession(
        video='tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.mp4',
        subtitle='tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.en.srt',
        extra_args=['--pause', '--script-opts=kardenwort-immersion_mode_default=MOVIE'],
    )
    session.start()
    yield session
    session.stop()


@pytest.fixture
def mpv_ass():
    """Single ASS subtitle session. Triggers ASS gatekeeping (drum mode forced OFF).

    Sub timeline:
      1: 1.000 → 3.000  "Hello world"
      2: 4.000 → 6.000  "This is a test"
      3: 7.000 → 9.000  "Final entry"
    """
    session = MpvSession(
        video='tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.mp4',
        subtitle='tests/fixtures/20260508173706-test-ass/20260508173706-test.ass',
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
        video='tests/fixtures/20260507200612-paketzustellerin-in-der-vorweihnachtszeit/20260507164826-fragment2.mp4',
        subtitle='tests/fixtures/20260507200612-paketzustellerin-in-der-vorweihnachtszeit/20260507164826-fragment2.de.srt',
        secondary_subtitle='tests/fixtures/20260507200612-paketzustellerin-in-der-vorweihnachtszeit/20260507164826-fragment2.ru.srt',
        extra_args=['--pause'],
    )
    session.start()
    yield session
    session.stop()
@pytest.fixture
def mpv_merge_test():
    """Fixture to verify subtitle merging logic (200ms guard).
    
    Sub timeline:
      1: Hello (0-1s)
      2: Music (1.1-2s)
      3: World (2.1-3s)
      4: Music (3.1-4s) -> Should NOT merge with 2
      5: Bridge (4.1-5s)
      6: Bridge (5.05-6s) -> SHOULD merge with 5
    Expected count: 5 subs.
    """
    session = MpvSession(
        video='tests/fixtures/20260502165659-test-fixture/20260502165659-test-fixture.mp4',
        subtitle='tests/fixtures/20260508192831-merge-test/20260508192831-merge-test.en.srt',
        extra_args=['--pause', '--config-dir=.'],
    )
    session.start()
    yield session
    session.stop()




