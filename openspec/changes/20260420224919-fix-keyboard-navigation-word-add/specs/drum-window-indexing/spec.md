## ADDED Requirements

### Requirement: Keyboard Cursor Synchronization
The system SHALL ensure that line-based keyboard navigation (UP/DOWN) always synchronizes the cursor to a valid word token on the target line.
- **Auto-Snap**: If a line move occurs and the new line contains word tokens, the `FSM.DW_CURSOR_WORD` SHALL be set to the logical index of the first word token on that line.
- **Empty Line Handling**: If a line contains no word tokens, `FSM.DW_CURSOR_WORD` SHALL be set to `-1` to prevent invalid toggle/export actions.

#### Scenario: Navigating to a line with leading punctuation
- **WHEN** the user navigates from one line to the next using the DOWN arrow.
- **AND** the target line starts with leading punctuation (e.g., `[Note]`).
- **THEN** `FSM.DW_CURSOR_WORD` SHALL be set to the logical index corresponding to the first word (e.g., "Note").

## MODIFIED Requirements

### Requirement: Logical Hit-Test Snapping
The hit-testing engine SHALL implement logical token snapping for all mouse and keyboard interactions.
- **Visual-to-Logical Mapping**: Clicks, drags, or arrow navigation landing on or targeting tokens SHALL be identified by their unique logical index.
- **Margin Snap**: Mouse coordinates outside the active text block (line gaps or margins) SHALL be clamped to the first/last logical word of the nearest visible subtitle line.
- **Keyboard Precision**: Keyboard navigation SHALL skip non-word tokens (spaces, punctuation) unless explicitly using sub-word navigation modes.
- **Precision**: The system SHALL use a 0.0001 epsilon for all logical index comparisons to ensure stability across floating-point coordinates.

#### Scenario: Snapping keyboard cursor across spacers
- **WHEN** the user is focused on word 1 and presses the RIGHT arrow.
- **AND** word 1 and word 2 are separated by multiple spaces or punctuation tokens.
- **THEN** `FSM.DW_CURSOR_WORD` SHALL jump directly to 2, skipping all fractional logical indices.
