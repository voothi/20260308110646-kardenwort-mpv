## Why

Restore `Ctrl+C` (copy) functionality in Drum Window Book Mode navigation while maintaining independent pointer states. Ensure the copy command complies with "Verbatim Selection with Context" requirements and "Copy as is" formatting expectations.

## What Changes

- **Navigation Focus Fallback**: Update `cmd_dw_copy` to prioritize `FSM.DW_ACTIVE_LINE` in Book Mode when `FSM.DW_FOLLOW_PLAYER` is active and no word/range is selected.
- **Context Splicing**: Fix `COPY_CONTEXT` logic to correctly wrap specific word/range selections with surrounding context lines.
- **Formatting Preservation**: Remove aggressive punctuation and bracket stripping to ensure text is copied "as is" (e.g., preserving `[räuspern]`).
- **Esc Fallback**: Ensure copying works on the active line even if the manual cursor is dismissed.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `context-copy`: Fix verbatim selection wrapping requirements.
- `drum-window-navigation`: Refine focus priority for decoupled reading states.

## Impact

- **Affected Code**: `scripts/lls_core.lua` (specifically `cmd_dw_copy`).
- **Systems**: Drum Window input handling and clipboard management.
