# Tasks: Regression Review & Stability Validation

## 1. Critical Fixes (must resolve before closing)

- [x] 1.1 **[CRITICAL]** Fix `cmd_toggle_drum_window`: `FSM.DRUM_WINDOW = "DOCKED"` is mutated before all initialization completes inside the `pcall`. If any subsequent line throws, FSM is permanently corrupted — next toggle executes the close branch on a window that never opened. Implement state rollback or move the FSM mutation to after successful initialization.
- [x] 1.2 **[HIGH]** Replace all bare `pcall(fn)` error handlers with `xpcall(fn, debug.traceback)` so that logged `[LLS ERROR]` messages include full stack traces, not just the raw error string.
- [x] 1.3 **[HIGH]** Remove the hardcoded machine-specific absolute path from the init print statement: `"[LLS] SCRIPT INITIALIZING (u:\\voothi\\...)"`. Replace with a dynamic path via `mp.get_script_directory()` or remove entirely.

## 2. Static Code Analysis

- [x] 2.1 Trace `get_tsv_path()` callers: confirm that a `nil` return is handled before any `io.open` call in `load_anki_tsv`, preventing a crash when no media is loaded.
  - ✅ **SAFE**: Line 1125 — `if not tsv_path then return end` — the first statement after resolving the path. `io.open` is never reached on nil.
- [x] 2.2 Trace the `is_header` filter interaction with the auto-created TSV: verify that when `wf:write("Term\tSentence\tTime\n")` creates a file with `"Term"` as the header, and `anki_mapping.ini` has a custom field name (e.g. `"Quotation"`), the header row is still correctly filtered on the next load.
  - ✅ **SAFE**: The `is_header` check has a hardcoded fallback `term == "Term"` regardless of `term_header_name`. The auto-created header `"Term"` is always caught by this fallback.
- [x] 2.3 Verify the `force` flag semantics in `load_anki_tsv`: confirm that calling `load_anki_tsv(true)` on toggle correctly bypasses the `if next(FSM.ANKI_HIGHLIGHTS) ~= nil then return end` guard, and that this is safe on large TSV files (no performance regression for >500 rows).
  - ✅ **CONFIRMED**: The guard is `elseif not force then` — force=true bypasses it. Performance is synchronous I/O; acceptable for typical vocabulary TSVs (<2000 rows). No async option exists in mpv lua without coroutines.
- [x] 2.4 Check the periodic timer callback: confirm `dw_osd` is nil-guarded before calling `:update()` when `FSM.DRUM_WINDOW == "OFF"`.
  - ✅ **SAFE**: Timer callback at line 3972 — `if dw_osd then dw_osd:update() end`. The nil guard is present. `drum_osd` is a module-level global initialised at startup and is never nil.
- [x] 2.5 Assess `osd-dimensions` observer: in a persistent error condition (e.g. `update_font_scale` always throws), this observer fires on every resize, spamming `[LLS ERROR]` lines. Determine if a rate-limit or early-return guard is needed.
  - ⚠️ **ACCEPTED RISK**: No rate-limit added. The probability of a persistent `update_font_scale` failure is very low (it only fails if OSD dimensions are not available). Adding a debounce would complicate the code for an edge case. Documented as known acceptable risk.

## 3. Requirement Verification

- [x] 3.1 Verify the "auto-creation" behaviour against the stated requirement: the original spec (`drum-window/spec.md` §"Drum Window Opens Without TSV") says the window SHALL open with an empty table — confirm that auto-creation does not block or delay this.
  - ✅ **CONFIRMED**: `load_anki_tsv(true)` is called before the window opens. If auto-creation succeeds, the file is immediately re-read — producing an empty `new_highlights` table from the header-only file. The toggle then proceeds with an empty highlight table. No blocking.
- [x] 3.2 Confirm that the `is_header` filter covers the scenario where a file is opened immediately after auto-creation (header row `"Term"` must be skipped, not loaded as a word).
  - ✅ **CONFIRMED**: After auto-creation, `io.open(tsv_path, "r")` re-opens the file in the same call. The loop reads `"Term\tSentence\tTime"`. `term = "Term"` matches `is_header` fallback. Not added to highlights.
- [x] 3.3 Verify that deleted-file recovery and manual-management workflows are not in conflict: a user who deletes their TSV intentionally and does not want a new file created has no opt-out mechanism currently.
  - ⚠️ **KNOWN LIMITATION**: Confirmed — no opt-out. However, auto-creation only writes an empty header row; no user data is created, no records are lost. The log message `[LLS] TSV file missing - attempting auto-creation: <path>` is emitted. Documenting as known limitation, not a blocking defect.

## 4. Artifact Finalization

- [x] 4.1 Rewrite `specs/stability-review/spec.md` to cover gap scenarios identified in review (not restate existing requirements from `fix-tsv-deletion-crash`).
- [x] 4.2 Summarize all findings and fixes in `regression-report.md`.
- [x] 4.3 Archive the change once all critical and high items are resolved.
