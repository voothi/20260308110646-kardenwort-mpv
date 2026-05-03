## 1. Core Logic Refactoring

- [x] 1.1 Add `goldendict_trigger` option to `Options` in `lls_core.lua`
- [x] 1.2 Implement `mp.set_property("clipboard")` in `set_clipboard`
- [x] 1.3 Add `WScript.Shell` hotkey trigger logic to `set_clipboard`
- [x] 1.4 Synchronize `mpv.conf` with new defaults and recommended retry delay

## 2. Verification

- [x] 2.1 Verify native clipboard setting works on Windows
- [x] 2.2 Verify `goldendict_trigger=yes` successfully triggers the dictionary popup
- [x] 2.3 Verify PowerShell fallback works if native property is forced to fail
