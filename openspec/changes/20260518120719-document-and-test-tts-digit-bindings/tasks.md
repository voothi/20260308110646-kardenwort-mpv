## 1. Core Configuration & Script Bindings

- [x] 1.1 Implement TTS options and key bindings inside `main.lua`
- [x] 1.2 Implement layout-independent Virtual Key injection for TTS modes in clipboard trigger system

## 2. Configuration & Hotkeys Integration

- [x] 2.1 Remap video adjustments in `input.conf` to layout-independent keys (`o`/`p`/`k`/`l` and Cyrillic equivalents)
- [x] 2.2 Comment out or unignore active digits `2`..`5` in `input.conf` and explicitly ignore unused digits
- [x] 2.3 Add `@help` documentation comments for TTS digit bindings in `input.conf`
- [x] 2.4 Set active TTS key and hotkey configurations in `mpv.conf`

## 3. Regression Tests & Verification

- [x] 3.1 Create regression test suite `tests/acceptance/test_20260518115930_tts_digit_bindings.py` to guard digit binding compatibility
- [x] 3.2 Run acceptance tests to verify all regression guards pass successfully

