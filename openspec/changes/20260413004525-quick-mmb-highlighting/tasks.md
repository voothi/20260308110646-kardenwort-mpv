## 1. Refactor Mouse Handling logic

- [x] 1.1 Modify `make_mouse_handler` function in `scripts/lls_core.lua` to accept an optional `on_up_callback` parameter.
- [x] 1.2 Update the `up` event branch in `make_mouse_handler` to execute `on_up_callback(tbl)` if it is provided.

## 2. Implement MMB Quick Export

- [x] 2.1 Refactor `cmd_dw_export_anki` in `scripts/lls_core.lua` to use the `make_mouse_handler(false, export_logic)` pattern.
- [x] 2.2 Ensure the export logic (currently the body of `cmd_dw_export_anki`) is correctly packaged as a callback that executes on button release.
- [x] 2.3 Verify that single-click MMB still works by ensuring the export logic handles cases where `DW_ANCHOR_LINE` is `-1`.
- [x] 2.4 Implement `is_inside_dw_selection` helper function in `scripts/lls_core.lua` for detecting clicks within the current Red range.
- [x] 2.5 Update `make_mouse_handler` on `down` event to bypass cursor movement if clicking MMB over an existing selection.
- [x] 2.6 Add `drum_osd:update()` to the `down` event branch in `make_mouse_handler` for immediate visual feedback.

## 3. Verification

- [x] 3.1 Verify that holding MMB now performs a red selection drag in the Drum Window.
- [x] 3.2 Verify that releasing MMB immediately turns the selection green and saves to Anki TSV.
- [x] 3.3 Verify that LMB behavior remains unchanged (selects without exporting).
- [x] 3.4 Verify that "SCM" (Middle click on existing selection) behavior is preserved.
