## 1. Test Infrastructure Setup

- [ ] 1.1 Create `tests/acceptance/test_20260513102658_vscode_text_navigation.py` base.
- [ ] 1.2 Implement helper functions for FSM state querying in the test file.
- [ ] 1.3 Create a specific SRT fixture with multi-line and single-line samples for movement tests.

## 2. Implement Navigation Tests

- [ ] 2.1 Test basic token movement (Arrow Left/Right).
- [ ] 2.2 Test line-to-line transitions (Right at EOL, Left at SOL).
- [ ] 2.3 Test vertical movement (Arrow Up/Down) across subtitles.
- [ ] 2.4 Test multi-line subtitle navigation (Down within the same subtitle).

## 3. Implement Selection and Jump Tests

- [ ] 3.1 Test selection extension with Shift + Arrow keys.
- [ ] 3.2 Test selection collapse (releasing Shift or moving without Shift).
- [ ] 3.3 Test jump movement with Ctrl + Arrow keys (5-token jumps).
- [ ] 3.4 Test jump selection with Ctrl + Shift + Arrow keys.

## 4. Verification and Hardening

- [ ] 4.1 Verify Sticky-X behavior during vertical navigation.
- [ ] 4.2 Run full suite and ensure no regressions in existing tests.
- [ ] 4.3 Audit FSM logs to ensure no trace level errors during rapid navigation.
