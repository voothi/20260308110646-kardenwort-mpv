# Test Fixtures

## test_minimal.srt

A minimal SRT file with three subtitle entries. Used as the standard fixture for acceptance tests.

| Entry | Timestamp | Text | Word count |
|-------|-----------|------|------------|
| 1 | 00:00:01,000 → 00:00:03,000 | Hello world | 2 |
| 2 | 00:00:04,000 → 00:00:06,000 | This is a test | 4 |
| 3 | 00:00:07,000 → 00:00:09,000 | Final entry | 2 |

**Acceptance tests that depend on this file:**

- `tests/acceptance/test_state_probe.py` — boots mpv with this fixture; verifies initial FSM state.
- `tests/acceptance/test_drum_mode.py` — boots mpv with this fixture; toggles drum mode and checks FSM.
- `tests/acceptance/test_render.py` — boots mpv with this fixture; activates drum mode and inspects ASS overlay.
