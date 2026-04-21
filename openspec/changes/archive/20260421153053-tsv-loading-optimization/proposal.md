## Why

The introduction of the "Advanced Index" system significantly increased the processor load during TSV parsing, especially for databases containing thousands of highlights. Currently, the script re-parses the entire TSV file whenever tracks change or a periodic sync occurs, even if the file content remains identical. Implementing a "fingerprinting" approach reduces redundant CPU cycles by skipping the parsing step when no changes are detected.

## What Changes

- **TSV Fingerprinting**: Implement a pure-Lua check using modification time (mtime) and file size to detect TSV changes.
- **Optimized Reloads**: Refactor `load_anki_tsv` to skip expensive parsing loops if the file fingerprint matches the in-memory state.
- **FSM State expansion**: Capture current TSV mtime and size in the internal state machine.
- **Enhanced Logging**: Provide explicit feedback in the console when a reload is optimized/skipped.
- **Safety Hardening**: Ensure reloads are only skipped if data is already present in memory and fingerprints match perfectly.

## Capabilities

### New Capabilities
- `tsv-load-optimization`: Establishes the requirement for stateful tracking of TSV file metadata to minimize parsing overhead.

### Modified Capabilities
- `anki-highlighting`: Requirements for high-frequency highlight refreshing now include a mandatory "change detection" step to protect CPU resources.
- `source-url-discovery`: (Optional/Planned) Requirements for periodic `.url` file scanning may include similar fingerprinting to reduce filesystem I/O.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (specifically `load_anki_tsv` and `FSM` initialization).
- **Performance**: Significant reduction in idle CPU usage during periodic syncs (controlled by `anki_sync_period`).
- **User Experience**: Elimination of occasional UI stutter during background syncs on large databases.
