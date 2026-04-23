# Tasks: Cross-Platform Clipboard Support

## 1. Abstraction Layer
- [x] Implement platform detection logic in `lls_core.lua`
- [x] Create `get_clipboard()` and `set_clipboard(text)` helpers
- [x] Map platform utilities (PowerShell, pbcopy, wl-copy, etc.)
- [x] Implement shell string escaping in `set_clipboard`

## 2. Refactoring
- [x] Refactor `cmd_dw_copy` to use new helpers
- [x] Refactor `cmd_copy_sub` to use new helpers
- [x] Refactor `paste_from_clipboard` to use new helpers

## 3. Validation
- [x] Verify continued functionality on Windows 11
- [x] Confirm correct OS branching for non-Windows platforms
- [x] Test clipboard operations with special characters (quotes/spaces)
