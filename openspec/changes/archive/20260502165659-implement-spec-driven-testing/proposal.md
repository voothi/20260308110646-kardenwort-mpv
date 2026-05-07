## Why

The project currently relies on manual user verification to detect regressions, which is slow and prone to oversight. AI-agent audits cost too many tokens to run per change. We need a deterministic, local mechanism to (a) verify pure-Lua logic without booting mpv at all, and (b) drive a real mpv instance and verify state for the small set of behaviors that genuinely require it.

## What Changes

- **Lua unit tests (Tier 1)**: A vendored single-file [luaunit](https://github.com/bluebird75/luaunit) runner, executed by stand-alone Lua/LuaJIT. No mpv, no LuaRocks. Targets pure utility functions extracted into `scripts/lls_utils.lua`.
- **In-script state probe**: A small block (~30 lines) appended to `lls_core.lua` that registers two `script-message` handlers. They write semantic state snapshots into `user-data/lls/state` and `user-data/lls/render` properties. Dormant until queried.
- **Python IPC driver (Tier 2)**: `tests/ipc/mpv_ipc.py` — a cross-platform IPC client using Python stdlib only. On Windows, connects to mpv's Win32 named pipe via `open(r'\\.\pipe\...', 'r+b', buffering=0)`. On Linux/macOS, connects via `socket.AF_UNIX`. The JSON-lines protocol is identical either way.
- **Test fixtures**: A small set of subtitle files with known content checked into `tests/fixtures/`.
- **Acceptance tests**: Hand-written pytest files (`tests/acceptance/test_*.py`) that boot a headless mpv, drive it via IPC, query the probe, and assert behavior.

## Capabilities

### New Capabilities
- `automated-acceptance-testing`: Infrastructure for running BDD-style scenarios against a running mpv instance via JSON IPC.

### Modified Capabilities
- None. The probe block is additive and namespaced under `user-data/lls/*`.

## Impact

- `scripts/lls_core.lua`: ~30-line probe block appended at end. Existing logic untouched.
- `scripts/lls_utils.lua` (new): Holds extracted pure functions (`calculate_ass_alpha`, `utf8_to_table`, etc.) so the unit tier can reach them.
- `tests/` (new): luaunit runner, fixtures, Python IPC module (`mpv_ipc.py`, `mpv_session.py`), unit and acceptance test files.
- No CI/CD work in this change. Local execution only.
