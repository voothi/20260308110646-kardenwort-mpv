## Context

During execution of the subtitle TTS pipeline (`sub_tts.py`), a single subtitle file can contain hundreds of cues (e.g. 200–500+). Currently, the system prints a full line for each individual cue during the TTS Synthesis and Speed Adjustment stages. This causes heavy scrolling clutter in the command window. Furthermore, the brackets surrounding cue numbers (e.g. `[1/274]`) in the speed adjustment phase are not styled with dim grey (`_dim`), leading to an inconsistent visual style.

This design addresses these issues by introducing an in-place, carriage-returned premium progress bar and standardizing console typography to look premium and neat, drawing inspiration from `youtube_downloader.py`.

## Goals / Non-Goals

**Goals:**
- Implement a premium, carriage-returned, in-place progress bar for the TTS Synthesis and Speed Adjustment phases when running on a TTY.
- Style all progress indicators consistently with dim brackets (e.g., `_dim("[1/274]")`).
- Support clean, throttled line-by-line logging in non-TTY environments to prevent log file bloat.
- Provide a robust way to cleanly clear carriage-returned lines when transitions or completions occur.

**Non-Goals:**
- Changing the underlying synthesis logic, file format handling, or media compilation pipeline.
- Creating progress bars for FFmpeg sub-processes, which are already managed and kept clean by FFmpeg's quiet modes and python subprocess capture.

## Decisions

### 1. Unified Cue Progress Bar Helper
To avoid confusing name clashes with `youtube_downloader.py`'s downloader-specific signature, we will introduce a new, cue-specific progress bar function in `sub_tts.py` named `make_cue_progress_bar`:
```python
def make_cue_progress_bar(current, total, label, detail="", bar_width=40, indent="  "):
    percent_val = (current / total) * 100.0 if total > 0 else 0
    filled_width = int(round(bar_width * percent_val / 100.0))
    bar = _green("━" * filled_width) + _dim("━" * (bar_width - filled_width))
    tag = _dim(f"[{current}/{total}]")
    
    line = f"\r{indent}{bar} {tag} {label}"
    if detail:
        line += f": {_dim(detail)}"
    return line
```
*Rationale*: This is a parallel implementation tailored to cue-by-cue iteration, reusing the existing `_dim`/`_green` ANSI helpers and box-drawing block (`━`) styling already established in `sub_tts.py`. The `current` parameter specifically represents the 1-indexed loop counter position (rather than `cue['index']`, which can be non-sequential or have gaps) to ensure monotonic progress bar increments.

### 2. TTY vs. Non-TTY Handling and Throttling
We will reuse the cached module-level boolean constant `_IS_TTY` rather than querying `sys.stdout.isatty()` on every loop iteration.
- **TTY mode (`_IS_TTY` is True)**: The script will print the output with a carriage return `\r` and use `clear_line()` before outputting.
- **Non-TTY mode (`_IS_TTY` is False)**: The progress line is printed as a standard line without `\r` by stripping it using `.lstrip("\r")`.
- **Throttling algorithm**: To prevent log bloating in automated/CI pipelines, we will adopt the delta-based progress throttling pattern from `youtube_downloader.py`. A progress line is printed only when `current == 1` (the first loop index), `current == total` (the last loop index), or when the percentage increase since the last printed progress line is at least 10% (`percent_val - last_pct >= 10`).

### 3. Clear line on completion and stage transitions
We will introduce `clear_line()` to completely overwrite and clear the carriage-returned terminal line:
```python
def clear_line(width=65):
    """Clears the current console line completely to prevent character leftovers."""
    sys.stdout.write("\r\x1b[K" + " " * width + "\r")
    sys.stdout.flush()
```
*Rationale*: 65 is chosen as the standard precedent constant in the `sub_tts.py` file to clean the countdown line cleanly.

We will call `clear_line()` at:
- The transition between stages (e.g. at the end of the TTS Synthesis stage, before beginning the Speed Adjustment stage).
- The completion of the Speed Adjustment stage, before the timed audio assembly logs print.

## Risks / Trade-offs

- **Risk**: Carriage returns might leave garbled characters if a longer line is followed by a shorter line.
  - *Mitigation*: Ensure `clear_line()` uses the standard ANSI escape code `\x1b[K` (Clear line from cursor to end) and a whitespace padding fallback of the configured width (default 65) before writing the new progress line.
- **Risk**: Logging in tests/CI could get too verbose or fail to print anything if throttled too aggressively.
  - *Mitigation*: The throttling logic will explicitly print the first, last, and every 10% interval cue in non-TTY mode to guarantee key checkpoints are always present in stdout logs.
