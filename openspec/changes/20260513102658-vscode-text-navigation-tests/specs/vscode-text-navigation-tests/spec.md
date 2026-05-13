# VSCode Text Navigation Tests

## Purpose
Formalize the acceptance criteria for the Drum Window keyboard-driven text manipulation, ensuring parity with modern text editor behaviors (VSCode) and maintaining stability of the FSM state transitions.

## Requirements

### Requirement: Word-Level Navigation
The system SHALL support incremental token-level movement using Arrow keys.
- **RIGHT**: Move to the next logical token (word or punctuation).
- **LEFT**: Move to the previous logical token.

#### Scenario: Navigating tokens
- **GIVEN** a line "Hello, world!"
- **WHEN** the cursor is at "Hello" and RIGHT is pressed
- **THEN** the cursor SHALL move to the comma `,`.

### Requirement: Line-to-Line Transition
The system SHALL transition between subtitle lines when moving past the boundary.
- **RIGHT at EOL**: Move to the first token of the next subtitle.
- **LEFT at SOL**: Move to the last token of the previous subtitle.

#### Scenario: Line wrap navigation
- **GIVEN** subtitle 1 and subtitle 2
- **WHEN** the cursor is on the last word of subtitle 1 and RIGHT is pressed
- **THEN** the cursor SHALL move to the first word of subtitle 2.

### Requirement: Selection Extension (Shift)
The system SHALL maintain a selection anchor when Shift is held during navigation.
- **Shift + RIGHT**: Move cursor and set `DW_ANCHOR_WORD` if not already set.
- **Selection**: All tokens between `ANCHOR` and `CURSOR` are considered selected.

### Requirement: Jump Navigation (Ctrl)
The system SHALL support jumping over multiple tokens.
- **Ctrl + RIGHT**: Jump `dw_jump_words` tokens forward (default 5).

### Requirement: Vertical Navigation and Sticky-X
The system SHALL support moving between lines while preserving approximate horizontal position.
- **DOWN**: Move to the word closest to current `DW_CURSOR_X` on the line below.
- **Sticky-X**: If the target line is shorter, land at the end, but remember the original X for subsequent vertical moves.
