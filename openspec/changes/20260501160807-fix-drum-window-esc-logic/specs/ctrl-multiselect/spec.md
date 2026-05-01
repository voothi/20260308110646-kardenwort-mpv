# Delta: Ctrl-Multiselect (Sequential Escape)

## Modified Requirement: Context-Aware Escape Mechanism
The system MUST provide an intuitive escape mechanism using the `ESC` key to gracefully clear selections in sequential stages before closing the window.

### Scenario: Context-Aware ESC Behavior (Refined)
- **WHEN** the user presses `ESC`
- **STAGES** (evaluated in order):
  1. **IF** the `ctrl_pending_set` (Pink) is not empty:
     - **THEN** clear ONLY the `ctrl_pending_set`.
  2. **ELSE IF** a multi-word selection range (Yellow Range) exists:
     - **THEN** clear the range anchor (collapsing highlight to the single Yellow Pointer).
  3. **ELSE IF** a word indicator (Yellow Pointer) exists:
     - **THEN** clear the word indicator.
  4. **ELSE** (if no selection exists):
     - **THEN** close the Drum Window.

## Requirement: Robust Selection Comparison
Selection boundary checks SHALL use an epsilon-based comparison (`logical_cmp`) to ensure consistent behavior with fractional indices (comma granularity).
