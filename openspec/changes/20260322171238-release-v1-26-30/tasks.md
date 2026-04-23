# Tasks: Search Selection Fix (Scoping Bug)

## 1. Code Refinement
- [x] Identify scoping error in `get_word_boundary` call to `is_word_char`
- [x] Reorder function definitions in `lls_core.lua` to resolve scoping
- [x] Synchronize `FSM.DW_ANCHOR_LINE` field in Drum Window logic

## 2. Validation
- [x] Verify `Ctrl+Shift+Left/Right` word selection in Search Mode
- [x] Confirm script stability (no crashes) during complex selection actions
- [x] Verify multi-word selection accuracy in Drum Window
- [x] Test persistence of script features (Drum Window, AutoPause) after selection
