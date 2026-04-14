# Design: Regression Review Strategy (v1.32.0)

## Overview

The regression review focuses on the interaction between the newly implemented file recovery logic and the existing event-driven architecture of the Drum Window. The methodology is a static logic analysis of the diff between `11bf3ac6a93b` and `704a49e02578`, with each finding mapped to a testable scenario in `specs/stability-review/spec.md`.

## Call Chain Analysis

Understanding dependencies is required before assessing risk.

```
cmd_toggle_drum_window()
└── load_anki_tsv(true)          ← called before FSM mutation (correct)
    └── get_tsv_path()           ← returns nil if no media is loaded
        └── io.open(path, "r")   ← called only if path is non-nil (must verify)
            └── [auto-creation branch if not f]
                └── io.open(path, "w")
                    └── wf:write("Term\tSentence\tTime\n")  ← hardcoded header
                    └── io.open(path, "r")   ← re-opens for reading
└── FSM.DRUM_WINDOW = "DOCKED"   ← ⚠ state mutated before full init completes
└── manage_ui_border_override(true)
└── mp.set_property_bool(...)
└── dw_osd:update()
```

### Critical Design Gap

`FSM.DRUM_WINDOW = "DOCKED"` is set early in the `OFF → DOCKED` branch — before subtitle queries, property mutations, and OSD updates. All of those operations are inside the same `pcall`. If any throw, the pcall catches the error but `FSM.DRUM_WINDOW` is already `"DOCKED"`. The next toggle call will execute the close branch (setting it back to `"OFF"`, hiding OSD, restoring sub-visibility) on a window that was never rendered.

**Resolution options** (for Phase 2 to decide):
1. Move `FSM.DRUM_WINDOW = "DOCKED"` to the *last* line of the open branch.
2. Set a temporary `"OPENING"` state before init and commit to `"DOCKED"` only on success, rolling back to `"OFF"` on error inside an `xpcall` error handler.

## Error Handling Design

### Current Pattern (inadequate)
```lua
local ok, err = pcall(fn)
if not ok then print("[LLS ERROR] site: " .. tostring(err)) end
```
`pcall` returns only the raw error string. No file, no line, no call stack.

### Required Pattern
```lua
local ok, err = xpcall(fn, debug.traceback)
if not ok then print("[LLS ERROR] site: " .. tostring(err)) end
```
`xpcall` with `debug.traceback` as the message handler produces a formatted traceback string in `err`, giving the exact failure site without needing to reproduce the crash.

## `force` Flag Semantics

`load_anki_tsv(force)` has two meaningful code paths at the top:

```lua
if FSM.ANKI_DB_PATH ~= tsv_path then
    FSM.ANKI_DB_PATH = tsv_path
    FSM.ANKI_HIGHLIGHTS = {}
elseif not force then
    if next(FSM.ANKI_HIGHLIGHTS) ~= nil then return end   -- cache hit, skip reload
end
```

When called with `force = true` (from toggle and periodic timer), the cache-hit early return is bypassed. This is correct: it ensures the highlight table is always reloaded from disk. The performance implication is that every toggle call re-reads the entire TSV file synchronously. For files under ~200 rows this is negligible; for files over ~2000 rows the I/O may be perceptible.

## Components Under Review

### 1. TSV Recovery Logic (`load_anki_tsv`)
- **Change**: Adds auto-creation branch when `io.open(path, "r")` fails.
- **Risk**: Hardcoded header `"Term\tSentence\tTime\n"` may not match user's configured field names. The `is_header` filter handles the mismatch via fallback string comparison, but this must be explicitly verified.
- **Risk**: No check for `get_tsv_path()` returning `nil` before the `io.open` call — requires tracing.

### 2. Drum Window Toggle (`cmd_toggle_drum_window`)
- **Change**: Entire body wrapped in `pcall`; `load_anki_tsv(true)` added before transition.
- **Risk (Critical)**: FSM state corrupted if error is thrown after `FSM.DRUM_WINDOW = "DOCKED"`.
- **Risk**: `pcall` does not capture traceback — error messages are not diagnostic.

### 3. System Event Observers (`sid`, `track-list`, `osd-dimensions`)
- **Change**: Callbacks wrapped in `pcall` with error logging.
- **Risk (Low)**: `osd-dimensions` fires on every resize. In persistent failure mode, every resize emits an `[LLS ERROR]` line — potential log spam. No observed buffering or rate-limiting.

## Integration Plan

The review will produce:
- **`regression-report.md`**: Findings with severity, reproducibility steps, and recommended fixes.
- **`specs/stability-review/spec.md`**: Verifiable WHEN/THEN gap scenarios.
- **Fixes in `lls_core.lua`**: Critical items resolved, changes committed and archived.
