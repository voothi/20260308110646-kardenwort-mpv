# Tasks: Fix Startup Navigation Latency

## 1. Core Refactoring

- [x] 1.1 Move subtitle loading logic in `update_media_state` outside of the `FSM.DRUM == "ON"` block.
- [x] 1.2 Update the loading call in `update_media_state` to use `Tracks.pri.is_ass` / `Tracks.sec.is_ass` instead of hardcoded `false`.
- [x] 1.3 Remove redundant "Boot subs for memory" logic from `cmd_toggle_drum_window`.

## 2. Verification

- [x] 2.1 Start a video and immediately test `a`/`d` keys in Normal Mode.
- [x] 2.2 Verify that `w` and `c` modes still function correctly and load their data.
- [x] 2.3 Verify behavior with an ASS track (Normal Mode seeking should work).
- [x] 2.4 Update `release-notes.md` for version v1.28.3.
