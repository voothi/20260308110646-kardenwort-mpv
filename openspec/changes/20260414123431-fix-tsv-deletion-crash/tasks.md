## 1. Observer Protection

- [x] 1.1 In `lls_core.lua`, wrap the `sid` and `secondary-sid` `mp.observe_property` callbacks with anonymous functions that call `pcall(update_media_state)` internally, preventing a crash inside `update_media_state` from silently killing the observer.
- [x] 1.2 In `lls_core.lua`, wrap the `track-list` observer callback body in `pcall` for both `update_media_state` and `update_font_scale`.
- [x] 1.3 Replace `mp.msg.error` in all observer `pcall` error handlers with `print()` to bypass mpv log-level filtering and ensure visibility in the terminal.

## 2. TSV State Recovery

- [x] 2.1 In `lls_core.lua` within `load_anki_tsv`, when `io.open` returns `nil`, clear `FSM.ANKI_HIGHLIGHTS = {}` before returning, so stale highlights from a previous file are not left in memory.
- [x] 2.2 In `lls_core.lua` within `load_anki_tsv`, after clearing highlights on missing file, attempt to auto-create a fresh `.tsv` file with a default header row so downstream callers always have a valid file to open.
- [x] 2.3 In `lls_core.lua` within `load_anki_tsv`, after the column-index resolution loop, capture `local term_header_name = config.fields[term_col]` to derive the configured header value dynamically.
- [x] 2.4 In `lls_core.lua` within `load_anki_tsv`, replace the hardcoded `term ~= "WordSource" and term ~= "Term"` filter with an `is_header` variable that also compares against `term_header_name`, so custom field names (e.g. `"Quotation"`) are correctly excluded.

## 3. Drum Window Resilience

- [x] 3.1 In `lls_core.lua` within `cmd_toggle_drum_window`, call `load_anki_tsv(true)` at the top of the `if FSM.DRUM_WINDOW == "OFF"` branch, before the state transition, so mid-session file deletions are reflected immediately on window open.
- [x] 3.2 In `lls_core.lua`, wrap the `cmd_toggle_drum_window` body in a `pcall` so initialization errors are caught and logged via `print()` rather than crashing silently.

## 4. Initialization Diagnostics

- [x] 4.1 Add `print("[LLS] SCRIPT INITIALIZING...")` at the top of the script initialization block so the user can confirm the script is being executed by mpv.
- [x] 4.2 Add `print("[LLS] SCRIPT LOADED SUCCESSFULLY")` at the very end of `lls_core.lua` so the user can confirm the full script loaded without parse errors.
