## 1. Console helper alignment in `youtube_downloader.py`

- [ ] 1.1 Change `clear_line()` to `clear_line(width=65)` in `scripts/_tools/youtube-downloader/youtube_downloader.py` (around line 168) so the signature and default constant mirror `sub_tts.py`.
- [ ] 1.2 Inside `pause_console()` (around line 212), replace the ad-hoc `sys.stdout.write("\r" + " " * 65 + "\r")` countdown-clear with a call to `clear_line()` (default width).
- [ ] 1.3 Inside `pause_console()` (around line 188), replace `if is_windows and sys.stdout.isatty():` with `if is_windows and _IS_TTY:` so the countdown logic gates on the cached constant.

## 2. Cached `_IS_TTY` in the streaming subprocess wrapper

- [ ] 2.1 In `run_subprocess_streaming.stream_pipe()` (around line 948-950 in `youtube_downloader.py`), remove the local `is_tty = sys.stdout.isatty()` assignment.
- [ ] 2.2 Remove the `is_tty` parameter from the `process_line(raw_line, is_stderr, is_tty, state)` signature and from both `stream_pipe()` invocations of `process_line(...)`.
- [ ] 2.3 Inside `process_line()`, replace the three `if is_tty:` branches (around lines 889, 905, 912) with `if _IS_TTY:`.

## 3. Subtitle progress non-TTY throttling

- [ ] 3.1 Extend the streaming `state` dict initialization (around line 981) to include a `sub_progress_emitted` flag (default `False`) so the non-TTY subtitle branch can detect the per-file first emission.
- [ ] 3.2 In the `elif sub_progress_match:` branch (around lines 903-909), add a non-TTY arm that prints the first subtitle progress line of a file when `_IS_TTY` is False — wrap the existing `f"\r{indent}Downloading subtitles: ..."` formatting in `.strip("\r")` and emit on its own line, then set `state["sub_progress_emitted"] = True`.
- [ ] 3.3 In the `complete_match` branch (around line 910-919), reset `state["sub_progress_emitted"] = False` so the next subtitle file's first event prints again.

## 4. Queue section header dim grey counter

- [ ] 4.1 In `main()` (around line 1761 in `youtube_downloader.py`), replace `log_section(f"[{idx}/{len(queue)}] {display_source}")` with `log_section(f"{_dim(f'[{idx}/{len(queue)}]')} {display_source}")` so the bracketed counter renders in dim grey.

## 5. Inter-stage `clear_line()` discipline audit

- [ ] 5.1 Audit all call sites in `download_video_and_metadata` (and its helpers) where a `make_premium_progress_bar(...)` write is followed by a standalone `log_info`/`log_ok`/`log_warn`/`log_detail`/`log_section` call; insert `if _IS_TTY: clear_line()` before each such transition where it is currently missing.
- [ ] 5.2 Confirm the existing `clear_line()` calls inside the retry / fragment-skip branches (around lines 854, 860, 866, 891, 906, 913, 922, 928, 934) remain in place and continue to use the helper rather than ad-hoc whitespace writes.

## 6. Testing and verification

- [ ] 6.1 Run `youtube_downloader.py` against a short YouTube URL in a PowerShell window and visually confirm: (a) the queue section header counter `[1/1]` renders in dim grey, (b) the video progress bar still renders in-place, (c) the subtitle progress bar still renders in-place, (d) no carriage-return residue appears on any `[OK]`, `[INFO]`, `[WARN]` line. *Manual-only verification step.*
- [ ] 6.2 Run `youtube_downloader.py` with stdout redirected to a file (`python youtube_downloader.py <url> > log.txt 2>&1`) and confirm: (a) no `\r` characters appear in `log.txt`, (b) the video stream's throttled progress lines appear at first, every 10%+ delta, and at completion, (c) at least one subtitle progress line appears per subtitle file, (d) no raw ANSI escape sequences appear.
- [ ] 6.3 Run `openspec validate 20260528233703-improve-yt-downloader-terminal --strict` and confirm the change validates cleanly before archival.
