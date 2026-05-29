## Context

`youtube_downloader.py` (≈1,786 lines) and `sub_tts.py` (≈1,284 lines) historically shared a common "pip-style console output helper" block at the top of each file (`_c`, `_dim`, `_green`, `_tag_info`, `log_info`, `log_detail`, etc.). When archived change `20260528151209-improve-sub-tts-terminal` polished the sub-tts terminal output, it introduced four tighter conventions that the youtube-downloader has not yet adopted in full:

1. **Cached TTY detection**: a single module-level `_IS_TTY = sys.stdout.isatty()` constant, then consistent reuse — never calling `sys.stdout.isatty()` again at the hot path.
2. **Parameterized line clearing**: `clear_line(width=65)` for an overwrite/erase that the entire file uses uniformly (instead of bespoke `\r" + " " * 65 + "\r"` snippets).
3. **Dim grey progress brackets**: every "counter in brackets" (e.g. `[3/150]`, `[3/10]`) flows through `_dim(...)` so brackets render as soft grey, not stark white.
4. **Delta-based non-TTY throttling**: in non-TTY runs, print the first progress line, the last progress line, and every line whose percentage delta since the last printed line is ≥10 %.

The youtube-downloader already implements 1, 2, and 4 partially:
- It defines `_IS_TTY` (line 64) but redundantly re-evaluates `is_tty = sys.stdout.isatty()` inside `stream_pipe()` (line 950) and again inside `pause_console()` (line 188).
- It defines `clear_line()` (line 168) but with a hardcoded `120`-column whitespace buffer and no width parameter — and the countdown clear inside `pause_console()` still uses an inline `\r" + " " * 65 + "\r"` rather than the helper.
- It already throttles the **video** byte-progress line in non-TTY mode (line 896-901) but does **not** throttle the **subtitle** byte-progress line — the subtitle branch (line 903-909) is gated entirely by `if is_tty:` so non-TTY runs print nothing at all there.
- It still emits queue section headers via `log_section(f"[{idx}/{len(queue)}] {display_source}")` (line 1761) where the `[idx/total]` counter is **not** wrapped in `_dim(...)`.

This design records the alignment plan and the specific decisions/trade-offs.

## Goals / Non-Goals

**Goals:**

- Adopt the cached `_IS_TTY` constant uniformly across `youtube_downloader.py`.
- Adopt the parameterized `clear_line(width=65)` signature with the same default constant as `sub_tts.py`.
- Apply the dim grey `_dim("[N/total]")` styling to queue section headers in `main()`.
- Adopt the delta-based throttling pattern for the subtitle byte-progress path so non-TTY (CI/redirected) runs always emit subtitle progress at the standard checkpoints.
- Ensure inter-stage transitions explicitly call `clear_line()` before printing standalone summary lines so no carriage-return residue leaks into log files.

**Non-Goals:**

- Refactoring `make_premium_progress_bar` itself or changing the visual block-drawing characters (the bar already matches sub-tts's `━` aesthetic).
- Extracting a shared utility module (no new `progress_console.py` helper). The two tools intentionally keep their own self-contained pip-style helper blocks; mirroring is preferred over coupling.
- Touching the `make_cue_progress_bar` semantics of `sub_tts.py` or porting it into youtube-downloader (youtube-downloader iterates URLs at the queue level using `log_section`, not cues inside one file, so it does not need a parallel cue-style bar function).
- Changing yt-dlp invocation flags, retry logic, or any media-handling behavior.

## Decisions

### 1. Keep two pip-style helper blocks in sync via convention, not extraction

We will **not** introduce a shared `scripts/_tools/_common/console.py`. The duplicated helper block is a deliberate, short, self-contained piece of code in each tool; sharing it would tightly couple `youtube_downloader.py` and `sub_tts.py` and force every future tweak to one tool through a shared module update + two import-site reviews.

Instead, the alignment is done by direct mirror-edit: changes that landed in `sub_tts.py`'s helper block in `20260528151209-improve-sub-tts-terminal` are re-applied here, line-equivalent where possible.

*Rationale*: Two small, parallel implementations under the same author with a written specification are easier to evolve than a premature abstraction that the user has not asked for.

### 2. `clear_line(width=65)` — keep default at 65, not 120

The current `clear_line()` in `youtube_downloader.py` writes `" " * 120` because the download progress line (with size + speed + ETA + frag info) is wider than the cue-progress bars that `sub_tts.py` emits. We will change the default to `width=65` to match `sub_tts.py`'s house default, but rely on the standard ANSI `\x1b[K` ("erase to end of line") escape that the helper already emits as the **primary** clearing mechanism. The `" " * width` fallback is only material when `\x1b[K` is not honored (legacy terminals) — and call sites that need a wider buffer can override via `clear_line(width=120)`.

*Rationale*: ANSI `\x1b[K` handles modern terminals universally; the whitespace fallback width does not need to default to the worst-case line width.

### 3. Subtitle download non-TTY throttling: reuse `state["last_percent"]`

The subtitle download path uses `sub_progress_match` which yields `size_str`, `speed_str`, `time_str` but no percent value (yt-dlp does not emit a percent on subtitle streams — only bytes and elapsed time). To honor the delta-throttling spirit, we will derive a "soft" pseudo-percentage from elapsed time when possible, but if that proves brittle, we fall back to a fixed-cadence approach: print the first subtitle progress line, then suppress subsequent lines in non-TTY mode (since subtitle downloads complete in seconds and rarely emit more than a handful of progress events). The completion event is already covered by the existing `complete_match` branch.

*Rationale*: Subtitles are small; the cost of slightly-thinner non-TTY logging for subtitles is acceptable, and matching the exact 10%-delta cadence would add bookkeeping without proportional value. The key requirement is that subtitle progress is **not silently dropped** in non-TTY mode.

**Concrete behavior**: In non-TTY mode, the subtitle branch will emit at least one progress line per subtitle file (gated by a per-file state flag like `state["sub_progress_emitted"]`) so log readers see "subtitles started downloading" — the existing `complete_match` branch then prints the completion summary. TTY mode is unchanged.

### 4. Dim grey queue section header counters

`main()` currently prints:

```
log_section(f"[{idx}/{len(queue)}] {display_source}")
```

We will change this to:

```
log_section(f"{_dim(f'[{idx}/{len(queue)}]')} {display_source}")
```

This is the direct parallel to `sub_tts.py`'s `_dim(f"[{current}/{total}]")` cue tag. The `display_source` text remains in bold (via `log_section`'s `_bold()` wrap), preserving visual hierarchy.

*Rationale*: Brackets are visual scaffolding — their content (the count) is informational, but the brackets themselves should fade so the eye lands on the source label.

### 5. Replace remaining `sys.stdout.isatty()` calls with `_IS_TTY`

Two call sites in `youtube_downloader.py` still call `sys.stdout.isatty()` directly:

- `pause_console()` (line 188): `if is_windows and sys.stdout.isatty():`
- `stream_pipe()` (line 950): `is_tty = sys.stdout.isatty()` (captured per pipe-thread)

Both will switch to the cached `_IS_TTY` constant. The `stream_pipe()` local `is_tty` variable is removed and its in-function references (`if is_tty:` at lines 889, 905, 912) become `if _IS_TTY:`.

*Rationale*: Calling `sys.stdout.isatty()` repeatedly has negligible cost but breaks the convention. More importantly, `_IS_TTY` is captured once at import time, so any downstream stdout redirection during the run cannot cause inconsistent branching between the early helper functions and the later streaming threads.

### 6. Inter-stage `clear_line()` discipline

Every place where a carriage-returned in-place line is followed by a standalone `log_info`/`log_ok`/`log_warn`/`log_section` call must `clear_line()` first. The current code does this in most paths but not all (e.g. some post-`make_premium_progress_bar` summary logs rely on the next line's `\n` to overwrite the residue). We will audit and add `clear_line()` calls so every transition between TTY-mode in-place output and a fresh prefix-tagged line is clean.

*Rationale*: Without explicit clearing, residue from a truncated progress bar can leak into the start of the next summary line — visible especially when terminal width changes mid-run.

## Risks / Trade-offs

- **[Risk] Subtitle non-TTY logging could become too sparse** — emitting only one progress line per subtitle file may hide stalled subtitle downloads from CI logs.
  - **Mitigation**: The existing inactivity-watchdog (the `inactivity_timeout` arg on `run_subprocess_streaming`, with `last_activity_ts` bookkeeping at line 838) already kills processes that produce no output for the watchdog window. A stalled subtitle download will be caught by the watchdog and surface as an `[WARN] No output for Ns — killing stalled process` line, independent of the per-file progress branch.

- **[Risk] Width change in `clear_line()` (120 → 65) may leave residue on legacy/non-ANSI terminals** when a very long progress line is followed by a short one and `\x1b[K` is not interpreted.
  - **Mitigation**: All modern terminals (Windows Terminal, ConEmu, Powershell 7+ host, VS Code integrated terminal) interpret `\x1b[K`. Legacy `cmd.exe` on pre-Windows-10 hosts is the only known offender; the `make_premium_progress_bar` line on those is rarely 120-wide because the size+speed+ETA segment is colored, which is itself disabled when `_IS_TTY` is False on those hosts.

- **[Risk] Dimmed queue counter could reduce scannability** for users who rely on the bracket count to scroll back through their session.
  - **Mitigation**: The dim grey treatment is the same one used for cue counters in sub-tts and the user has explicitly accepted that styling there. The counter content (e.g. `3/10`) remains the same; only the brackets and digits fade — and `_bold()` still highlights the source label that the user actually scans for.

- **[Trade-off] Convention-based mirroring vs. shared helper module**: Two parallel implementations risk silent drift in the future.
  - **Mitigation**: The change is recorded as an OpenSpec change archive — future authors editing one tool's pip-style block can see the convention codified in the requirement and apply it to the sibling tool.
