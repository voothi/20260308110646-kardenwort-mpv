"""
Lua-level unit tests for scripts/kardenwort/dw_pure.lua.

Runs the pure-Lua test file `tests/lua/test_dw_pure.lua` via a system Lua
interpreter. Skips gracefully when no Lua interpreter is on PATH.

Why pure-Lua testing matters: the rest of the suite either matches string
patterns against main.lua (structural) or spins up mpv via IPC (slow/flaky
on Windows). Pure helpers in dw_pure.lua can be exercised directly, giving
us real behavior coverage with no mpv stub maze.
"""

from pathlib import Path
import shutil
import subprocess

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]
LUA_TEST_FILE = REPO_ROOT / "tests" / "lua" / "test_dw_pure.lua"


def _find_lua():
    for candidate in ("lua", "lua5.5", "lua5.4", "lua5.3", "lua5.1", "luajit"):
        path = shutil.which(candidate)
        if path:
            return path
    # Repo-local fallback documented in CLAUDE.md (`C:\lua\lua-5.5.0_Win64_bin\lua.exe`)
    fallback = Path(r"C:/lua/lua-5.5.0_Win64_bin/lua.exe")
    if fallback.exists():
        return str(fallback)
    return None


def test_dw_pure_lua_unit_suite():
    lua = _find_lua()
    if not lua:
        pytest.skip("No Lua interpreter available on PATH")

    assert LUA_TEST_FILE.exists(), f"Missing Lua test file: {LUA_TEST_FILE}"

    result = subprocess.run(
        [lua, str(LUA_TEST_FILE)],
        cwd=str(REPO_ROOT),
        capture_output=True,
        text=True,
        timeout=30,
    )

    output = (result.stdout or "") + (result.stderr or "")
    assert result.returncode == 0, (
        f"dw_pure.lua unit tests failed (exit {result.returncode}).\n"
        f"Output:\n{output}"
    )
    assert "PASS" in output, f"Expected PASS summary line, got:\n{output}"
