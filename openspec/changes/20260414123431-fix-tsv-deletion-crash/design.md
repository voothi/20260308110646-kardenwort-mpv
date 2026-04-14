## Context

The Drum Window and related mechanisms depend on an active TSV file to store and retrieve records. Currently, when the user or an external process deletes or clears the active TSV file, `kardenwort.lua`/`lls_core.lua` attempts to read or parse the non-existent or empty file without proper boundary checks. This results in missing fields or unexpected nil values that cascade into a fatal silent failure during Drum Window initialization. The system lacks a safety mechanism to verify the integrity of the critical data source before engaging the UI.

## Goals / Non-Goals

**Goals:**
- Identify when the active TSV record file is deleted, missing, or empty right before operations that require reading it (like opening the Drum Window).
- Re-initialize or recreate the TSV file seamlessly with correct headers if it is completely missing.
- Provide a clear `mp.osd_message` indicating the failure state if recovery is impossible.
- Prevent any UI freezing or state corruption during Drum Window opening when the file is unavailable.

**Non-Goals:**
- Restoring lost data from the deleted TSV file.
- Creating an independent backup/snapshot system for TSV data.

## Decisions

**Decision:** Before opening the Drum Window or returning rows in the TSV parser, explicitly verify the file's existence and size.
*Rationale:* Relying simply on iteration limits or parsing logic assumes a structurally valid file. Explicitly checking `io.open` or utilizing standard Lua filesystem calls guarantees that we don't attempt to process a missing file.

**Decision:** Automatically rewrite the TSV headers if the file is recreated or discovered as empty.
*Rationale:* If the user accidentally deletes the file, a seamless recovery involves recreating an empty, valid state. Re-writing standard anki mapping headers allows the script to continue without error.

**Decision:** Wrap critical reading loops in pcall or safe return fallbacks.
*Rationale:* Prevents uncaught Lua errors from silently crashing the script thread if `io.lines` or similar operations fail unexpectedly.

## Risks / Trade-offs

- **Risk**: File locks from external editors (like VSCode) might prevent the script from recreating or reading the file, causing another failure.
  - *Mitigation*: We will use robust `pcall` or check the return of `io.open(path, "a")` before trying to read/write, degrading gracefully to UI errors if standard file I/O operations fail.
