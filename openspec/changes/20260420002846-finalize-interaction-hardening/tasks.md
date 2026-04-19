## 1. Mouse Interaction Hardening

- [x] 1.1 Add `updates_selection` parameter to `make_mouse_handler` and implement Phase 2/3 gating.
- [x] 1.2 Implement `MOUSE_HANDLERS` weak table registry to track factory-generated functions.
- [x] 1.3 Refactor `parse_and_bind` to detect registered mouse handlers and avoid redundant wrapping.
- [x] 1.4 Update all tooltip-related bindings in `manage_dw_bindings` to use `updates_selection = false`.

## 2. Global Mouse Shield

- [x] 2.1 Implement the `nav(fn, key_name)` wrapper function inside `manage_dw_bindings`.
- [x] 2.2 Add modifier exclusion logic (`Ctrl`, `Shift`, `Alt`, `Meta`) to the `nav` wrapper.
- [x] 2.3 Wrap all static keyboard navigation keys (Arrows, Enter, ESC, etc.) in the `nav` decorator.
- [x] 2.4 Incorporate the 150ms shield into the dynamic `parse_and_bind` keyboard path.

## 3. Initialization & Cleanup

- [x] 3.1 Relax `cmd_toggle_dw` validation to support internal memory-loaded subtitles.
- [x] 3.2 Refactor `cmd_dw_toggle_pink` to remove legacy cursor-sync during mouse interactions.
- [x] 3.3 Verify that `LOCKED_LINE` logic respects the informational isolation (skipping lock on release for RMB).
