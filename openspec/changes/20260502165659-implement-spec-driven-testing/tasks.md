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
    run_unit.py              ← cross-platform Lua runner (Python wrapper)
    run_unit.lua             ← discovers and runs tests/unit/test_*.lua
    requirements.txt         ← pytest only
    lua/
      luaunit.lua            ← vendored
    unit/
      test_ass_alpha.lua
      test_utf8.lua
    ipc/
      mpv_ipc.py             ← cross-platform IPC client (stdlib only)
      mpv_session.py         ← mpv lifecycle helper (pytest fixture)
    acceptance/
      conftest.py            ← shared pytest fixtures (mpv session)
      test_state_probe.py
      test_drum_mode.py
      test_render.py
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

- [ ] **What**: `tests/run_unit.lua` discovers and runs all `tests/unit/test_*.lua`. `tests/run_unit.py` is a thin Python wrapper that finds `lua` (or LuaJIT) and invokes the Lua runner. `tests/requirements.txt` holds the single `pytest` dependency.
- [ ] **Why**: One command per tier. Python wrapper avoids platform-specific shell scripts.
- [ ] **How** — `tests/run_unit.lua`:
  ```lua
  package.path = package.path .. ";tests/lua/?.lua;tests/unit/?.lua;scripts/?.lua"
  local lu = require("luaunit")
  -- hard-coded list is fine for ~10 files; expand as the suite grows
  for _, name in ipairs({ "test_ass_alpha", "test_utf8" }) do
      require(name)
  end
  os.exit(lu.LuaUnit.run())
  ```
- [ ] **How** — `tests/run_unit.py`:
  ```python
  #!/usr/bin/env python3
  import subprocess, sys, os, shutil

  def find_lua():
      for name in ('lua', 'lua5.4', 'lua5.3', 'luajit'):
          if shutil.which(name):
              return name
      return None

  lua = os.environ.get('LUA') or find_lua()
  if not lua:
      sys.exit('ERROR: no Lua interpreter found. Set LUA=/path/to/lua or install lua.')
  sys.exit(subprocess.run([lua, 'tests/run_unit.lua']).returncode)
  ```
- [ ] **How** — `tests/requirements.txt`:
  ```
  pytest
  ```
- [ ] **Done when**: `python tests/run_unit.py` prints `Ran 0 tests in 0.000 seconds, OK`.

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
- [ ] **Done when**: `python tests/run_unit.py` reports 6 passed.

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

- [ ] **What**: Without writing any test code yet, confirm the probe round-trips. Use a small inline Python script to avoid building the full IPC module first.
- [ ] **How**: Run in two separate terminals. In terminal A:
  ```
  # Windows
  mpv --no-config --vo=null --no-terminal --idle=once
      --input-ipc-server=\\.\pipe\mpv-lls-test
      --script=scripts\lls_core.lua
      tests\fixtures\test_minimal.srt

  # Linux / macOS
  mpv --no-config --vo=null --no-terminal --idle=once
      --input-ipc-server=/tmp/mpv-lls-test.sock
      --script=scripts/lls_core.lua
      tests/fixtures/test_minimal.srt
  ```
  In terminal B (platform-adaptive Python, no third-party packages):
  ```python
  import json, os, socket, time

  if os.name == 'nt':
      conn = open(r'\\.\pipe\mpv-lls-test', 'r+b', buffering=0)
      send = lambda d: conn.write(d)
      recv = lambda: conn.read(4096)
  else:
      s = socket.socket(socket.AF_UNIX); s.connect('/tmp/mpv-lls-test.sock')
      send = lambda d: s.sendall(d)
      recv = lambda: s.recv(4096)

  send(b'{"command":["script-message-to","lls_core","lls-state-query"],"request_id":1}\n')
  time.sleep(0.3)
  send(b'{"command":["get_property","user-data/lls/state"],"request_id":2}\n')
  time.sleep(0.3)
  print(recv().decode())
  ```
- [ ] **Done when**: The output contains a JSON line for `request_id: 2` whose `data` field is the semantic snapshot with all expected fields.

---

## Phase 4 — Python IPC driver (~1 day)

### 4.1 `tests/ipc/mpv_ipc.py` — connection & send

- [ ] **What**: Cross-platform IPC client using only Python stdlib. Exports `MpvIpc`.
- [ ] **Why**: Encapsulates the platform-specific transport and request/response correlation. Acceptance tests never import `os`, `socket`, or platform detection — they just call `ipc.command(...)`.
- [ ] **How**: The key design points:
  - `_open_transport()` selects the connection method by `os.name`:
    - Windows: `open(path, 'r+b', buffering=0)` — Python's `io.FileIO` calls `CreateFile()` for Win32 named pipes. No `win32file` needed.
    - Linux/macOS: `socket.socket(socket.AF_UNIX)` + `s.makefile('rwb', buffering=0)`.
  - A background `threading.Thread` reads lines and dispatches: responses (have `request_id`) are matched to a `threading.Event` stored in a `_pending` dict; events (have `event`) go to an event queue.
  - `command(cmd, timeout=5.0)` increments a `_rid` counter, writes JSON, waits on the event, returns the response dict.
  - `get_property(name)` is a one-liner on top of `command`.
  - `observe_property(obs_id, name)` + `wait_property_change(name, timeout)` for the probe query pattern.

  Skeleton:
  ```python
  # tests/ipc/mpv_ipc.py
  import json, os, socket, threading, time, tempfile

  def default_ipc_path():
      if os.name == 'nt':
          return r'\\.\pipe\mpv-lls-test'
      return os.path.join(tempfile.gettempdir(), 'mpv-lls-test.sock')

  class MpvIpc:
      def __init__(self, path=None):
          self._path = path or default_ipc_path()
          self._rid = 0
          self._lock = threading.Lock()
          self._pending = {}   # request_id -> (Event, [result])
          self._prop_events = {}  # property name -> Event
          self._conn = None

      def connect(self, timeout=5.0):
          deadline = time.time() + timeout
          while True:
              try:
                  self._conn = self._open_transport()
                  break
              except OSError:
                  if time.time() > deadline:
                      raise TimeoutError(f'mpv IPC not ready: {self._path}')
                  time.sleep(0.1)
          threading.Thread(target=self._read_loop, daemon=True).start()

      def _open_transport(self):
          if os.name == 'nt':
              return open(self._path, 'r+b', buffering=0)
          s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
          s.connect(self._path)
          return s.makefile('rwb', buffering=0)

      def _read_loop(self):
          buf = b''
          while True:
              try:
                  chunk = self._conn.read(4096)
                  if not chunk:
                      break
                  buf += chunk
                  while b'\n' in buf:
                      line, buf = buf.split(b'\n', 1)
                      msg = json.loads(line)
                      self._dispatch(msg)
              except (OSError, json.JSONDecodeError):
                  break

      def _dispatch(self, msg):
          if 'request_id' in msg:
              with self._lock:
                  ev, holder = self._pending.get(msg['request_id'], (None, None))
              if ev:
                  holder.append(msg)
                  ev.set()
          elif msg.get('event') == 'property-change':
              name = msg.get('name', '')
              ev = self._prop_events.get(name)
              if ev:
                  ev.set()

      def command(self, cmd, timeout=5.0):
          with self._lock:
              self._rid += 1
              rid = self._rid
              ev, holder = threading.Event(), []
              self._pending[rid] = (ev, holder)
          self._conn.write(json.dumps({'command': cmd, 'request_id': rid}).encode() + b'\n')
          if not ev.wait(timeout):
              raise TimeoutError(f'mpv timeout on {cmd}')
          with self._lock:
              del self._pending[rid]
          return holder[0]

      def get_property(self, name, timeout=5.0):
          r = self.command(['get_property', name], timeout)
          if r.get('error') != 'success':
              raise RuntimeError(f'get_property({name}): {r}')
          return r['data']

      def observe_property(self, obs_id, name):
          self.command(['observe_property', obs_id, name])
          self._prop_events[name] = threading.Event()

      def wait_property_change(self, name, timeout=2.0):
          ev = self._prop_events.get(name)
          if not ev or not ev.wait(timeout):
              raise TimeoutError(f'property-change timeout: {name}')
          ev.clear()

      def close(self):
          if self._conn:
              try:
                  self._conn.close()
              except OSError:
                  pass
  ```
- [ ] **Done when**:
  ```python
  from tests.ipc.mpv_ipc import MpvIpc
  ipc = MpvIpc(); ipc.connect()
  print(ipc.get_property('mpv-version'))  # → "mpv 0.39.0" or similar
  ipc.close()
  ```

### 4.2 Probe helpers in `mpv_ipc.py`

- [ ] **What**: `query_lls_state(ipc)` and `query_lls_render(ipc, overlay_name)` module-level helpers.
- [ ] **Why**: The two-step send-then-observe-property pattern is always the same; helpers prevent copy-paste in every test.
- [ ] **How**:
  ```python
  import json

  def query_lls_state(ipc, timeout=2.0):
      ipc.observe_property(99, 'user-data/lls/state')
      ipc.command(['script-message-to', 'lls_core', 'lls-state-query'])
      ipc.wait_property_change('user-data/lls/state', timeout)
      raw = ipc.get_property('user-data/lls/state')
      return json.loads(raw) if raw else {}

  def query_lls_render(ipc, overlay_name, timeout=2.0):
      ipc.observe_property(98, 'user-data/lls/render')
      ipc.command(['script-message-to', 'lls_core', 'lls-render-query', overlay_name])
      ipc.wait_property_change('user-data/lls/render', timeout)
      return ipc.get_property('user-data/lls/render') or ''
  ```
- [ ] **Done when**: `query_lls_state(ipc)['drum_mode']` returns `'OFF'` on a clean boot.

### 4.3 `tests/ipc/mpv_session.py` — lifecycle helper

- [ ] **What**: `MpvSession` class that boots a headless mpv and exposes a connected `MpvIpc`. Used as a pytest fixture in `conftest.py`.
- [ ] **How**:
  ```python
  # tests/ipc/mpv_session.py
  import os, subprocess, sys
  from tests.ipc.mpv_ipc import MpvIpc, default_ipc_path

  class MpvSession:
      def __init__(self, fixture, ipc_path=None):
          self.ipc_path = ipc_path or default_ipc_path()
          self.fixture = fixture
          self.ipc = MpvIpc(self.ipc_path)
          self._proc = None

      def start(self):
          cmd = [
              'mpv', '--no-config', '--vo=null', '--no-terminal', '--idle=once',
              f'--input-ipc-server={self.ipc_path}',
              '--script=scripts/lls_core.lua',
              self.fixture,
          ]
          self._proc = subprocess.Popen(cmd)
          self.ipc.connect(timeout=5.0)

      def stop(self):
          try:
              self.ipc.command(['quit'], timeout=2.0)
          except Exception:
              pass
          if self._proc and self._proc.poll() is None:
              self._proc.terminate()
              self._proc.wait(timeout=5)
          self.ipc.close()
  ```
  In `tests/acceptance/conftest.py`:
  ```python
  import pytest
  from tests.ipc.mpv_session import MpvSession

  @pytest.fixture
  def mpv():
      session = MpvSession(fixture='tests/fixtures/test_minimal.srt')
      session.start()
      yield session
      session.stop()
  ```
- [ ] **Done when**: A minimal test that just calls `mpv.ipc.get_property('mpv-version')` passes via `python -m pytest tests/acceptance/`.

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

Each file is a standard pytest module. Shared fixtures live in `conftest.py`. Each file begins with a comment citing its spec.

### 6.1 `tests/acceptance/test_state_probe.py`

- [ ] **What**: Boots mpv with `test_minimal.srt`, queries the probe, asserts default state values.
- [ ] **How**:
  ```python
  # Spec: openspec/changes/.../specs/automated-acceptance-testing/spec.md
  # Scenario: Querying playback state
  import json
  from tests.ipc.mpv_ipc import query_lls_state

  def test_default_state(mpv):
      state = query_lls_state(mpv.ipc)
      assert state['playback_state'] in ('SINGLE_SRT', 'NO_SUBS')
      assert state['drum_mode'] == 'OFF'
      assert state['drum_window'] == 'OFF'
      assert state['dw_selection_count'] == 0
  ```
- [ ] **Done when**: `python -m pytest tests/acceptance/test_state_probe.py -v` passes.

### 6.2 `tests/acceptance/test_drum_mode.py`

- [ ] **What**: Sends `script-binding lls_core/toggle-drum-mode` via IPC, then queries the probe.
- [ ] **Note**: Use `script-binding`, not raw key codes — the binding name is the public contract; the physical key is the implementation detail.
- [ ] **How**:
  ```python
  # Spec: openspec/changes/.../specs/automated-acceptance-testing/spec.md
  # Scenario: Simulating a keypress
  import time
  from tests.ipc.mpv_ipc import query_lls_state

  def test_toggle_drum_mode(mpv):
      mpv.ipc.command(['script-binding', 'lls_core/toggle-drum-mode'])
      time.sleep(0.1)  # one tick (~50 ms) for state to propagate
      state = query_lls_state(mpv.ipc)
      assert state['drum_mode'] == 'ON'
  ```
- [ ] **Done when**: Test passes and fails predictably when the assertion is reversed.

### 6.3 `tests/acceptance/test_render.py`

- [ ] **What**: With drum mode active, queries `lls-render-query dw`, asserts the returned ASS string contains an expected color tag.
- [ ] **How**:
  ```python
  # Spec: openspec/changes/.../specs/automated-acceptance-testing/spec.md
  # Scenario: Verifying highlight color
  import re, time
  from tests.ipc.mpv_ipc import query_lls_render

  def test_drum_osd_contains_color_tags(mpv):
      mpv.ipc.command(['script-binding', 'lls_core/toggle-drum-mode'])
      time.sleep(0.1)
      render = query_lls_render(mpv.ipc, 'drum')
      assert re.search(r'\\1c&H[0-9A-Fa-f]{6}&', render), \
          f'No \\1c color tag found in drum OSD. Got: {render[:200]}'
  ```
- [ ] **Done when**: Test passes against a real subtitle file; a deliberate fixture break (removing the subtitle so OSD is empty) fails with the descriptive message.

---

## Phase 7 — Verification & docs (~0.5 day)

### 7.1 Negative-test the unit tier

- [ ] **What**: Edit `lls_utils.lua` to break `calculate_ass_alpha` (e.g., off-by-one). Run `python tests/run_unit.py`, confirm it reports the failure with a useful diff. Revert.

### 7.2 Negative-test the acceptance tier

- [ ] **What**: Temporarily change one snapshot field in the probe (e.g., `autopause = "WRONG"`). Run `python -m pytest tests/acceptance/test_state_probe.py`, confirm assertion failure. Revert.

### 7.3 Write `tests/README.md`

- [ ] **What**: Two sections — "Run unit tests" and "Run acceptance tests" — each with the exact cross-platform command. Note the headless mpv flags, the IPC path difference per platform, and the single-instance limitation.

### 7.4 Final smoke test

- [ ] **What**: Fresh checkout (or `git stash` your work), run both tiers from scratch, confirm green.

---

## Out of scope for this change (track in follow-ups)

- Extracting `format_highlighted_word`, `dw_build_layout`, hit-test functions to `lls_utils.lua` (they read `Options`/`FSM` — needs stub plumbing).
- Parametrizing pipe names for parallel runs.
- CI integration.
- Rendering tests beyond ASS-tag presence (e.g., layout metric assertions).
