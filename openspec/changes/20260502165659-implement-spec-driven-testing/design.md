## Context

The Kardenwort-mpv project is a complex Lua-based mpv configuration with many interactive layers (Drum, SRT, Tooltips, Search HUD). Currently, manual regression testing is the only way to verify changes, which is inefficient and unreliable. We have formal specifications in `spec.md` files but no automated way to enforce them.

`lls_core.lua` is a 7,189-line monolith with 40+ FSM state variables, four OSD overlays, 15+ drawing functions, hit-test logic, and a 20 Hz tick loop. Tests that require booting a full mpv instance are inherently slow, flaky, and hard to debug. A tiered approach is required.

---

## Goals / Non-Goals

**Goals:**
- Implement a **three-tier test stack** (unit → script-level → acceptance).
- Achieve coverage of pure Lua logic without booting mpv.
- Enable runtime state introspection for acceptance-level tests.
- Keep production code (`lls_core.lua`) free of test-only conditional paths.

**Non-Goals:**
- Building a full CI/CD pipeline (local execution only).
- Pixel-perfect visual regression.
- Auto-parsing spec.md files into executable test steps (see Decision 4 below).

---

## Decisions

### Decision 1: Three Testing Tiers, Not One

The original proposal jumps immediately to the hardest, most brittle layer — full-stack acceptance tests over IPC. This inverts the testing pyramid. A 7,189-line Lua script has a substantial testable surface at the unit level that requires no mpv at all.

**Tier 1 — Lua unit tests (busted, no mpv)**
Pure functions in `lls_core.lua` — `calculate_ass_alpha` (line 1294), `format_highlighted_word` (line 3270), `utf8_to_table` (line 1315), `dw_build_layout` (line 3656), all hit-test functions, ASS tag formatting — are fully testable with a mocked `mp` table. These are the most stable, fastest-to-run, and highest-ROI tests.

Tool: [busted](https://lunarmodules.github.io/busted/) — the Lua BDD test framework. Installed via LuaRocks or as a standalone Windows binary. Runs as `busted tests/unit/`.

**Tier 2 — Companion Lua test script (lls_test.lua, runs inside mpv)**
A separate `scripts/lls_test.lua` that loads alongside `lls_core.lua` in a dedicated mpv test instance. Uses `mp.get_property_native()` and `mp.register_script_message()` to read state after controlled inputs, then writes a structured result to a log file. **lls_core.lua is not modified at all.** The companion script exits mpv when done via `mp.commandv("quit", "0")`.

**Tier 3 — IPC acceptance tests (narrow scope, PowerShell driver)**
Reserved for a small set (5–10) of scenarios that genuinely require the full stack: verifying autopause triggers at subtitle boundaries, verifying modal key binding changes. No more than this.

---

### Decision 2: Companion Script Isolates Test Code from Production

The original proposal pollutes `lls_core.lua` with `mp.register_script_message("test-probe", ...)` and `test-click` message handlers. This is wrong — it permanently adds test-only branches to production code and makes the monolith larger.

**Correct approach**: `scripts/lls_test.lua` is the test adapter. It reads shared state that is already accessible through mpv's property system (`mp.get_property_native()` on any shared `local` that mpv exposes, plus `mp.get_script_name()` cross-script messaging). For state that is not naturally exposed, the companion script uses `mp.add_timeout(0.1, ...)` to observe post-tick state.

If specific deep state needs to be readable, the minimal addition to `lls_core.lua` is a **single** `mp.register_script_message("lls-state-query", ...)` handler that returns a **semantic** JSON snapshot — not a dump of raw internals.

---

### Decision 3: Semantic State, Not Raw Internal Dumps

The original design exposes `FSM.MEDIA_STATE`, raw OSD overlay strings, and `Tracks` internals. This tests the *implementation*, not the *behavior*. When a variable is renamed or the FSM restructured, every test breaks with no useful failure message.

**Semantic API contract** (what the `lls-state-query` handler returns):

```json
{
  "autopause": "ON",
  "drum_mode": "OFF",
  "drum_window": "DOCKED",
  "active_sub_index": 3,
  "playback_state": "SINGLE_ASS",
  "dw_cursor": {"line": 2, "word": 1},
  "dw_selection_count": 0
}
```

ASS string content for rendering verification is exposed via a separate `lls-render-query` message that returns the current `.data` field of the named overlay — but framed as structured word-style data, not a raw ASS blob.

---

### Decision 4: Do NOT Auto-Parse spec.md into Tests

The original proposal (Tasks 4.1–4.3) describes parsing `spec.md` Gherkin scenarios and auto-mapping them to Python functions. This is a significant mistake for three reasons:

1. **The 165 spec.md files are documentation, not executable definitions.** The scenarios contain English prose, not machine-parseable step definitions with stable identifiers.
2. **Any parser will lag behind spec edits.** Every time a scenario is reworded, the parser breaks or silently decouples from the test.
3. **The mapping layer adds indirection without value.** A hand-written test that says `-- Scenario: Verifying highlight color (shared-rendering-utils/spec.md)` is clearer, more maintainable, and requires zero parsing infrastructure.

**Approach**: Tests are written by hand, one test file per spec capability. A comment in the test file cites the spec path and scenario. The spec is the design document; the test file is the code artifact.

---

### Decision 5: PowerShell for IPC Driver, Not Python + win32file

The existing codebase already uses PowerShell for Windows-specific operations (clipboard, GoldenDict integration). Adding Python + `win32file` introduces an external dependency that may not be present and adds maintenance overhead.

PowerShell has native named pipe support via `System.IO.Pipes.NamedPipeClientStream`:

```powershell
$pipe = [System.IO.Pipes.NamedPipeClientStream]::new(".", "mpv-test", [System.IO.Pipes.PipeDirection]::InOut)
$pipe.Connect(5000)
```

For the IPC driver, a PowerShell module (`tests/ipc/MpvIpc.psm1`) is sufficient. If the test suite grows to need pytest-style parametrization or reporting, Python is an acceptable escalation path — but only after the PowerShell layer proves inadequate.

---

### Decision 6: Fix the `Diagnostic` Naming Collision

The original proposal adds `Diagnostic.get_state()` to `lls_core.lua`. `Diagnostic` is already the logging system (line 44) — a production module with `ERROR/WARN/INFO/DEBUG/TRACE` levels. Extending it with state-query methods conflates two completely different concerns.

The state-query handler should live in a separate `LLSStateProbe` table, or simply be a standalone function `lls_state_snapshot()`.

---

## Risks / Trade-offs

- **busted on Windows**: Installing busted requires LuaRocks or a pre-built binary. One-time setup cost, but then zero-friction for unit tests.
- **Companion script timing**: `lls_test.lua` must account for the tick loop's 50ms cadence — state queries immediately after a key press may read pre-tick state. Use `mp.add_timeout(0.1, ...)` as a buffer.
- **lls_core.lua locals**: Several functions are `local` in the file scope. For unit tests, the test files will need to either require a refactored module or test via the public-ish interface. The minimal refactoring required: extract the pure utility functions (ASS formatters, layout calculators) into a `scripts/lls_utils.lua` module that both `lls_core.lua` and the unit tests can require.
- **Test fixtures**: Acceptance tests presuppose a known media file with known subtitle content. A small set of `.srt` fixtures checked into `tests/fixtures/` is required. Without fixtures, tests are not reproducible.
