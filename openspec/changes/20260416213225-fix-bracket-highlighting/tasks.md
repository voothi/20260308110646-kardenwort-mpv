## 1. Export Logic Improvements

- [ ] 1.1 Update `dw_anki_export_selection` in `lls_core.lua` to implement selective metadata stripping for terms (preserving content if it's the only thing in the selection).
- [ ] 1.2 Update `ctrl_commit_set` in `lls_core.lua` to ensure consistent metadata stripping and bracket removal for multi-word manual selections.

## 2. Highlighter Robustness

- [ ] 2.1 Update `calculate_highlight_stack` in `lls_core.lua` to tolerate/skip metadata neighbors during strict context matching when `anki_strip_metadata` is enabled.

## 3. Verification

- [ ] 3.1 Verify that `[UMGEBUNG]` can be added and is saved as `UMGEBUNG`.
- [ ] 3.2 Verify that `Netto` in `[UMGEBUNG] Netto` remains highlighted even if `[UMGEBUNG]` was stripped from the saved context.
- [ ] 3.3 Verify that **paired/multi-word selection** (Ctrl+MMB/purple highlights) correctly handles metadata tags:
    - [ ] Selecting `[UMGEBUNG]` + `Netto` results in `UMGEBUNG Netto`.
    - [ ] Selecting `[musik]` + `word` results in `word` (if `[musik]` is stripped).
- [ ] 3.4 Verify that `[musik]` followed by a word (e.g., `[musik] word`) correctly strips `[musik]` from the term if only `word` is intended, or allows it if `[musik]` was specifically selected.
