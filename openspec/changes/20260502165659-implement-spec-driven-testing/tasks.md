## 1. Extract Pure Utilities into a Testable Module

- [ ] 1.1 Create `scripts/lls_utils.lua` and move pure functions into it: `calculate_ass_alpha`, `utf8_to_table`, `format_highlighted_word`, and the Cyrillic case-mapping helpers.
- [ ] 1.2 In `lls_core.lua`, replace the inlined definitions with `local U = require("lls_utils")` and update all call sites.
- [ ] 1.3 Verify the script loads and all existing functionality works after the extraction.

> **Why**: These functions have no `mp` dependency. Moving them enables unit testing without booting mpv. This is the enabling step for the entire test effort.

---

## 2. Lua Unit Test Suite (busted, no mpv)

- [ ] 2.1 Install busted (LuaRocks `busted` or pre-built Windows binary) and confirm `busted --version` runs.
- [ ] 2.2 Create `tests/unit/test_ass_formatting.lua` — tests for `calculate_ass_alpha` (boundary values: `0`, `1`, `0.5`, `"FF"`, invalid input) and `format_highlighted_word` (phrase mode, surgical mode, color equality short-circuit).
- [ ] 2.3 Create `tests/unit/test_utf8.lua` — tests for `utf8_to_table` with ASCII, multi-byte CJK, Cyrillic, and empty string inputs.
- [ ] 2.4 Create `tests/unit/test_layout.lua` — extract `dw_build_layout` into `lls_utils.lua` and test it against mock subtitle data (known line counts, cursor positions).
- [ ] 2.5 Create `tests/unit/test_hit_zones.lua` — test `dw_hit_test`, `drum_osd_hit_test` logic given fabricated hit-zone tables (no OSD required).
- [ ] 2.6 Add `tests/run_unit.ps1` — a PowerShell wrapper that invokes `busted tests/unit/` and prints pass/fail summary.

---

## 3. State Probe in lls_core.lua (Minimal, Semantic)

- [ ] 3.1 Add a single `mp.register_script_message("lls-state-query", ...)` handler to `lls_core.lua` that returns a **semantic** JSON snapshot: autopause mode, drum/dw mode, active sub index, cursor position, selection count. **Do not dump raw FSM fields.**
- [ ] 3.2 Add a second `mp.register_script_message("lls-render-query", ...)` handler that returns the current `.data` string of a named overlay (`"drum"`, `"dw"`, `"tooltip"`, `"search"`).
- [ ] 3.3 Confirm both handlers are guarded by a feature flag (`Options.enable_test_probe = false` by default) so they are a no-op in normal use.

> **Note**: Do not extend the existing `Diagnostic` table — it is the logging system (line 44). These handlers should be standalone functions or live in a new `LLSProbe` table.

---

## 4. IPC Driver (PowerShell)

- [ ] 4.1 Create `tests/ipc/MpvIpc.psm1` — a PowerShell module wrapping `System.IO.Pipes.NamedPipeClientStream` with functions: `Connect-MpvIpc`, `Send-MpvCommand`, `Get-MpvProperty`, `Disconnect-MpvIpc`.
- [ ] 4.2 Implement request/response correlation using `request_id` — mpv's IPC stream interleaves event notifications with responses, so naive line-by-line reading will misparse. Use a receive loop that matches `request_id` fields.
- [ ] 4.3 Implement `Invoke-LlsStateQuery` — sends `script-message-to lls_core lls-state-query` and returns the parsed JSON response.
- [ ] 4.4 Implement `Invoke-LlsRenderQuery` — sends `lls-render-query` and returns the overlay `.data` string.
- [ ] 4.5 Create `tests/ipc/Invoke-MpvTest.ps1` — boots mpv with `--input-ipc-server=\\.\pipe\mpv-test --script=scripts\lls_core.lua --script-opts=lls_core-enable_test_probe=yes` against a fixture file, waits for IPC to become available, runs a test block, and quits mpv cleanly.

---

## 5. Test Fixtures

- [ ] 5.1 Create `tests/fixtures/` directory.
- [ ] 5.2 Add `tests/fixtures/test_dual.srt` (primary) and `tests/fixtures/test_dual_sec.srt` (secondary) — minimal subtitle files with known content (3–5 entries, known timestamps) sufficient for autopause, drum mode, and word-navigation tests.
- [ ] 5.3 Add `tests/fixtures/test_render.ass` — an ASS file with known styled dialogue lines for rendering verification.
- [ ] 5.4 Document the fixture contract in `tests/README.md`: what each fixture file contains and which test scenarios depend on it.

---

## 6. Acceptance Test Suite (Narrow Scope)

Write tests by hand — one `.ps1` file per capability, citing the relevant `spec.md` path and scenario in a comment. No auto-parsing of spec files.

- [ ] 6.1 `tests/acceptance/test_state_probe.ps1` — verifies `lls-state-query` returns expected default state on clean load.
- [ ] 6.2 `tests/acceptance/test_drum_mode.ps1` — sends `toggle-drum-mode` keypress via IPC, queries state, asserts `"drum_mode": "ON"`.
- [ ] 6.3 `tests/acceptance/test_rendering.ps1` — loads `test_render.ass`, queries `lls-render-query dw`, verifies the overlay `.data` string contains expected ASS color tags for a known word index.
- [ ] 6.4 `tests/acceptance/test_autopause.ps1` — loads `test_dual.srt`, enables autopause via IPC, seeks to known subtitle boundary, asserts mpv is paused.
- [ ] 6.5 `tests/acceptance/test_hit_zones.ps1` — confirms `DRUM_HIT_ZONES` is populated after drum mode is active (via `lls-state-query`).

---

## 7. Pilot Verification

- [ ] 7.1 Run `tests/run_unit.ps1` — all unit tests pass.
- [ ] 7.2 Run `Invoke-MpvTest.ps1` against `test_rendering.ps1` — confirm ASS tag for a hex conversion regression is caught by the test before the fix and passes after.
- [ ] 7.3 Manually break `calculate_ass_alpha` (off-by-one in the hex conversion) and confirm the unit test in 2.2 fails with a descriptive message.
- [ ] 7.4 Document run instructions in `tests/README.md`.
