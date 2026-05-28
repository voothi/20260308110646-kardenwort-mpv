## 1. Terminal Utilities in sub_tts.py

- [ ] 1.1 Implement the `clear_line(width=65)` function in `sub_tts.py` to completely clear carriage-returned terminal lines, using the standard precedent width constant.
- [ ] 1.2 Implement the `make_cue_progress_bar(current, total, label, detail="", bar_width=40, indent="  ")` utility using green and dim grey blocks for premium visual appeal, matching the design aesthetic of `youtube_downloader.py`.

## 2. Refactoring Loops

- [ ] 2.1 Refactor the TTS Synthesis loop in `synthesize_all_cues` to utilize `make_cue_progress_bar` using the module-level constant `_IS_TTY` for environment checks.
- [ ] 2.2 Implement the delta-based progress logging throttle for TTS Synthesis in non-TTY environments (printing only first, last, and every 10%+ increase), using the `.lstrip("\r")` method.
- [ ] 2.3 Refactor the Speed Adjustment loop in `adjust_speed_for_cues` to utilize `make_cue_progress_bar` using the module-level constant `_IS_TTY` for environment checks, ensuring that `[current/total]` progress brackets are styled with `_dim`.
- [ ] 2.4 Implement the delta-based progress logging throttle for Speed Adjustment in non-TTY environments (printing only first, last, and every 10%+ increase), using the `.lstrip("\r")` method.
- [ ] 2.5 Ensure the final stage completions/summaries and the inter-stage transition cleanly finalize terminal carriage-returns using `clear_line()`.

## 3. Testing and Verification

- [ ] 3.1 Validate visual output layout in a Powershell window by running the sub-tts tool with dummy subtitle files (this is intentionally a manual-only verification step).
- [ ] 3.2 Verify that no carriage-return characters (`\r`) or multiple redundant lines are spammed to log files when running in redirected/non-TTY mode.
