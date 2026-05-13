## Why

Ensure 100% functional coverage for text navigation and selection in Drum Window (DW) and Dictation Mode (DM), specifically focusing on VSCode-inspired keyboard behaviors. This hardening is critical for the v1.80.0 release to guarantee reliability of the core interactive experience.

## What Changes

- Add comprehensive acceptance tests for text navigation (Word, Line, Jump).
- Add tests for selection extension (Shift + Arrow keys).
- Add tests for jump selection (Ctrl + Shift + Arrow keys).
- Verify pointer transitions and line-to-line navigation logic.
- Ensure regression stability for the layout-aware coordinate mapping.

## Capabilities

### New Capabilities
- `vscode-text-navigation-tests`: Automated acceptance tests for VSCode-inspired text selection and movement.

### Modified Capabilities
- `keyboard-selection-granularity`: Verify requirements for token-level navigation landing and Shift+Arrow selection.
- `dw-mouse-selection-engine`: Verify requirements for multi-word selection and coordinate mapping stability.

## Impact

- **Tests**: New acceptance tests in `tests/acceptance/`.
- **FSM**: Verification of `DW_CURSOR_WORD`, `DW_ANCHOR_WORD`, and `DW_CURSOR_LINE` state transitions.
- **IPC**: Utilization of `test-set-cursor`, `test-get-cursor`, and `test-get-selection` diagnostic hooks (if existing) or introduction of new ones if needed for verification.
