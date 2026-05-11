# Test Suite

Two test tiers: Lua unit tests (no mpv required) and Python acceptance tests (headless mpv via IPC).

## Run unit tests

Requires a Lua interpreter (`lua`, `lua5.4`, `lua5.3`, or `luajit`) on `PATH`, or set `LUA=/path/to/lua`.

Run from the **project root**:

```
python tests/run_unit.py
```

Expected output: `OK (6 tests, 6 assertions)` or similar.

## Run acceptance tests

Requires:
- `mpv` on `PATH`
- Python with pytest: `pip install -r tests/requirements.txt`

Run from the **project root**:

```
python -m pytest tests/acceptance/ -v
```

### Headless mpv flags used

`--no-config --vo=null --no-terminal --idle=once`

These prevent any window from opening, suppress all user config bleed-through, and make mpv quit automatically after the test fixture finishes (if IPC quit is not sent first).

### IPC path per platform

| Platform | Path |
|----------|------|
| Windows  | `\\.\pipe\mpv-kardenwort-test` (Win32 named pipe) |
| Linux/macOS | `/tmp/mpv-kardenwort-test.sock` (Unix socket) |

### Single-instance limitation

Only one mpv test session can hold the IPC path at a time. Do not run acceptance tests in parallel (pytest-xdist `-n auto`) without first parametrizing each session with a unique IPC path.


