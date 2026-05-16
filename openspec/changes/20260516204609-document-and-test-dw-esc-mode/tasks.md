## 1. Verification Framework

- [x] 1.1: Create acceptance test file `tests/acceptance/test_20260516204609_dw_esc_mode_cycling.py`. (Done)
- [x] 1.2: Implement `query_kardenwort_state` utility for IPC probing. (Done)

## 2. Omnidirectional Testing

- [x] 2.1: Verify circular cycling: `auto_follow` -> `neutral_last` -> `neutral_current` -> `auto_follow`. (Done)
- [x] 2.2: Verify OSD label feedback for each transition. (Done)
- [x] 2.3: Verify Cyrillic parity: `т` key behaves identically to `n`. (Done)
- [x] 2.4: Verify state persistence across DW toggles. (Done)

## 3. Documentation & Archival

- [x] 3.1: Update project's internal feature list or help documentation to include `DW Esc Mode`. (Done)
- [x] 3.2: Run the full acceptance suite and attach results to the change log. (Done)
