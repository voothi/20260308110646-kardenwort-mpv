## Why

The current `Esc` key behavior in the Drum Window and Drum Mode requires two presses to clear a single word highlight and exit, which is counter-intuitive and inconsistent with the "Context-Aware Escape" mechanism defined in the project specifications. This change aims to restore a unified, single-stage interaction for clearing active highlights and selections.

## What Changes

- Refactor the context-aware Escape mechanism to sequentially clear selections: Pink Set -> Yellow Range -> Yellow Pointer -> Exit.
- Ensure that a single word highlight (Yellow Pointer) is cleared in one `Esc` press.
- Update selection boundary checks to robustly handle fractional indices.

## Capabilities

### New Capabilities
<!-- None -->

### Modified Capabilities
- `ctrl-multiselect`: Refine the Context-Aware Escape Mechanism requirements to explicitly define the sequential clearing stages.
- `drum-window`: Update Escape synchronization requirements to match the refined context-aware behavior.

## Impact

- `scripts/lls_core.lua`: Primary logic implementation.
- `openspec/specs/ctrl-multiselect/spec.md`: Requirement refinement.
- `openspec/specs/drum-window/spec.md`: Requirement refinement.
