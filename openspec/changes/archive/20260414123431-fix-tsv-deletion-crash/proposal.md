## Why

Deleting or clearing the `.tsv` record file while mpv is running causes the Drum Window to enter a broken state — the interface either shows blank content or stops responding to key input entirely, with no error messages visible. The failure is silent because the initialization path uses `mp.observe_property` without crash protection: a single Lua error inside `update_media_state` causes mpv to drop the observer permanently, leaving subtitle data unpopulated for the rest of the session. Compound failures from stale highlight memory and defective header filtering make the state unrecoverable without restarting mpv.

## What Changes

- Wrap all `mp.observe_property` callbacks that invoke `update_media_state` in `pcall`, keeping observers alive through errors.
- Clear `FSM.ANKI_HIGHLIGHTS` when `load_anki_tsv` cannot open the record file, and auto-create a fresh file in its place.
- Fix the TSV header filter to use the actual configured field name from `anki_mapping.ini` rather than a hardcoded list of two values.
- Force a `load_anki_tsv(true)` refresh at the moment the Drum Window is opened, so file deletions are reflected immediately.
- Replace `mp.msg.error` in observer error handlers with `print()` to guarantee terminal visibility regardless of mpv log level.

## Capabilities

### New Capabilities
- The script now prints `[LLS] SCRIPT INITIALIZING...` and `[LLS] SCRIPT LOADED SUCCESSFULLY` to the terminal on every startup, allowing the user to confirm the script is being loaded by mpv without changing any command-line flags.

### Modified Capabilities
- `tsv-state-recovery`: Expand the missing-file handling to clear stale highlights, auto-create the record file, and dynamically skip any header row regardless of the configured field name.
- `drum-window`: Strengthen the window-open path to force a TSV sync and keep the observer pipeline alive through errors, ensuring the window always opens and renders correctly even when no record file exists.

## Impact

- **Affected code:** `load_anki_tsv`, `cmd_toggle_drum_window`, and the three `mp.observe_property` registrations in `lls_core.lua`.
- **Side effects:** Observer errors now appear in the terminal as `[LLS ERROR] ...` lines using `print()`, which bypasses the mpv structured log system and will not appear in `--log-file` output.
