# Proposal: Search Selection Fix (Scoping Bug) (v1.26.30)

## Problem
A Lua scoping error in Search Mode caused the script to crash when attempting word-based selection (`Ctrl+Shift+Arrow`). The `get_word_boundary` function attempted to call `is_word_char` before it was defined, resulting in a runtime error that killed the script session. Additionally, a state field name mismatch in the Drum Window's selection logic compromised multi-word selection stability.

## Proposed Change
Reorder utility function definitions in `lls_core.lua` to resolve scoping issues and synchronize state field names in the Drum Window logic to match established patterns.

## Objectives
- Resolve the script crash during word selection in Search Mode.
- Ensure all local functions are defined before they are called.
- Fix state field name inconsistencies in the Drum Window's selection logic.
- Restore VSCode-like word navigation and selection stability.

## Key Features
- **Lua Scoping Correction**: Proper ordering of `is_word_char` and `get_word_boundary`.
- **Drum Window State Fix**: Corrected `FSM.DW_ANCHOR_LINE` reference.
- **Improved Runtime Stability**: Prevention of `nil` function call errors.
