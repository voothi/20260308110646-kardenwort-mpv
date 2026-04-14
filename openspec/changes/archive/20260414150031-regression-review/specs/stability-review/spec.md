# Spec: Regression Coverage — Gap Scenarios

> This spec captures edge cases and failure modes NOT covered by the original `fix-tsv-deletion-crash` specs. It documents conditions that must hold for the implementation to be considered safe, not conditions already proven correct by existing tests.

## ADDED Requirements

### Requirement: FSM State Consistency on Toggle Failure
If `cmd_toggle_drum_window` throws a Lua error after `FSM.DRUM_WINDOW` has already been mutated, the FSM SHALL return to its pre-call state so that subsequent toggle calls behave correctly.

#### Scenario: Error thrown after DOCKED state is set
- **WHEN** `FSM.DRUM_WINDOW` is mutated to `"DOCKED"` during a toggle invocation
- **AND** a subsequent line inside the same `pcall` block throws a Lua error
- **THEN** the next toggle call SHALL correctly identify the current state and react appropriately
- **AND** no phantom close-branch execution SHALL occur on an unopened window

#### Scenario: Error thrown during close branch
- **WHEN** `FSM.DRUM_WINDOW` is `"DOCKED"` and the user triggers a close
- **AND** the close branch throws before `FSM.DRUM_WINDOW = "OFF"` is set
- **THEN** the window SHALL either remain open and functional, or be forced to a known clean state

---

### Requirement: Diagnostic Error Output Includes Context
All `[LLS ERROR]` log lines emitted via the error handlers SHALL include enough context to identify the failure site without requiring a second reproduction.

#### Scenario: Error in toggle with traceback
- **WHEN** `cmd_toggle_drum_window` catches a Lua error via `pcall`
- **THEN** the logged message SHALL include the file name and line number of the failure
- **AND** the message format SHALL be `[LLS ERROR] <site>: <traceback>`

---

### Requirement: No Phantom Highlights After Auto-Creation
When a TSV file is auto-created with a default header row, and `load_anki_tsv` immediately re-reads the new file in the same call, the header row SHALL be excluded from the highlight cache.

#### Scenario: Auto-created file with mismatched field name
- **WHEN** the TSV is auto-created with the hardcoded header `"Term\tSentence\tTime"`
- **AND** `anki_mapping.ini` defines the term column with a custom field name (e.g. `"Quotation"`)
- **THEN** the header value `"Term"` SHALL still be filtered by the fallback `term == "Term"` check
- **AND** `FSM.ANKI_HIGHLIGHTS` SHALL remain empty after the load

---

### Requirement: No Crash on Nil Media Path
`load_anki_tsv` SHALL exit cleanly when called with no media loaded (i.e. when `get_tsv_path()` returns `nil`), without attempting any file I/O.

#### Scenario: Invoked before media is loaded
- **WHEN** `load_anki_tsv` is called (e.g. from the periodic timer)
- **AND** `mp.get_property("path")` returns nil
- **THEN** the function SHALL return immediately
- **AND** no `io.open(nil, ...)` call SHALL be attempted

---

### Requirement: Auto-Creation Does Not Conflict With Manual Management
A user who intentionally deletes their TSV file SHALL have visibility that the system will recreate it. There SHALL be a log message making this behaviour explicit at the point of creation.

#### Scenario: Intentional deletion
- **WHEN** a user deletes the `.tsv` file manually while mpv is running
- **AND** `load_anki_tsv` is next invoked
- **THEN** a log message SHALL be emitted stating the file was missing and a new one is being created
- **AND** the newly created file SHALL contain only the header row and no user data
