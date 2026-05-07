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
