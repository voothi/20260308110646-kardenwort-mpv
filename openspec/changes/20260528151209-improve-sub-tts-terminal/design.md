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
We will introduce a new progress bar formatting function in `sub_tts.py` similar to the one in `youtube_downloader.py`, customized for cue iteration:
```python
def make_premium_progress_bar(current, total, label, detail="", bar_width=40, indent="  "):
    percent_val = (current / total) * 100.0 if total > 0 else 0
    filled_width = int(round(bar_width * percent_val / 100.0))
    bar = _green("━" * filled_width) + _dim("━" * (bar_width - filled_width))
    tag = _dim(f"[{current}/{total}]")
    
    line = f"\r{indent}{bar} {tag} {label}"
    if detail:
        line += f": {_dim(detail)}"
    return line
```
*Rationale*: This matches the beautiful pip-style and custom colors of the rest of the workspace and provides rich interactive feedback.

### 2. TTY vs. Non-TTY Handling and Throttling
- When `sys.stdout.isatty()` is `True`, the script will print using carriage return `\r` and call a `clear_line()` function to prevent overlapping artifacts.
- When `sys.stdout.isatty()` is `False` (such as background logging or automated tests), the progress bar is printed as a standard line without `\r` but only at specific steps (e.g., at `percent_val % 10 == 0`, first cue, and last cue) to avoid log spamming.

### 3. Clear line on completion
We will introduce `clear_line()` to completely overwrite and clear the carriage-returned terminal line:
```python
def clear_line():
    """Clears the current console line completely to prevent character leftovers."""
    sys.stdout.write("\r\x1b[K" + " " * 120 + "\r")
    sys.stdout.flush()
```

## Risks / Trade-offs

- **Risk**: Carriage returns might leave garbled characters if a longer line is followed by a shorter line.
  - *Mitigation*: Ensure `clear_line()` uses the standard ANSI escape code `\x1b[K` (Clear line from cursor to end) and a whitespace padding fallback before writing the new progress line.
- **Risk**: Logging in tests/CI could get too verbose or fail to print anything if throttled too aggressively.
  - *Mitigation*: The throttling logic will explicitly print the first, last, and every 10% interval cue in non-TTY mode to guarantee key checkpoints are always present in stdout logs.
