## Context

The current `lls_core.lua` implements Drum Mode (DM) and Drum Window (DW) as semi-independent features. `cmd_toggle_drum` contains defensive checks that prevent it from running if `DRUM_WINDOW` is active, which leads to a "Managed by Drum Window" message instead of a clean mode switch. Users want a more "modal" experience where `z` and `x` acts as mode selectors.

## Goals / Non-Goals

**Goals:**
- Implement strict, non-cyclical switching logic between SRT (baseline), DM, and DW.
- Ensure `z` (DW) and `x` (DM) always activate their respective modes from any other state.
- Support toggling back to SRT by pressing the active mode's key again.
- Provide a robust "Ignore" mechanism for accidental key presses.

**Non-Goals:**
- Creating a triple-cycle (z -> DM -> DW -> SRT). The user explicitly requested non-cyclical logic.
- Changing the rendering logic of the modes themselves.

## Decisions

### Decision: Mutually Exclusive Activation
Instead of checking for other modes and returning early, the toggle functions will now proactively shut down other modes before starting.

**Rationale:** Simplifies the mental model for the user. A key press always results in the intended mode being active (or toggled off).
**Alternative:** A central `switch_mode(target)` function.
**Chosen:** Updating existing `cmd_toggle_*` functions to maintain compatibility with existing call sites while adding deactivation logic.

### Decision: Baseline Toggle
Pressing `z` while in `DW` will transition to `SRT`. Pressing `x` while in `DM` will transition to `SRT`.

**Rationale:** Provides a consistent "escape" to the baseline state without needing a third dedicated key.

### Decision: Explicit State Cleanup
When switching from `DW` to `DM`, the system must explicitly call deactivation routines (like `manage_ui_border_override(false)`) to ensure no state leakage.

## Risks / Trade-offs

- [Risk] Loss of `DW_SAVED_DRUM_STATE`.
- [Mitigation] Since modes are now strictly exclusive, the concept of "saving" the previous state to restore it on exit is removed. Every transition goes either to the new mode or back to SRT.
- [Risk] Input.conf conflicts.
- [Mitigation] Ensure `ignore` bindings are applied after all other script-bindings.
