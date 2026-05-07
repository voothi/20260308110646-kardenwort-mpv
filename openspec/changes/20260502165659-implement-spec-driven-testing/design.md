## Context

Kardenwort-mpv ships as `scripts/lls_core.lua` (7,189 lines) plus `scripts/resume_last_file.lua`. The core script contains a 40-variable FSM, four OSD overlays, hit-test logic for mouse/keyboard, and a 50 ms tick loop. There are 165 spec files in `openspec/specs/` documenting behaviors, but no tests exist.

This document is written for a mid-level Lua/PowerShell developer implementing the test stack. **Read the "Critical mpv quirks" section before writing any IPC code** — it covers two non-obvious behaviors that will waste days if you don't know them up front.

---

## Goals / Non-Goals

**Goals:**
- A two-tier test stack: pure-Lua **unit** tests (no mpv) and full-stack **acceptance** tests (real mpv + IPC).
- Zero new test-time cost in production code paths. The probe is dormant until queried.
- Deterministic, reproducible runs on Windows with no LuaRocks dependency.

**Non-Goals:**
- CI/CD integration (deferred).
- Pixel-based rendering verification (we inspect ASS strings instead).
- Auto-parsing `spec.md` files into executable tests — see Decision 4.

---

## Critical mpv quirks (read this first)

### Quirk 1: `script-message` over IPC is fire-and-forget

When you send the IPC command:
```json
{ "command": ["script-message-to", "lls_core", "lls-state-query"], "request_id": 7 }
```
mpv replies with **only** the dispatch acknowledgement:
```json
{ "request_id": 7, "error": "success" }
```
The Lua callback's return value **never** comes back over the pipe. There is no built-in request/response for script messages.

**The pattern we use** is a side channel via mpv's `user-data/*` property namespace (mpv reserves this for arbitrary script-defined data):

1. PowerShell sends `script-message-to lls_core lls-state-query`.
2. The Lua handler computes the snapshot and calls `mp.set_property("user-data/lls/state", json_string)`.
3. PowerShell reads the result via `get_property user-data/lls/state`.

To eliminate the polling race, the driver can subscribe with `observe_property user-data/lls/state` before sending the request and wait for the change event.

### Quirk 2: `--input-ipc-server` alone does not make mpv headless

A bare `mpv --input-ipc-server=\\.\pipe\mpv-test test.srt` still opens a video window. For unattended test runs the full incantation is:
```
mpv --no-config --vo=null --no-terminal --idle=once
    --input-ipc-server=\\.\pipe\mpv-test
    --script=scripts\lls_core.lua
    tests\fixtures\test_minimal.srt
```
- `--no-config` ensures user `mpv.conf` does not bleed into the test environment.
- `--vo=null` runs without a video output (OSD `.data` strings are still constructed by Lua, which is what we test).
- `--no-terminal` prevents the console from grabbing stdin.
- `--idle=once` keeps mpv alive until a file is loaded, then quits when playback ends. For tests that need an indefinite session, use `--idle=yes` and quit explicitly via IPC.

### Quirk 3: Tick-loop timing affects state queries

`master_tick` runs every 50 ms (line 5471). State changes triggered by an IPC keypress are processed on the **next** tick, not synchronously. Always insert at least one tick of slack between sending input and querying state — the simplest pattern is to wait on a property change rather than poll.

---

## Decisions

### Decision 1: Two tiers — unit and acceptance — not three

Earlier drafts proposed a "Tier 2 companion script" running inside mpv. With the user-data side channel from Quirk 1, that middle tier collapses into the acceptance tier (which already runs Lua inside mpv). Two tiers is enough:

| Tier | Runs in | Targets | Speed |
|------|---------|---------|-------|
| Unit | stand-alone Lua, no mpv | pure functions in `lls_utils.lua` | ~10 ms / file |
| Acceptance | full mpv + PowerShell IPC | end-to-end behaviors against real fixtures | ~2-5 s / test |

Most coverage comes from Tier 1. Tier 2 is reserved for behaviors that genuinely need mpv (subtitle loading, tick loop, key bindings, OSD rendering).

### Decision 2: Vendor luaunit, do not depend on busted/LuaRocks

LuaRocks setup on Windows is fragile. **luaunit** is a single ~4 KB Lua file, MIT-licensed, no dependencies. Drop it into `tests/lua/luaunit.lua` and require it from test files. Run with `lua tests/run_unit.lua`.

If `lua.exe` is not available, the LuaJIT bundled inside the mpv installation can run unit tests too — invoke it with `mpv --script=tests/lua/runner.lua --idle=once` (the script calls `mp.commandv("quit", 0)` after running tests). Document both paths in `tests/README.md`.

### Decision 3: Minimal extraction — only what we want to test

Earlier drafts said "extract pure functions." That is open-ended and risky. Be specific: in this change we extract exactly three functions to `scripts/lls_utils.lua`:

- `calculate_ass_alpha` (line 1294) — pure math.
- `utf8_to_table` (line 1315) — pure string parsing.
- `is_valid_mpv_key` (line 83) — pure regex.

These three have **no** dependency on `Options`, `FSM`, or `mp`. They can be `require`d from a unit test with no mocking. Other candidates (`format_highlighted_word`, `dw_build_layout`) read `Options` and need a stub — defer them to a future change.

### Decision 4: Do NOT auto-parse spec.md into tests

The 165 spec files contain English prose under "Scenario:" headings, not machine-parseable step definitions. Any parser will silently decouple from spec edits. Tests are written by hand; each test file cites its spec scenario in a comment header:
```lua
-- Spec: openspec/specs/shared-rendering-utils/spec.md
-- Scenario: Verifying highlight color
```

### Decision 5: Probe lives in `lls_core.lua`, dormant by default

The probe is a ~30-line block appended at the end of `lls_core.lua`. It registers two script-message handlers. They allocate nothing and run no code unless queried. **No feature flag** — flags add complexity for no benefit since the probe costs nothing when idle.

The block sits in its own clearly-labelled region (`-- ===== STATE PROBE (test instrumentation) =====`) so future readers understand its purpose at a glance.

### Decision 6: Probe exposes semantic state, not raw FSM

The state snapshot is a curated, stable JSON shape. When `FSM` internals are renamed, the snapshot field stays the same — its computation changes. Example:
```json
{
  "autopause": "ON",
  "drum_mode": "OFF",
  "drum_window": "DOCKED",
  "active_sub_index": 3,
  "playback_state": "SINGLE_ASS",
  "dw_cursor": { "line": 2, "word": 1 },
  "dw_selection_count": 0,
  "immersion_mode": "MOVIE",
  "copy_mode": "A",
  "loop_mode": "OFF",
  "book_mode": false
}
```
For ASS rendering verification, a separate `lls-render-query` message returns the raw `.data` field of a named overlay (`drum`, `dw`, `tooltip`, `search`, `seek`). Tests parse the ASS string for tag presence (`\1c&H00CCFF&`) — they do not compute pixels.

### Decision 7: Test files live in `tests/`, never in `scripts/`

mpv auto-loads everything in `scripts/`. Anything we put there runs during normal playback. Test-only Lua lives in `tests/lua/` and is injected via `--script=tests/lua/...` only when running tests.

### Decision 8: PowerShell driver, not Python

The repo already uses PowerShell for Windows-specific concerns (clipboard, GoldenDict integration). PowerShell has native named-pipe support via `System.IO.Pipes.NamedPipeClientStream` — no external dependencies. Python with `win32file` is not faster to write or more reliable; it just adds an extra runtime to install.

### Decision 9: Naming — do not collide with existing modules

The original draft put state methods on `Diagnostic`. That table is the **logging** subsystem (line 44). Collision is confusing. Probe internals live in a new local table `LlsProbe` defined inside the probe block.

---

## Architecture overview

```
Test driver (PowerShell)
    │
    │  named pipe: \\.\pipe\mpv-test
    │  JSON-lines IPC
    ▼
mpv process (--vo=null --no-terminal)
    │
    └── scripts/lls_core.lua  ← probe block at end
            │
            │  script-message: lls-state-query / lls-render-query
            ▼
        LlsProbe._snapshot()  →  mp.set_property("user-data/lls/state", json)
                                                                        │
                                                                        ▼
                                            PowerShell reads via get_property

Tier 1 (no mpv at all):
    lua tests/run_unit.lua
        ↓ require
    tests/lua/luaunit.lua + scripts/lls_utils.lua
```

---

## Risks / Trade-offs

- **Polling vs observe_property**: A naive driver polls `user-data/lls/state` after sending a query and risks reading the stale value. Use `observe_property` and wait on the change event. The IPC module helper hides this from individual tests.
- **Fixture brittleness**: Acceptance tests assume specific subtitle timestamps. Document the fixture contract in `tests/fixtures/README.md` so a developer changing a fixture knows which tests they break.
- **mpv lifecycle leaks**: If a test crashes mid-run, the mpv process must still be killed. The PowerShell helper uses `try/finally` with `Stop-Process` on the spawned PID.
- **Pipe collisions**: Hard-coding `\\.\pipe\mpv-test` means two parallel runs collide. For now we accept this (single-developer project). If parallelism becomes desirable, parameterize the pipe name with a GUID.
- **Future of `lls_core.lua` locals**: Most useful logic is in `local function` bindings — unreachable by `require`. Each future test that needs a new pure function will require an extraction step. That is fine: it forces explicit decisions about what is testable.
