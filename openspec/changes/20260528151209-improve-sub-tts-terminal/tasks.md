## 1. Terminal Utilities in sub_tts.py

- [ ] 1.1 Implement the `clear_line()` function in `sub_tts.py` to completely clear carriage-returned terminal lines.
- [ ] 1.2 Implement the `make_premium_progress_bar(current, total, label, detail="", bar_width=40, indent="  ")` utility using green and dim grey blocks for premium visual appeal.

## 2. Refactoring Loops

- [ ] 2.1 Refactor the TTS Synthesis loop in `synthesize_all_cues` to use `make_premium_progress_bar` when running in a TTY environment.
- [ ] 2.2 Implement throttled line-by-line fallback for TTS Synthesis in non-TTY environments (CI/logs).
- [ ] 2.3 Refactor the Speed Adjustment loop in `adjust_speed_for_cues` to use `make_premium_progress_bar` when running in a TTY environment.
- [ ] 2.4 Implement throttled line-by-line fallback for Speed Adjustment in non-TTY environments (CI/logs).
- [ ] 2.5 Ensure the final stage completions/summaries cleanly finalize terminal carriage-returns using `clear_line()`.

## 3. Testing and Verification

- [ ] 3.1 Validate visual output layout in Powershell window by running sub-tts tool with test subtitle files.
- [ ] 3.2 Verify that no carriage-return characters (`\r`) or multiple redundant lines are spammed to log files when running in redirected/non-TTY mode.
