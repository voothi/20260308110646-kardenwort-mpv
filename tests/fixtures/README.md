# Test Fixtures

## 20260502165659-test-fixture.mp4

A 2×2 black synthetic video (12 s, silent). Used as the main media file for acceptance tests — gives mpv a valid A/V stream so the IPC server stays alive.

## 20260502165659-test-fixture.en.srt

A minimal English SRT file with three subtitle entries, loaded as an external subtitle alongside the video above.

| Entry | Timestamp | Text | Word count |
|-------|-----------|------|------------|
| 1 | 00:00:01,000 → 00:00:03,000 | Hello world | 2 |
| 2 | 00:00:04,000 → 00:00:06,000 | This is a test | 4 |
| 3 | 00:00:07,000 → 00:00:09,000 | Final entry | 2 |

**Acceptance tests that depend on these files:**

- `tests/acceptance/test_state_probe.py` — boots mpv; verifies initial FSM state (`SINGLE_SRT`).
- `tests/acceptance/test_drum_mode.py` — boots mpv; toggles drum mode and checks FSM.
- `tests/acceptance/test_render.py` — boots mpv; activates drum mode and inspects ASS overlay.

## 20260502165659-test-fixture.tsv

Auto-generated empty highlights file associated with the video above. Committed as an empty header so kardenwort does not attempt to create it at test time.


