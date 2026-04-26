## 1. Preparation

- [ ] 1.1 Verify current behavior: Reproduce the copy failure in Regular mode with Context OFF.

## 2. Implementation

- [ ] 2.1 Fix the `ctext` empty string check at L5802 to prevent `"\n"` from being treated as valid content.
- [ ] 2.2 Refactor `cmd_copy_sub` to use `Tracks.pri.subs` and `Tracks.sec.subs` if `mp.get_property` returns an empty string.
- [ ] 2.3 Ensure `FSM.COPY_MODE` (A/B) is correctly applied when extracting text from internal tracks.

## 3. Verification

- [ ] 3.1 Test `Ctrl+c` in Regular Mode with `Context OFF`: Should copy the current subtitle.
* - [ ] 3.2 Test `Ctrl+c` in White Subtitles Mode (SRT OSD) with `Context OFF`: Should copy correctly.
- [ ] 3.3 Test `Ctrl+c` with `Context ON`: Ensure no regressions in context gathering.
- [ ] 3.4 Test `z` (Copy Mode) toggle: Verify it correctly switches between source and translation in the clipboard.
