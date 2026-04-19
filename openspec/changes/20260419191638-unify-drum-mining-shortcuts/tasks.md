## 1. Core Logic Refactoring

- [x] 1.1 Update `dw_anki_export_smart_callback` to detect paired selection context.
- [x] 1.2 Enable `ctrl_commit_set` triggering from the smart callback without requiring modifier presence.
- [x] 1.3 Refactor `cmd_dw_toggle_pink` to support both mouse (hit-test) and keyboard (cursor) inputs.

## 2. Multi-Delimiter Parser & Unified Configuration

- [x] 2.1 Implement `parse_and_bind` helper function using `gmatch("[^%s,;]+")`.
- [x] 2.2 Rename and consolidate action parameters (`dw_key_add`, `dw_key_pair`, etc.) in the `Options` table.
- [x] 2.3 Update `manage_dw_bindings` to process unified action lists instead of individual hardcoded parameters.

## 3. Configuration & Documentation Updates

- [x] 3.1 Update `mpv.conf` with new unified parameter names and space-separated default lists.
- [x] 3.2 Remove legacy/duplicate parameters from `mpv.conf` (e.g., `dw_mouse_add`, `dw_key_add_ru`).
- [x] 3.3 Update `input.conf` internal documentation to reflect the new `r/к` and `t/е` shortcut scheme.
