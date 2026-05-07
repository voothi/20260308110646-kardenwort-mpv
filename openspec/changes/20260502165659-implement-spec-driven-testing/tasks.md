# Implementation Tasks

Each task lists **What**, **Why**, **How**, and **Done when**. Work top-to-bottom — phases depend on the previous one. Total budget: ~5 working days.

---

## Phase 1 — Test infrastructure foundation (~0.5 day)

### 1.1 Create directory layout

- [ ] **What**: Create the directory tree.
- [ ] **How**:
  ```
  tests/
    README.md
    run_unit.ps1
    run_unit.lua
    lua/
      luaunit.lua            ← vendored
    unit/
      test_ass_alpha.lua
      test_utf8.lua
    ipc/
      MpvIpc.psm1
      Start-MpvTest.ps1
    acceptance/
      test_state_probe.ps1
      test_drum_mode.ps1
      test_render.ps1
    fixtures/
      README.md
      test_minimal.srt
  ```
- [ ] **Done when**: Tree exists. Empty placeholder files are fine.

### 1.2 Vendor luaunit

- [ ] **What**: Drop `luaunit.lua` (single file, MIT) into `tests/lua/`.
- [ ] **Why**: Avoids LuaRocks. Single dependency you can read in 10 minutes.
- [ ] **How**: Download `luaunit.lua` from `https://github.com/bluebird75/luaunit` (latest release). Commit verbatim. Add a `LICENSE-luaunit` file with the upstream license.
- [ ] **Done when**: `lua tests/lua/luaunit.lua` exits 0 (it should — the file is loadable on its own).

### 1.3 Add test runners

- [ ] **What**: `tests/run_unit.lua` discovers and runs all `tests/unit/test_*.lua`. `tests/run_unit.ps1` is a thin wrapper that invokes `lua` (or LuaJIT) on the runner.
- [ ] **Why**: One command per tier. CI-friendly later.
- [ ] **How** — `tests/run_unit.lua`:
  ```lua
  package.path = package.path .. ";tests/lua/?.lua;tests/unit/?.lua;scripts/?.lua"
  local lu = require("luaunit")
  -- discover and require every test_*.lua
  local lfs_ok, lfs = pcall(require, "lfs")
  -- if no lfs, fall back to a hard-coded list (acceptable for ~10 files)
  for _, name in ipairs({ "test_ass_alpha", "test_utf8" }) do
      require(name)
  end
  os.exit(lu.LuaUnit.run())
  ```
- [ ] **Done when**: `pwsh tests/run_unit.ps1` prints `Ran 0 tests in 0.000 seconds, OK`.

---

## Phase 2 — Pure-function extraction & first unit tests (~1 day)

### 2.1 Create `scripts/lls_utils.lua`

- [ ] **What**: New module exporting exactly three functions:
  - `M.calculate_ass_alpha(val)` — moved from `lls_core.lua:1294`.
  - `M.utf8_to_table(str)` — moved from `lls_core.lua:1315`.
  - `M.is_valid_mpv_key(k_str)` — moved from `lls_core.lua:83`.
- [ ] **Why**: Test surface for the unit tier. These three are truly pure (no `Options`, no `mp`, no `FSM`).
- [ ] **How**: Each function returns the same outputs for the same inputs as before. The module ends with `return M`.
- [ ] **Done when**: `lua -e "print(require('scripts.lls_utils').calculate_ass_alpha(0.5))"` prints `80`.

### 2.2 Update `lls_core.lua` to consume the module

- [ ] **What**: At the top of `lls_core.lua` add:
  ```lua
  local U = require("lls_utils")
  ```
  Replace each in-file definition of the three extracted functions with a local alias:
  ```lua
  local calculate_ass_alpha = U.calculate_ass_alpha
  local utf8_to_table = U.utf8_to_table
  local is_valid_mpv_key = U.is_valid_mpv_key
  ```
- [ ] **Why**: Keep the file's call sites unchanged — only the definition moves. Lower regression risk than rewriting every call.
- [ ] **Done when**: mpv loads `lls_core.lua` cleanly with a real subtitle file, drum mode toggles, and the seek OSD shows correct alpha values. Manual smoke test, ~2 minutes.

### 2.3 Write `tests/unit/test_ass_alpha.lua`

- [ ] **What**: Boundary-value tests for `calculate_ass_alpha`.
- [ ] **How**:
  ```lua
  local lu = require("luaunit")
  local U  = require("lls_utils")

  TestAssAlpha = {}

  function TestAssAlpha:testFullyOpaque()
      lu.assertEquals(U.calculate_ass_alpha(1), "00")
  end
  function TestAssAlpha:testFullyTransparent()
      lu.assertEquals(U.calculate_ass_alpha(0), "FF")
  end
  function TestAssAlpha:testHalfOpacity()
      lu.assertEquals(U.calculate_ass_alpha(0.5), "80")
  end
  function TestAssAlpha:testHexPassthrough()
      lu.assertEquals(U.calculate_ass_alpha("aa"), "AA")
  end
  function TestAssAlpha:testInvalidInputDefaults()
      lu.assertEquals(U.calculate_ass_alpha("garbage"), "00")
  end
  function TestAssAlpha:testNilInputDefaults()
      lu.assertEquals(U.calculate_ass_alpha(nil), "00")
  end
  ```
- [ ] **Done when**: `pwsh tests/run_unit.ps1` reports 6 passed.

### 2.4 Write `tests/unit/test_utf8.lua`

- [ ] **What**: Tests for `utf8_to_table` covering ASCII, Cyrillic, German diacritics, and CJK.
- [ ] **How**: `lu.assertEquals(#U.utf8_to_table("привет"), 6)` and similar.
- [ ] **Done when**: All cases pass; one deliberate-fail run (e.g., `assertEquals(#..., 99)`) confirms the runner reports failure with a diff.

---

## Phase 3 — In-script probe (~0.5 day)

### 3.1 Append the probe block to `lls_core.lua`

- [ ] **What**: Add a clearly-delimited block at the end of `lls_core.lua`:
  ```lua
  -- =========================================================================
  -- STATE PROBE (test instrumentation)
  -- Dormant in production. Activated by IPC `script-message-to lls_core ...`.
  -- =========================================================================
  local LlsProbe = {}

  function LlsProbe._snapshot()
      return {
          autopause          = FSM.AUTOPAUSE,
          drum_mode          = FSM.DRUM,
          drum_window        = FSM.DRUM_WINDOW,
          active_sub_index   = FSM.ACTIVE_IDX,
          playback_state     = FSM.MEDIA_STATE,
          dw_cursor          = { line = FSM.DW_CURSOR_LINE, word = FSM.DW_CURSOR_WORD },
          dw_selection_count = #(FSM.DW_CTRL_PENDING_LIST or {}),
          immersion_mode     = FSM.IMMERSION_MODE,
          copy_mode          = FSM.COPY_MODE,
          loop_mode          = FSM.LOOP_MODE,
          book_mode          = FSM.BOOK_MODE,
      }
  end

  mp.register_script_message("lls-state-query", function()
      mp.set_property("user-data/lls/state", utils.format_json(LlsProbe._snapshot()))
  end)

  mp.register_script_message("lls-render-query", function(overlay_name)
      local map = {
          drum    = drum_osd,
          dw      = dw_osd,
          tooltip = dw_tooltip_osd,
          search  = search_osd,
          seek    = seek_osd,
      }
      local osd = map[overlay_name]
      mp.set_property("user-data/lls/render", (osd and osd.data) or "")
  end)
  ```
- [ ] **Why**: Two-handler API, no flag, zero cost when nobody queries it. Semantic snapshot insulates tests from future FSM renames.
- [ ] **Watch out**: `drum_osd`, `dw_osd`, etc. are file-scoped locals at lines 612, 937, 942. The probe block must be **after** their declarations. Easiest: append at the very end of the file, after the last `mp.add_periodic_timer` registration.
- [ ] **Done when**: `lls_core.lua` still loads cleanly under mpv with the same manual smoke test as 2.2.

### 3.2 Manual probe verification

- [ ] **What**: Without writing any test code yet, confirm the probe round-trips.
- [ ] **How** (run in two PowerShell windows):
  ```powershell
  # Window A — start mpv with IPC and a fixture
  mpv --no-config --vo=null --no-terminal --idle=once `
      --input-ipc-server=\\.\pipe\mpv-test `
      --script=scripts\lls_core.lua `
      tests\fixtures\test_minimal.srt

  # Window B — query the probe
  $pipe = [System.IO.Pipes.NamedPipeClientStream]::new(".", "mpv-test", "InOut")
  $pipe.Connect(5000)
  $w = [System.IO.StreamWriter]::new($pipe); $w.AutoFlush = $true
  $r = [System.IO.StreamReader]::new($pipe)
  $w.WriteLine('{"command":["script-message-to","lls_core","lls-state-query"],"request_id":1}')
  Start-Sleep -Milliseconds 200
  $w.WriteLine('{"command":["get_property","user-data/lls/state"],"request_id":2}')
  while (-not $r.EndOfStream) { $r.ReadLine() }
  ```
- [ ] **Done when**: One of the JSON lines printed is the snapshot returned for `request_id: 2`, with all the semantic fields populated.

---

## Phase 4 — PowerShell IPC driver (~1 day)

### 4.1 `tests/ipc/MpvIpc.psm1` — connection & send

- [ ] **What**: PowerShell module exporting `Connect-MpvIpc`, `Send-MpvCommand`, `Disconnect-MpvIpc`.
- [ ] **Why**: Encapsulates the pipe lifecycle and request/response correlation. Test files should not deal with `StreamReader`.
- [ ] **How**:
  - Connection state held in a hashtable returned to the caller.
  - Each `Send-MpvCommand` increments a `request_id` counter, writes the JSON line, then reads lines until one matches that `request_id`. Any line whose top-level key is `event` is handled separately (events are emitted asynchronously and interleave with responses).
  - Time out after 5 seconds with a `throw`.
- [ ] **Done when**: From PowerShell:
  ```powershell
  Import-Module ./tests/ipc/MpvIpc.psm1
  $s = Connect-MpvIpc -PipeName "mpv-test"
  $r = Send-MpvCommand -Session $s -Command @("get_property","mpv-version")
  $r.data  # → "0.39.0" or similar
  Disconnect-MpvIpc -Session $s
  ```

### 4.2 Probe helpers

- [ ] **What**: `Invoke-LlsStateQuery` and `Invoke-LlsRenderQuery -Overlay <name>`.
- [ ] **Why**: Hides the two-step send-then-read pattern.
- [ ] **How**:
  1. Call `observe_property 1 user-data/lls/state` (subscribes to changes).
  2. Send `script-message-to lls_core lls-state-query`.
  3. Wait up to 1 s for a `property-change` event for `user-data/lls/state`.
  4. Call `unobserve_property 1`.
  5. Parse the `data` field from the event with `ConvertFrom-Json`. Return as a PSCustomObject.
- [ ] **Done when**: `Invoke-LlsStateQuery -Session $s` returns an object whose `.autopause` matches the script's default.

### 4.3 `tests/ipc/Start-MpvTest.ps1`

- [ ] **What**: Boots a headless mpv against a given fixture and connects.
- [ ] **How**:
  ```powershell
  param(
      [string]$Fixture = "tests/fixtures/test_minimal.srt",
      [string]$PipeName = "mpv-test"
  )
  $proc = Start-Process mpv `
      -ArgumentList @(
          "--no-config", "--vo=null", "--no-terminal", "--idle=once",
          "--input-ipc-server=\\.\pipe\$PipeName",
          "--script=scripts\lls_core.lua",
          $Fixture
      ) -PassThru -NoNewWindow
  # poll for pipe availability up to 5 s
  $session = Connect-MpvIpc -PipeName $PipeName
  return @{ Session = $session; Process = $proc }
  ```
  Pair with `Stop-MpvTest` that runs `Send-MpvCommand quit` then `Stop-Process` on the PID as a fallback.
- [ ] **Done when**: `Start-MpvTest.ps1` returns a session object; `Stop-MpvTest` exits cleanly.

---

## Phase 5 — Fixtures (~0.5 day)

### 5.1 `tests/fixtures/test_minimal.srt`

- [ ] **What**: Three SRT entries with documented timestamps and word counts.
- [ ] **How**:
  ```
  1
  00:00:01,000 --> 00:00:03,000
  Hello world

  2
  00:00:04,000 --> 00:00:06,000
  This is a test

  3
  00:00:07,000 --> 00:00:09,000
  Final entry
  ```
- [ ] **Done when**: mpv loads it without errors and lls_core enters `SINGLE_SRT` playback state (verifiable via the probe).

### 5.2 `tests/fixtures/README.md`

- [ ] **What**: Document each fixture's contract: timestamps, total entries, word counts per entry, which acceptance tests depend on it.
- [ ] **Why**: Without this, a future developer changing a fixture will silently break tests.
- [ ] **Done when**: Each `.srt` has a corresponding section listing every test that reads it.

---

## Phase 6 — Pilot acceptance tests (~1 day)

Each `.ps1` follows the same pattern: `Start-MpvTest`, run assertions, `Stop-MpvTest` in a `finally`.

### 6.1 `tests/acceptance/test_state_probe.ps1`

- [ ] **What**: Boots mpv with `test_minimal.srt`, queries the probe, asserts default state values.
- [ ] **Spec ref**: `# Spec: openspec/changes/.../specs/automated-acceptance-testing/spec.md` — Scenario "Querying playback state".
- [ ] **Done when**: `playback_state -eq "SINGLE_SRT"`, `drum_mode -eq "OFF"`, etc.

### 6.2 `tests/acceptance/test_drum_mode.ps1`

- [ ] **What**: Sends `script-binding lls_core/toggle-drum-mode` via IPC, then queries the probe.
- [ ] **Note**: Use `script-binding`, not raw key codes — the binding is the public contract; the keypress is the implementation.
- [ ] **Done when**: `drum_mode -eq "ON"` after the binding fires.

### 6.3 `tests/acceptance/test_render.ps1`

- [ ] **What**: With drum mode active, queries `lls-render-query dw`, asserts the returned ASS string contains the expected color tag for highlighted words.
- [ ] **Done when**: `$render -match '\\1c&H[0-9A-Fa-f]{6}&'` succeeds.

---

## Phase 7 — Verification & docs (~0.5 day)

### 7.1 Negative-test the unit tier

- [ ] **What**: Edit `lls_utils.lua` to break `calculate_ass_alpha` (e.g., off-by-one). Run `run_unit.ps1`, confirm it reports the failure with a useful diff. Revert.

### 7.2 Negative-test the acceptance tier

- [ ] **What**: Temporarily change one snapshot field in the probe (e.g., `autopause = "WRONG"`). Run `test_state_probe.ps1`, confirm assertion failure. Revert.

### 7.3 Write `tests/README.md`

- [ ] **What**: Two sections — "Run unit tests" and "Run acceptance tests" — each with the exact PowerShell command. Note the headless mpv flags. Note the pipe-name single-instance limitation.

### 7.4 Final smoke test

- [ ] **What**: Fresh checkout (or `git stash` your work), run both tiers from scratch, confirm green.

---

## Out of scope for this change (track in follow-ups)

- Extracting `format_highlighted_word`, `dw_build_layout`, hit-test functions to `lls_utils.lua` (they read `Options`/`FSM` — needs stub plumbing).
- Parametrizing pipe names for parallel runs.
- CI integration.
- Rendering tests beyond ASS-tag presence (e.g., layout metric assertions).
