# Implementation Plan - Missed Functional Coverage (ZID: 20260512130623)

Audit of the current test suite revealed gaps in functional verification for several critical v1.80.0 features. This plan remediates these gaps with a new acceptance test suite.

## 🎯 Objectives
1.  **Verify Shortcut Swaps**: Confirm `Shift+H` and `h` bindings are correctly mapped.
2.  **Search UX Validation**: Verify the full search flow (Open -> Type -> Select -> Seek).
3.  **Cyrillic Compatibility**: Confirm `Ctrl+ц` and other Russian layout search keys are functional.
4.  **Persistence Integrity**: Verify `b` correctly manages the Anki record file.

## 🛠️ Tasks

### 1. Diagnostic Script Messages
Add helper script messages to `scripts/kardenwort/main.lua` to allow testing internal state:
- [ ] `test-set-search-query`: Directly set the search query for rapid result testing.
- [ ] `test-get-anki-record-path`: Retrieve the path to the current record file for disk verification.

### 2. New Acceptance Test Suite
Create `tests/acceptance/test_20260512130623_missed_functional_coverage.py`:
- [ ] `test_shortcut_swap_h_and_H`: Send keypresses and verify FSM state changes for `toggle-anki-global` and `toggle-karaoke-mode`.
- [ ] `test_search_mode_flow`:
    - Open search.
    - Send `kardenwort/search-char-T`, `E`, `S`, `T`.
    - Verify `FSM.SEARCH_QUERY == "TEST"`.
    - Verify `FSM.SEARCH_RESULTS` is non-empty.
    - Send `ENTER`.
    - Verify `FSM.SEARCH_MODE == false` and player timestamp changed.
- [ ] `test_search_mode_cyrillic_delete`:
    - Set search query to "WORD1 WORD2".
    - Send `Ctrl+ц` (via `script-opts` simulation or physical key if possible).
    - Verify word deletion.
- [ ] `test_anki_record_file_creation`:
    - Press `b`.
    - Verify file existence on disk via Python's `os.path.exists`.

## 🧪 Verification
- Run the new test suite: `python -m pytest tests/acceptance/test_20260512130623_missed_functional_coverage.py`
- Verify 100% pass rate.
