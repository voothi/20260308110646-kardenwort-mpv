# Ctrl-Multiselect (Paired Selections)

## Purpose
Enable the user to create non-contiguous mining records by pairing multiple subtitle segments or words into a single Anki export. Supports minimalist remote controllers (e.g., 8BitDo Zero 2) by decoupling selection persistence from physical modifier-key states.
## Requirements
### Requirement: Selection Range Feedback
The system SHALL provide immediate visual feedback during "Cool Path" (Pink) selections across all rendering modes (Drum Window, Drum Mode/Windowless, and SRT mode).
- **Color**: **Neon Pink (#FF88FF)**.
- **State**: Persistent until explicitly additive commit (MMB/Add) or explicit discard (ESC).

#### Scenario: Pink selection visibility
- **WHEN** the user selects a word in paired mode
- **THEN** it SHALL be colored Neon Pink (#FF88FF).

#### Scenario: Immediate Feedback in Drum Mode
- **WHEN** the user toggles a word into the paired selection set while in Drum Mode or SRT mode
- **THEN** the OSD MUST redraw immediately to reflect the Pink highlight.

### Requirement: Modifier-Decoupled Persistence
Selected items in the `ctrl_pending_set` SHALL NOT be cleared when the `Ctrl` or `Shift` modifier key is released.
- This allows users to build complex selections using single-button clicks on specialized remote profiles.

#### Scenario: Selection persists after Ctrl release
- **GIVEN** a word is added to the pink set while holding Ctrl
- **WHEN** the user releases the Ctrl key
- **THEN** the word SHALL remain in the selection set.

### Requirement: Context-Aware Escape Mechanism
The system MUST provide an intuitive escape mechanism using the `ESC` key to gracefully clear selections in sequential stages before closing the window.

#### Scenario: Context-Aware ESC Behavior (Refined)
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

### Requirement: Multiselect Joining Logic
When multiple distinct ranges or words are paired, the system SHALL use the `Smart Joiner Service` to combine them into a single `WordSource` and `SentenceSource`.
- Contiguous words SHALL be joined with original spacing.
- Non-contiguous segments SHALL be joined using the **Elliptical Joiner (` ... `)**.

#### Scenario: Joining split lines
- **User selects**: "Hello" (Line 1), "World" (Line 5).
- **Export Result**: `Hello ... World`.

#### Scenario: Preserving middle-word dashes
- **WHEN** composing a term from tokens "Marken", "-", and "Discount".
- **THEN** the resulting term MUST be "Marken-Discount".

### Requirement: Highlight Stability
Selections in the "Cool Path" (Neon Pink) SHALL maintain their visibility and logical anchoring even if the user scrokardenwort the Drum Window or performs a seek operation, up until the moment of export or discard.

#### Scenario: Scrolling preserves highlights
- **WHEN** the user scrokardenwort the window
- **THEN** existing pink highlights SHALL remain at their logical positions.

### Requirement: Configurable Palette
The system SHALL allow user overrides for all terminal colors in the "Warm vs. Cool" system.
- `ctrl_select_color`: Default `#FF88FF` (Neon Pink).
- `focus_range_color`: Default `#00CCFF` (Gold).

#### Scenario: Customizing colors
- **WHEN** the user sets `ctrl_select_color` in config
- **THEN** the system SHALL use that color for pink selections.

### Requirement: Robust Selection Comparison
Selection boundary checks SHALL use an epsilon-based comparison (`logical_cmp`) to ensure consistent behavior with fractional indices (comma granularity).

#### Scenario: Comparing word indices with epsilon
- **GIVEN** a word index `1.1` and another index `1.1` from a different tokenization pass
- **WHEN** comparing for equality in `get_dw_selection_bounds`
- **THEN** the system SHALL use `logical_cmp(a, b)` (which allows for `0.0001` epsilon) to determine if they refer to the same word.

