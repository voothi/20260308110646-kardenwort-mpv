---
aliases: 
  - Code Review — Commit d92e6edf (20260528235743).
up: "[[20260528235830-do-a-review-last]]"
type: 
status: 
down: 
prev: 
next: 
same: 
project: 
area: 
tags: []
created: 2026-05-29
due: 
---

# Code Review — Commit d92e6edf (20260528235743).

## Description

Change: 20260528233703-improve-yt-downloader-terminal — align youtube_downloader.py with the sub-tts premium pip-style terminal conventions. Overview Three files changed. The commit aligns youtube_downloader.py with the house style established in the archived 20260528151209-improve-sub-tts-terminal change: parameterized clear_line(width=65), cached _IS_TTY everywhere, non-TTY subtitle progress throttling, dim grey queue header brackets, and explicit inter-stage line-clearing guards. tasks.md is marked complete. docs/conversation.log is updated. Correctness sub_progress_emitted scoping — clean. The flag is initialized in each call's local state dict (line 984), so it correctly resets per run_subprocess_streaming invocation. Since each subtitle language command runs in its own subprocess call, there's no cross-file contamination. sub_progress_emitted reset in complete_match — redundant but harmless. Since complete_match fires on [download] 100% of X in T at S lines (which yt-dlp emits on subtitle completion too), the reset is logically correct. It's defensive, not strictly necessary given per-call state isolation, but it provides correct behavior if yt-dlp ever emits multiple subtitle files in a single subprocess run. state.get("sub_progress_emitted") vs state["sub_progress_emitted"] (line ~909): The key is guaranteed to exist since it's initialized in the state dict. Using.get() here is overly defensive — state["sub_progress_emitted"] would be idiomatic and consistent with how state["last_percent"] is accessed on the line above. Low-priority, no functional impact. Inter-stage clear_line() guards — some are unconditional when no progress bar may have run. For example, the guard inserted at line ~1583 fires even when mode == "video" (subtitle section is skipped). Emitting \r\x1b[K on an already-clean line is a no-op visually but generates a redundant write every URL. By design (erring on always-clean), this is acceptable. process_line closure correctly reads _IS_TTY — it's a module-level global, not a parameter, so the closure captures it correctly after removing the is_tty parameter. Clean. Thread Safety state["sub_progress_emitted"] is only read/written in the stdout pipe path (is_stderr=False). The stderr path doesn't touch it. Both paths hold PRINT_LOCK before accessing state. Correct — no new race conditions. Style and Conventions _dim(f'[{idx}/{len(queue)}]') inner single-quote nesting is valid Python 3.12 (project target). Consistent with sub_tts.py's _dim(f"[{current}/{total}]"). clear_line(width=65) default matches sub_tts.py exactly — mirror is faithful. clear_line() in pause_console() replaces the ad-hoc sys.stdout.write("\r" + " " * 65 + "\r") cleanly. The ANSI \x1b[K primary clear is now active here too; minor improvement. The new if _IS_TTY: clear_line() guards in download_video_and_metadata and download_companion_audio use a consistent single-line if form without braces/block, matching the surrounding code style. Potential Concerns download_companion_audio still uses bare print(..., flush=True) for warning/status lines (e.g. print(f" Extracted audio-only stream...") and print(f" WARNING: Companion audio download failed...")). These predate this commit and aren't introduced by it, but now they have if _IS_TTY: clear_line() guards before them without the log-tag prefix style (log_warn, log_info). The inconsistency is inherited, not new. No action needed now but worth noting for a future cleanup pass. clear_line() with width=65 fallback on long progress bars: The ANSI \x1b[K handles modern terminals universally. Legacy cmd.exe without VT processing would only get 65 whitespace chars, which may not fully overwrite a 90-char video progress line. This is the accepted trade-off per the design doc and matches sub_tts.py's convention. Verification Per the conversation log: 140 unit tests (22 + 14 + 13 + remaining unit suite) pass cleanly, and openspec validate --strict confirms the change is fully valid. Verdict: LGTM. The implementation is a faithful, clean execution of the OpenSpec. No blocking issues.

## MOC.



## Notes


