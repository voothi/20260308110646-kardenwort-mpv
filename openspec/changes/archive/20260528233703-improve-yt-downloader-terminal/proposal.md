## Why

The `scripts/_tools/youtube-downloader/youtube_downloader.py` tool was the original visual inspiration for the project's "premium pip-style" console aesthetic, but the sibling `sub-tts` tool has since received a focused terminal polish round (see archived change `20260528151209-improve-sub-tts-terminal`) that introduced consistent dim grey progress brackets, a parameterized `clear_line(width=...)` helper, strict reuse of the cached `_IS_TTY` constant, and a delta-based throttling pattern for non-TTY environments.

As a result, the youtube-downloader has visibly drifted from the new house style: its queue section headers (e.g. `[3/10] Direct URL`) are not styled in dim grey, its `clear_line()` helper still uses a hardcoded `120`-column buffer, parts of the streaming code re-evaluate `sys.stdout.isatty()` per pipe instead of using the cached `_IS_TTY`, and the SRT subtitle download progress stream prints nothing in non-TTY mode (no throttled fallback). Bringing youtube-downloader back in line restores a single, premium, cross-tool visual identity and ensures CI/log runs no longer silently drop subtitle progress.

## What Changes

- **Cached TTY constant everywhere**: Replace remaining `sys.stdout.isatty()` calls in `stream_pipe()` and `pause_console()` with the module-level `_IS_TTY` constant, matching the sub-tts convention.
- **Parameterized `clear_line(width=65)`**: Make the youtube-downloader's `clear_line()` accept a `width` parameter with the same `65` default constant used in `sub_tts.py`, and update its current internal call sites (notably the `pause_console` countdown clear that still writes `\r" + " " * 65 + "\r"` ad-hoc) to use the helper.
- **Dim grey queue counters**: Wrap the queue section header counter `[{idx}/{len(queue)}]` (printed via `log_section` in `main()`) in `_dim(...)` so it adopts the same pip-style faded bracket look that sub-tts uses for cue counters.
- **Delta-throttled subtitle progress in non-TTY mode**: Extend the existing delta-based throttling pattern (already present for the main video `make_premium_progress_bar` path) to the subtitle-download branch (`sub_progress_match`) so that non-TTY runs always emit the first progress line, the last progress line, and every 10%+ delta line — preventing silent log dropouts during CI/redirected runs.
- **Consistent stage-transition line clearing**: Ensure every stage handoff (URL → metadata → video stream → subtitle stream → companion-audio stream → final OK summary) calls `clear_line()` before emitting the next standalone summary log, removing carriage-return residue from the prior in-place progress bar.

## Capabilities

### New Capabilities

*None.*

### Modified Capabilities

- `youtube-video-download`: Tighten the **Pip-Style Output and Fallback Log Accuracy** requirement and the **Download Progress Feedback** requirement so they explicitly mandate (a) cached `_IS_TTY` usage, (b) dim grey progress counter brackets across the queue header and subtitle progress line, (c) delta-throttled subtitle-progress output in non-TTY mode, and (d) clean inter-stage `clear_line()` transitions — mirroring the requirements introduced for `sub-tts-pipeline` by archived change `20260528151209-improve-sub-tts-terminal`.

## Impact

- **Affected code**: `scripts/_tools/youtube-downloader/youtube_downloader.py` (pip-style helpers section, `clear_line`, `pause_console`, `stream_pipe`, `make_premium_progress_bar` call sites, and the `main()` queue section header).
- **APIs & Dependencies**: No new third-party dependencies or yt-dlp interface changes. Pure stdout/stderr formatting and TTY-detection refactor.
- **Behavioral compatibility**: TTY-attached runs remain visually identical except for the now-dim-grey queue header brackets. Non-TTY/CI runs gain throttled subtitle progress output that previously did not appear at all.
