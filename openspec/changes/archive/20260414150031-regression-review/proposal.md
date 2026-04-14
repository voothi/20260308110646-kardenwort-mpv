# Proposal: Regression Review (v1.32.0 Implementation Phase)

## Problem Statement

A series of critical fixes and stability improvements were implemented between commits `11bf3ac6a93b` and `704a49e02578`, specifically targeting TSV state recovery and Drum Window initialization. Given the complexity of the `lls_core.lua` script and the historical frequency of silent crashes in OSD-heavy interactions, a formal regression review is required to ensure that:
1. New safety mechanisms (pcalls, auto-creation) do not introduce secondary issues (e.g., recursive errors, file lock contention).
2. The core requirements for TSV recovery are fully met.
3. No existing features (Anki syncing, font scaling, UI state management) were inadvertently broken by the addition of error handling for system events.

## Objectives

- Verify the robustness of the new `load_anki_tsv` auto-creation logic.
- Ensure that `pcall` wrapping in `cmd_toggle_drum_window` and system observers correctly reports errors without leaving the application in an inconsistent state (`FSM` mismatches).
- Identify any "death loops" or performance regressions introduced by the added logging or explicit TSV refreshes.
- Document any remaining edge cases (e.g., read-only filesystem, corrupt config files).

## What Changes

This is an **analysis change**. No functional code changes are being proposed, but a comprehensive review of the following will be performed:
- **TSV Recovery Logic**: Path handling and file accessibility during auto-creation.
- **Error Propagation**: Effectiveness of the new `[LLS ERROR]` logging.
- **State Consistency**: Lifecycle of the Drum Window and FSM across toggle events.

## Impact

- **Affected Areas**: `scripts/lls_core.lua` (TSV loading, event observers, drum window logic).
- **Dependencies**: OpenSpec changes `20260414123431-fix-tsv-deletion-crash`.

## Success Criteria

- Confirmation that `load_anki_tsv` handles missing files without crashing.
- Confirmation that Drum Window toggling remains stable even if internal functions throw errors.
- No detected regressions in font scaling or subtitle tracking logic.
