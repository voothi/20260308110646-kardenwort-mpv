## 1. Diagnostic State Probe (Lua)

- [ ] 1.1 Implement `Diagnostic.get_state()` in `lls_core.lua` to aggregate FSM and Track data.
- [ ] 1.2 Register `script-message test-probe` to return JSON-formatted state via IPC.
- [ ] 1.3 Add `test-click` script message to simulate mouse interactions with OSD coordinates.
- [ ] 1.4 Expose `osd-overlay` data structure for external inspection.

## 2. Test Driver Infrastructure (Python)

- [ ] 2.1 Create `tests/runner.py` to manage mpv lifecycle (start/stop/restart).
- [ ] 2.2 Implement `MpvIpcClient` class for synchronous communication over Windows named pipes.
- [ ] 2.3 Create utility functions for `send_key`, `click_at`, and `get_overlay_data`.

## 3. Aesthetic Validation Logic (Python)

- [ ] 3.1 Implement an ASS tag parser in the Python driver to extract styles (\1c, \3c, \b, etc.).
- [ ] 3.2 Create assertions for color verification (e.g., `assert_word_color(text, color_bgr)`).
- [ ] 3.3 Create assertions for font weight verification (e.g., `assert_is_bold(text)`).

## 4. Spec-to-Test Orchestration

- [ ] 4.1 Implement a parser for `spec.md` to identify "Scenario" blocks.
- [ ] 4.2 Create a mapping between Gherkin steps (WHEN/THEN) and Python test functions.
- [ ] 4.3 Implement a summary reporter for "Acceptance Results".

## 5. Pilot Implementation

- [ ] 5.1 Implement a full test suite for `openspec/specs/shared-rendering-utils/spec.md`.
- [ ] 5.2 Verify that breaking a hex conversion function triggers a test failure.
- [ ] 5.3 Verify that mouse click hit-zones are correctly reported over IPC.
