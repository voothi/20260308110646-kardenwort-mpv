## 1. Test Environment Preparation

- [x] 1.1 Verify existing test fixtures in `tests/conftest.py` and ensure they cover required track configurations (DE/RU, single/dual SRT).
- [x] 1.2 Create `tests/acceptance/test_archived_regressions.py` skeleton with necessary imports and session helpers.

## 2. Immersion Engine Tests

- [x] 2.1 Implement `test_adaptive_replay_autopause_on`: Verify `s` key triggers correct replay behavior in Autopause ON.
- [x] 2.2 Implement `test_subtitle_looping_autopause_off`: Verify `s` key triggers infinite loop in Autopause OFF.
- [x] 2.3 Implement `test_drum_mode_navigation_sync`: Verify active index and pointer sync between primary/secondary tracks during navigation.

## 3. Input and Clipboard Tests

- [x] 3.1 Implement `test_layout_agnostic_hotkeys`: Verify Russian layout mappings (`ё` → `` ` ``) trigger intended commands.
- [x] 3.2 Implement `test_hotkey_false_positive_prevention`: Verify complex bindings aren't triggered by partial key sequences.
- [x] 3.3 Implement `test_selection_priority_in_context_copy`: Verify `Ctrl+C` copies active selection over full context when both exist.

## 4. UI and System Utilities Tests

- [x] 4.1 Implement `test_tooltip_hit_zone_accuracy`: Verify precise hover detection in Drum Window without ghost interference.
- [x] 4.2 Implement `test_highlight_aesthetic_calibration`: Verify OSD rendering tags for highlights match the "Premium" calibration.
- [x] 4.3 Implement `test_session_resume_logic`: Verify `resume_last_file.lua` correctly restores file and position.
- [x] 4.4 Implement `test_logging_suppression`: Verify smart logging reduces console spam while retaining critical diagnostics.

## 5. Verification and Hardening

- [x] 5.1 Run the new regression test suite using `pytest tests/acceptance/test_archived_regressions.py`.
- [x] 5.2 Integrate the new tests into the main `pytest` run to ensure zero regressions across the whole codebase.
- [x] 5.3 Archive the test implementation change once all tests are green.
