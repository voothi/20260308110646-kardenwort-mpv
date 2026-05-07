## Why

The project currently relies on manual user verification to detect regressions, which is slow and prone to oversight. AI-agent audits cost too many tokens to run per change. We need a deterministic, local mechanism to (a) verify pure-Lua logic without booting mpv at all, and (b) drive a real mpv instance and verify state for the small set of behaviors that genuinely require it.

## What Changes

- **Lua unit tests (Tier 1)**: A vendored single-file [luaunit](https://github.com/bluebird75/luaunit) runner, executed by stand-alone Lua/LuaJIT. No mpv, no LuaRocks. Targets pure utility functions extracted into `scripts/lls_utils.lua`.
- **In-script state probe**: A small block (~30 lines) appended to `lls_core.lua` that registers two `script-message` handlers. They write semantic state snapshots into `user-data/lls/state` and `user-data/lls/render` properties. Dormant until queried.
- **PowerShell IPC driver (Tier 2)**: A PowerShell module wrapping mpv's named-pipe JSON IPC, with request/response correlation, property reads, and headless-mpv lifecycle helpers.
- **Test fixtures**: A small set of subtitle files with known content checked into `tests/fixtures/`.
- **Acceptance scripts**: Hand-written `.ps1` files that boot mpv against a fixture, drive it via IPC, query the probe, and assert behavior.

## Capabilities

### New Capabilities
- `automated-acceptance-testing`: Infrastructure for running BDD-style scenarios against a running mpv instance via JSON IPC.

### Modified Capabilities
- None. The probe block is additive and namespaced under `user-data/lls/*`.

## Impact

- `scripts/lls_core.lua`: ~30-line probe block appended at end. Existing logic untouched.
- `scripts/lls_utils.lua` (new): Holds extracted pure functions (`calculate_ass_alpha`, `utf8_to_table`, etc.) so the unit tier can reach them.
- `tests/` (new): luaunit runner, fixtures, IPC PowerShell module, unit + acceptance test files.
- No CI/CD work in this change. Local execution only.
