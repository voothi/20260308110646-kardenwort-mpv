## ADDED Requirements

### Requirement: Modifier-Driven Selection Granularity
The Drum Window SHALL support granular token-level selection using the Shift modifier with arrow keys.
- **Normal Arrow Keys**: Move the cursor between adjacent words (tokens with `is_word=true`). Behavior unchanged from current implementation.
- **Shift + Arrow Keys**: Move the cursor between ALL logical tokens, including punctuation and symbols.

#### Scenario: Selecting punctuation with keyboard
- **GIVEN** a subtitle line "Hello, world!"
- **WHEN** the cursor is at "Hello" and the user presses Shift + Right
- **THEN** the cursor SHALL move to the comma token `,`.
- **WHEN** the user presses Right (without Shift) from the comma
- **THEN** the cursor SHALL move to the word "world".

#### Scenario: Selecting brackets with keyboard
- **GIVEN** a subtitle line "[Musik] Ende des Tests."
- **WHEN** the cursor is at "Musik" and the user presses Shift + Left
- **THEN** the cursor SHALL move to the opening bracket `[`.
- **WHEN** the user presses Shift + Right twice from "Musik"
- **THEN** the cursor SHALL move to `]`, then to a space token (if present), then to "Ende".

#### Scenario: Standard navigation unchanged
- **GIVEN** a subtitle line "Hello, world!"
- **WHEN** the cursor is at "Hello" and the user presses Right (without Shift)
- **THEN** the cursor SHALL skip the comma and move directly to "world".

### Requirement: Fractional Cursor Rendering
The Drum Window cursor SHALL correctly highlight and position itself over symbols at fractional logical indices.

#### Scenario: Cursor glow on a period
- **GIVEN** a period `.` at logical index 1.5
- **WHEN** the cursor is set to `logical_idx = 1.5`
- **THEN** the `dw_compute_word_center_x` function SHALL return the X-coordinate of the period using epsilon-aware comparison (`logical_cmp`).
- **AND** the OSD SHALL render the highlight color on the period token.

#### Scenario: Selection range includes fractional tokens
- **GIVEN** a Shift+Arrow selection spanning from word index 2.0 to symbol index 3.5
- **WHEN** the selection is rendered
- **THEN** all tokens with `logical_idx` between 2.0 and 3.5 (inclusive, with epsilon guard) SHALL be highlighted in the selection color.
