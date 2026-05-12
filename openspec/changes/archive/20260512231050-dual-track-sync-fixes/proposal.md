## Why

During dual-subtitle playback in DM mode, the upper secondary track visually lagged behind the lower primary track during fast Shift+a/d scrubbing and repeated Replay operations. This was caused by the navigation cooldown period and lack of immediate dual-track anchoring during seek operations, leading to a poor user experience when primary/secondary subtitle timings are not perfectly aligned.

## What Changes

- **Configuration**: Reduced `kardenwort-nav_cooldown` from 0.5s to 0.2s for faster index settling after navigation
- **Shift+A/D seek-time**: Added immediate dual-track anchoring to minimize perceived upper-track lag during time-based seeks
- **Replay operations**: Added dual-track anchoring in all replay paths (Autopause ON/OFF, loop, scheduled replay) to prevent drift during repeated Replay presses
- **Diagnostics**: Restored `user-data/kardenwort/last_osd` property for IPC test diagnostics
- **Tests**: Added two new test suites for dual-track synchronization validation

## Capabilities

### New Capabilities
- `dual-track-sync-anchoring`: Immediate anchoring of both primary and secondary subtitle indices during seek operations to prevent visual lag and desynchronization
- `replay-dual-sync`: Dual-track synchronization during repeated Replay operations in both Autopause modes

### Modified Capabilities
- `nav-cooldown`: Reduced cooldown period from 0.5s to 0.2s for faster index settling

## Impact

- **Code**: [`scripts/kardenwort/main.lua`](scripts/kardenwort/main.lua) - Modified `cmd_seek_time()`, `cmd_replay_sub()`, `tick_loop()`, `tick_scheduled_replay()`, `show_osd()`, and initialization
- **Configuration**: [`mpv.conf`](mpv.conf) - Reduced `kardenwort-nav_cooldown` value
- **Tests**: Added [`tests/acceptance/test_20260512223046_shift_ad_seek_anchor.py`](tests/acceptance/test_20260512223046_shift_ad_seek_anchor.py) and [`tests/acceptance/test_20260512223306_replay_repeat_dual_sync.py`](tests/acceptance/test_20260512223306_replay_repeat_dual_sync.py)
- **Documentation**: [`docs/conversation.log`](docs/conversation.log) - Updated with conversation history

The changes ensure that both primary and secondary subtitle tracks remain synchronized during navigation and replay operations, improving the user experience for dual-subtitle language learning workflows.
