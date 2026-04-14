# Regression Report: TSV Deletion Crash Fix (v1.32.0)

> Change: `20260414123431-fix-tsv-deletion-crash`
> Review Range: `11bf3ac6a93b` → `704a49e02578`
> Reviewed: 2026-04-14

---

## Summary

The implementation addressed three core requirements: TSV state recovery on file deletion, Drum Window force-refresh on open, and observer resilience. The critical fixes are correctly implemented. One pre-existing state-corruption bug was found in the toggle function and has been resolved in this review cycle.

**Overall verdict: Implementation approved with fixes applied.**

---

## Findings

| # | Severity | Status | Finding |
|---|----------|--------|---------|
| F1 | 🔴 Critical | ✅ Fixed | `FSM.DRUM_WINDOW = "DOCKED"` was set before all initialization completed inside `pcall`. A failure after that line would leave FSM permanently believing the window was open. |
| F2 | 🟠 High | ✅ Fixed | All bare `pcall()` calls used — error messages captured without stack traces. Replaced with `xpcall(..., debug.traceback)`. |
| F3 | 🟠 High | ✅ Fixed | Hardcoded machine-specific absolute path in `print("[LLS] SCRIPT INITIALIZING ...")`. Replaced with dynamic `mp.get_script_directory()`. |
| F4 | 🟡 Medium | ✅ Safe | Auto-created TSV header `"Term\tSentence\tTime"` with custom `anki_mapping.ini` field names: the hardcoded `term == "Term"` fallback in `is_header` catches the auto-generated header correctly in all tested configurations. |
| F5 | 🟡 Medium | ✅ Verified | `load_anki_tsv(true)` on every toggle is synchronous. Acceptable for vocabulary file sizes typical in this workflow (<2000 rows). No async mechanism available without coroutines. |
| F6 | 🟢 Low | ⚠️ Accepted | `osd-dimensions` observer logs `[LLS ERROR]` on every resize in persistent failure mode. Rate-limit not added — failure condition is theoretical and debounce would add complexity. |
| F7 | 🟢 Low | ⚠️ Known Limitation | No opt-out for TSV auto-creation. A user who intentionally deletes their file cannot prevent recreation. Auto-created file is empty (header only); no data loss occurs. |

---

## Code Changes Applied in This Review

### `lls_core.lua`

**Fix F1 — FSM State Rollback**

`cmd_toggle_drum_window` now:
1. Snapshots `prev_drum_window = FSM.DRUM_WINDOW` before entering the `xpcall`.
2. Moves `FSM.DRUM_WINDOW = "DOCKED"` to after all initialization that can throw (saves, property mutations, OSD updates).
3. Moves `FSM.DRUM_WINDOW = "OFF"` to after all cleanup that can throw.
4. On `xpcall` failure, restores `FSM.DRUM_WINDOW = prev_drum_window`.

**Fix F2 — xpcall Replacement**

All `pcall` calls in error handlers replaced with `xpcall(fn, debug.traceback)`:
- `cmd_toggle_drum_window`
- `sid` observer
- `secondary-sid` observer
- `track-list` observer (both `update_media_state` and `update_font_scale`)
- `osd-dimensions` observer
- Periodic sync timer

**Fix F3 — Dynamic Init Path**

```lua
-- Before
print("[LLS] SCRIPT INITIALIZING (u:\\voothi\\...\\lls_core.lua)")

-- After
print("[LLS] SCRIPT INITIALIZING: " .. (mp.get_script_directory and mp.get_script_directory() or "<unknown dir>"))
```

---

## Requirements Traceability

| Requirement | Source Spec | Status |
|-------------|-------------|--------|
| TSV cleared on missing file | `tsv-state-recovery/spec.md` | ✅ Implemented & verified |
| Auto-creation of missing file | `tsv-state-recovery/spec.md` | ✅ Implemented & verified |
| Header row excluded from highlights | `tsv-state-recovery/spec.md` | ✅ Implemented; custom field names covered by fallback |
| Force-refresh on toggle open | `drum-window/spec.md` | ✅ Implemented — called before state mutation |
| Window opens with empty table when no TSV | `drum-window/spec.md` | ✅ Verified — auto-creation yields header-only file |
| Observer errors logged, observer stays active | `drum-window/spec.md` | ✅ Implemented with xpcall |
| Toggle error does not corrupt FSM | `stability-review/spec.md` | ✅ Fixed in this review |
| Error output includes traceback | `stability-review/spec.md` | ✅ Fixed in this review |
| No crash on nil media path | `stability-review/spec.md` | ✅ Verified — `if not tsv_path then return end` on line 1125 |

---

## Remaining Known Limitations

1. **Auto-creation opt-out**: No mechanism for users who prefer a missing TSV to remain missing. Non-blocking; file is always empty at creation.
2. **Synchronous TSV load on toggle**: Large files (>5000 rows, unusual) could cause a brief hitch. No async mechanism available in standard mpv Lua.
3. **osd-dimensions log spam in persistent error**: Theoretical only; `update_font_scale` failures are inherently transient.
