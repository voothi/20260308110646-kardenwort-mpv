# Tasks: Regression Review & Stability Validation

## 1. Critical Fixes (must resolve before closing)

- [ ] 1.1 **[CRITICAL]** Fix `cmd_toggle_drum_window`: `FSM.DRUM_WINDOW = "DOCKED"` is mutated before all initialization completes inside the `pcall`. If any subsequent line throws, FSM is permanently corrupted — next toggle executes the close branch on a window that never opened. Implement state rollback or move the FSM mutation to after successful initialization.
- [ ] 1.2 **[HIGH]** Replace all bare `pcall(fn)` error handlers with `xpcall(fn, debug.traceback)` so that logged `[LLS ERROR]` messages include full stack traces, not just the raw error string.
- [ ] 1.3 **[HIGH]** Remove the hardcoded machine-specific absolute path from the init print statement: `"[LLS] SCRIPT INITIALIZING (u:\\voothi\\...)"`. Replace with a dynamic path via `mp.get_script_directory()` or remove entirely.

## 2. Static Code Analysis

- [ ] 2.1 Trace `get_tsv_path()` callers: confirm that a `nil` return is handled before any `io.open` call in `load_anki_tsv`, preventing a crash when no media is loaded.
- [ ] 2.2 Trace the `is_header` filter interaction with the auto-created TSV: verify that when `wf:write("Term\tSentence\tTime\n")` creates a file with `"Term"` as the header, and `anki_mapping.ini` has a custom field name (e.g. `"Quotation"`), the header row is still correctly filtered on the next load.
- [ ] 2.3 Verify the `force` flag semantics in `load_anki_tsv`: confirm that calling `load_anki_tsv(true)` on toggle correctly bypasses the `if next(FSM.ANKI_HIGHLIGHTS) ~= nil then return end` guard, and that this is safe on large TSV files (no performance regression for >500 rows).
- [ ] 2.4 Check the periodic timer callback: confirm `dw_osd` is nil-guarded before calling `:update()` when `FSM.DRUM_WINDOW == "OFF"`.
- [ ] 2.5 Assess `osd-dimensions` observer: in a persistent error condition (e.g. `update_font_scale` always throws), this observer fires on every resize, spamming `[LLS ERROR]` lines. Determine if a rate-limit or early-return guard is needed.

## 3. Requirement Verification

- [ ] 3.1 Verify the "auto-creation" behaviour against the stated requirement: the original spec (`drum-window/spec.md` §"Drum Window Opens Without TSV") says the window SHALL open with an empty table — confirm that auto-creation does not block or delay this.
- [ ] 3.2 Confirm that the `is_header` filter covers the scenario where a file is opened immediately after auto-creation (header row `"Term"` must be skipped, not loaded as a word).
- [ ] 3.3 Verify that deleted-file recovery and manual-management workflows are not in conflict: a user who deletes their TSV intentionally and does not want a new file created has no opt-out mechanism currently.

## 4. Artifact Finalization

- [ ] 4.1 Rewrite `specs/stability-review/spec.md` to cover gap scenarios identified in review (not restate existing requirements from `fix-tsv-deletion-crash`).
- [ ] 4.2 Summarize all findings and fixes in `regression-report.md`.
- [ ] 4.3 Archive the change once all critical and high items are resolved.
