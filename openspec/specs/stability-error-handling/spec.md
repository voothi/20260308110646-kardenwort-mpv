# Spec: Stability & Error Handling

> Capability: `stability-error-handling`
> Introduced: `20260414150031-regression-review`

This spec documents the error-handling and stability requirements for `kardenwort/main.lua` — specifically around FSM state consistency, diagnostic output quality, and graceful degradation when file I/O or Lua functions fail.

---

## Requirements

### Requirement: FSM State Consistency on Toggle Failure
If `cmd_toggle_drum_window` throws a Lua error after `FSM.DRUM_WINDOW` has already been mutated, the FSM SHALL return to its pre-call state so that subsequent toggle calls behave correctly.

#### Scenario: Error thrown after DOCKED state is set
- **WHEN** a toggle invocation mutates `FSM.DRUM_WINDOW` to `"DOCKED"`
- **AND** a subsequent line inside the same protected block throws a Lua error
- **THEN** `FSM.DRUM_WINDOW` SHALL be rolled back to its pre-call value
- **AND** the next toggle call SHALL correctly identify the current state and react appropriately

#### Scenario: Error thrown during close branch
- **WHEN** `FSM.DRUM_WINDOW` is `"DOCKED"` and the user triggers a close
- **AND** the close branch throws before `FSM.DRUM_WINDOW = "OFF"` is set
- **THEN** `FSM.DRUM_WINDOW` SHALL be rolled back, leaving the window in a known open state

---

### Requirement: Diagnostic Error Output Includes Traceback
All `[Kardenwort ERROR]` log lines SHALL include enough context to identify the failure site without requiring a second reproduction (i.e., file name and line number of the failure).

#### Scenario: Error in toggle with traceback
- **WHEN** `cmd_toggle_drum_window` catches a Lua error
- **THEN** the logged message SHALL include the file name and line number of the failure via `xpcall(..., debug.traceback)`
- **AND** an OSD notification SHALL be displayed: "Kardenwort ERROR: Check console"

---

### Requirement: No Phantom Highlights After Auto-Creation
When a TSV file is auto-created, the header row SHALL be excluded from the highlight cache regardless of whether the configured field name matches the auto-created header.

#### Scenario: Auto-created file with real config field names
- **WHEN** a TSV is auto-created
- **AND** `anki_mapping.ini` defines the term column with any field name
- **THEN** the written header SHALL use the actual configured field names (not hardcoded defaults)
- **AND** `FSM.ANKI_HIGHLIGHTS` SHALL remain empty after the load

#### Scenario: Auto-created file — fallback when no config exists
- **WHEN** a TSV is auto-created
- **AND** no `anki_mapping.ini` exists or no fields are configured
- **THEN** the written header SHALL default to `"Term\tSentence\tTime"`
- **AND** the fallback `term == "Term"` check in `is_header` SHALL filter it correctly

---

### Requirement: No Crash on Nil Media Path
`load_anki_tsv` SHALL exit cleanly when called with no media loaded (i.e., when `get_tsv_path()` returns `nil`), without attempting any file I/O.

#### Scenario: Invoked before media is loaded
- **WHEN** `load_anki_tsv` is called (e.g., from the periodic timer)
- **AND** `mp.get_property("path")` returns nil
- **THEN** the function SHALL return immediately
- **AND** no `io.open(nil, ...)` call SHALL be attempted

---

### Requirement: Auto-Creation Does Not Conflict With Manual Management
A user who intentionally deletes their TSV file SHALL have visibility that the system will recreate it via a log message at the point of creation.

#### Scenario: Intentional deletion
- **WHEN** a user deletes the `.tsv` file manually while mpv is running
- **AND** `load_anki_tsv` is next invoked
- **THEN** a log message SHALL be emitted: `[Kardenwort] TSV file missing - attempting auto-creation: <path>`
- **AND** the newly created file SHALL contain only the header row and no user data


