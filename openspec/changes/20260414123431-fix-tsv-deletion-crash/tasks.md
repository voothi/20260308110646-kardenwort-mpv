## 1. Safety Wrapping TSV State Loading

- [x] 1.1 Locate the Drum Window initialize and file loading routines (e.g. in `lls_core.lua` or `kardenwort.lua` `init_tsv_state` or `open_drum_window`).
- [x] 1.2 Implement a robust file existence verification check before parsing (using `io.open`). When file is missing, `ANKI_HIGHLIGHTS` is now explicitly cleared.
- [ ] 1.3 Add a fallback path that writes the standard ANKI header map to a recreated file if it is missing or empty. (Deferred — not needed; DW works fine with no records.)

## 2. Drum Window Resiliency Integration

- [x] 2.1 Update the Drum Window open path to force-refresh TSV state before transitioning to `DOCKED`, catching any mid-session deletions/clears.
- [x] 2.2 Add verbose log (`mp.msg.verbose`) when file not found; parse errors logged via `mp.msg.warn`.
- [x] 2.3 DW opening is NOT blocked on TSV failure — DW works without highlights (correct design).

## 3. Empty File Robustness

- [x] 3.1 Verify robust handling of empty rows without nil reference crashes in highlighting and TSV parsing sequences. Parse loop is now wrapped in `pcall`; `calculate_highlight_stack` already guards on `not next(FSM.ANKI_HIGHLIGHTS)`.
- [x] 3.2 Script falls back gracefully: on file missing or parse error, highlights are cleared and DW continues to function normally for subtitle navigation.
