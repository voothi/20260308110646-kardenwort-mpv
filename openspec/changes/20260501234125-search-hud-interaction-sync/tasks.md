## 1. Preparation & Aesthetic Calibration

- [ ] 1.1 Update `anki_split_depth_1` default value to `FF88B0` (Standard Purple) in `lls_core.lua` to ensure spec compliance.
- [ ] 1.2 Synchronize `draw_search_ui` background box style to include `\3a` and `\4a` tags matching `opacity_hex`.
- [ ] 1.3 Simplify the Search UI by setting `\bord0` for both the background box and results (abandoning the explicit frame) as suggested by the user.

## 2. Rendering Refactor (LLS Core)

- [ ] 2.1 Refactor `draw_search_ui` to calculate `input_box_h` using the actual line count of the wrapped query (`#query_vlines`).
- [ ] 2.2 Update `results_y` to use the dynamic `input_box_h`.
- [ ] 2.3 Implement `FSM.SEARCH_HIT_ZONES` population inside the results rendering loop in `draw_search_ui`.
- [ ] 2.4 Ensure `FSM.SEARCH_HIT_ZONES` accounts for multi-line wrapped results correctly.

## 3. Interaction Synchronization

- [ ] 3.1 Refactor `search_mouse_click` to use `FSM.SEARCH_HIT_ZONES` for O(1) hit-testing instead of fixed height calculations.
- [ ] 3.2 Verify that clicking on the last results in the dropdown works correctly even when previous results are wrapped.
- [ ] 3.3 Conduct a regression test to ensure keyboard navigation (UP/DOWN) remains synchronized with the visual selection.

## 4. Verification

- [ ] 4.1 Confirm "Surgical Precision" of click targets across different query lengths.
- [ ] 4.2 Verify aesthetic parity with v1.58.0 (no blooming, synchronized transparency).
