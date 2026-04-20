## Why

When clicking MMB on an existing multi-line selection in the Drum Window, the selection collapses to the click point upon release. This is caused by the "Pointer Jump Sync" logic in the mouse handler, which unconditionally updates the word cursor to the release coordinate, overwriting the protected selection state.

## What Changes

- **Implement Selection Protection State**: Introduce `FSM.DW_PROTECTED_SELECTION` flag to track when a click occurs inside an existing selection.
- **Harden Mouse Release Logic**: Update the "UP" event handler in `make_mouse_handler` to respect the protection flag, preventing cursor desynchronization when exporting existing selections.
- **Synchronize Smart Export**: Ensure `dw_anki_export_smart_callback` clears the protection flag after a successful commit.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `mmb-drag-export`: Formalize "Selection Protection" as a core requirement to prevent selection collapse during MMB interactions.

## Impact

- `scripts/lls_core.lua`: Logic modification in `make_mouse_handler` and `dw_anki_export_smart_callback`.
