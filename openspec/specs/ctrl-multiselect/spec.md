# Ctrl-Multiselect (Paired Selections)

## Purpose
Enable the user to create non-contiguous mining records by pairing multiple subtitle segments or words into a single Anki export. Supports minimalist remote controllers (e.g., 8BitDo Zero 2) by decoupling selection persistence from physical modifier-key states.

## Requirements

### Requirement: Selection Range Feedback
The system SHALL provide immediate visual feedback during "Cool Path" (Pink) selections.
- **Color**: **Neon Pink (#FF88FF)**.
- **State**: Persistent until explicitly additive commit (MMB/Add) or explicit discard (ESC).

### Requirement: Modifier-Decoupled Persistence
Selected items in the `ctrl_pending_set` SHALL NOT be cleared when the `Ctrl` or `Shift` modifier key is released.
- This allows users to build complex selections using single-button clicks on specialized remote profiles.

### Requirement: Context-Aware Escape Mechanism
The system MUST provide an intuitive escape mechanism using the `ESC` key to gracefully clear selections before closing the window.

#### Scenario: Context-Aware ESC Behavior
- **WHEN** the user presses `ESC`
- **IF** there is an active selection (either `ctrl_pending_set` has items OR there is a contiguous selection anchor)
- **THEN** the system SHALL clear all active selection sets and anchors immediately.
- **ELSE** (if no selection exists), the system SHALL close the Drum Window.

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
Selections in the "Cool Path" (Neon Pink) SHALL maintain their visibility and logical anchoring even if the user scrolls the Drum Window or performs a seek operation, up until the moment of export or discard.

### Requirement: Configurable Palette
The system SHALL allow user overrides for all terminal colors in the "Warm vs. Cool" system.
- `ctrl_select_color`: Default `#FF88FF` (Neon Pink).
- `focus_range_color`: Default `#00CCFF` (Gold).
