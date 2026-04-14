## Context

Deleting or clearing the `.tsv` record file while mpv is running causes the Drum Window to silently fail — either showing nothing or stopping all key responses — with no error messages visible to the user. The failure was traced to three independent modes that compound each other.

The first mode is stale memory: when `load_anki_tsv` cannot open the file, it returned immediately without touching `FSM.ANKI_HIGHLIGHTS`, leaving phantom highlights in memory permanently. The second mode is header pollution: when a fresh `.tsv` is written with only a header row, the parsing loop accepted the header field name (e.g. `"Quotation"`) as a real word because the filter only excluded `"WordSource"` and `"Term"`. The third and most critical mode is the silent observer crash: the three `mp.observe_property` callbacks that drive `update_media_state` were not protected with `pcall`. A single Lua error inside `update_media_state` (e.g., from an invalid path or malformed line) caused mpv to silently drop the callback — meaning `Tracks.pri.subs` was never populated for the rest of the session. The user then pressed `w`, the window opened, `tick_dw` iterated zero subtitle lines, and the OSD rendered blank. Because `mp.msg.error` is filtered by mpv log level, no diagnostic output appeared in the terminal.

## Goals / Non-Goals

**Goals:**
- Ensure `FSM.ANKI_HIGHLIGHTS` is cleared whenever the `.tsv` file is absent or unreadable.
- Dynamically detect and skip the TSV header row regardless of the configured field name.
- Protect all `mp.observe_property` callbacks with `pcall` so an error inside `update_media_state` does not kill the observer.
- Force a TSV refresh at the moment the Drum Window is opened, reflecting any mid-session file deletion without waiting for the 5-second timer.
- Make script execution visible in the terminal unconditionally, independent of mpv log level.

**Non-Goals:**
- Rewriting the TSV parsing logic or changing the file format.
- Adding a UI indicator for file health status.
- Changing the behavior when the file exists and is well-formed.

## Decisions

- **Auto-Creation on Missing File:** When `io.open` fails, the script now creates a fresh `.tsv` with a default header rather than only clearing highlights. This prevents cascading nil-reference errors in downstream code that assumes a file has been written at least once, and gives the user a visible artifact confirming the script ran.
- **Dynamic Header Detection:** The filter was broadened to compare term column values against the actual configured field name (`config.fields[term_col]`), derived after the column-index resolution loop. This handles any field name defined in `anki_mapping.ini`, not just the two previously hardcoded values.
- **`pcall` on All Three Observers:** All three callbacks (`sid`, `secondary-sid`, `track-list`) now wrap their `update_media_state` call in `pcall`. The error handlers use `print()` instead of `mp.msg.error` to guarantee output visibility regardless of mpv's `--log-level` setting.
- **Subs Guard Dropped:** The original design included a `#Tracks.pri.subs == 0` guard in `cmd_toggle_drum_window` after the TSV refresh. Testing revealed it caused a regression — the window refused to open whenever the TSV was absent, because the system falsely correlated an empty highlights table with empty subtitle data. The primary `MEDIA_STATE == "NO_SUBS"` guard at the function entry is sufficient.
- **`print()` for Diagnostics:** `mp.msg.*` calls inside error handlers were replaced with `print()` throughout the affected code paths. This was the root cause of the "no messages" symptom — mpv was suppressing formatted log output at the default log level.

## Risks / Trade-offs

- **Auto-Creation Side Effect:** If the auto-creation write fails (e.g., read-only filesystem), the script logs the failure and continues. The highlights are still cleared. No user-visible fallback is provided beyond the terminal log line.
- **`print()` vs Structured Logging:** Using `print()` bypasses mpv's structured `mp.msg` system, meaning these messages will not appear in mpv's `--log-file` output. This is an acceptable trade-off for debugging visibility but should be reviewed if structured log capture becomes important.
