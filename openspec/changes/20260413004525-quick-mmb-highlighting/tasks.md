## 1. Refactor Mouse Handling logic

- [ ] 1.1 Modify `make_mouse_handler` function in `scripts/lls_core.lua` to accept an optional `on_up_callback` parameter.
- [ ] 1.2 Update the `up` event branch in `make_mouse_handler` to execute `on_up_callback(tbl)` if it is provided.

## 2. Implement MMB Quick Export

- [ ] 2.1 Refactor `cmd_dw_export_anki` in `scripts/lls_core.lua` to use the `make_mouse_handler(false, export_logic)` pattern.
- [ ] 2.2 Ensure the export logic (currently the body of `cmd_dw_export_anki`) is correctly packaged as a callback that executes on button release.
- [ ] 2.3 Verify that single-click MMB still works by ensuring the export logic handles cases where `DW_ANCHOR_LINE` is `-1`.

## 3. Verification

- [ ] 3.1 Verify that holding MMB now performs a red selection drag in the Drum Window.
- [ ] 3.2 Verify that releasing MMB immediately turns the selection green and saves to Anki TSV.
- [ ] 3.3 Verify that LMB behavior remains unchanged (selects without exporting).
- [ ] 3.4 Verify that "SCM" (Middle click on existing selection) behavior is preserved.
