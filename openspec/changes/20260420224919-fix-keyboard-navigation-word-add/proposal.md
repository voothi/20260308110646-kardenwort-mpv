## Why

Keyboard-based navigation in the Drum Window currently fails to support word addition/export behavior because of a fatal script crash in the fallback export path and unsynchronized cursor state initialization. This prevents users from effectively using arrow keys to select and export words to Anki, forcing a reliance on mouse interaction.

## What Changes

- **Fix Export Path Crash**: Introduce proper variable definitions (`target_sub`) in the keyboard-focus fallback of the Anki export logic to prevent script crashes when `al` (anchor line) is undefined.
- **Fix Data Integrity**: Ensure `term`, `time_pos`, and `advanced_index` are correctly populated and synchronized from the keyboard focus point (`cl`, `cw`) during fallback exports.
- **Synchronize Line Navigation**: Update `cmd_dw_line_move` to intelligently select the first valid word of a line rather than a hardcoded index, ensuring contextual actions like `t` (toggle pink) and `r` (add word) always target a valid logical token.
- **UI State Hardening**: Add missing OSD updates in the single-word fallback path of `cmd_dw_toggle_pink` to ensure keyboard-triggered toggles provide immediate visual feedback.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `drum-window-indexing`: Refine implementation to ensure keyboard-driven cursor grounding always targets a valid atomized word token.
- `mmb-drag-export`: Update export logic to support single-token fallback when the interaction anchor is undefined (standard keyboard focus mode).

## Impact

- `scripts/lls_core.lua`: Significant logic hardening in `dw_anki_export_selection`, `cmd_dw_line_move`, and `cmd_dw_toggle_pink`.
- System Stability: Elimination of a fatal `nil` reference error in the LLS core during keyboard-driven exports.
