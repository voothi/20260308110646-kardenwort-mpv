# Keyboard Selection Granularity
 
 ## Purpose
 Enhance the Drum Window keyboard navigation to allow precise, token-level selection of punctuation and symbols, ensuring that arrow keys land on every logical element of the subtitle.
 
 ## Requirements
 
 ### Requirement: Token-Level Navigation Landing
 The Drum Window SHALL support granular token-level navigation using standard arrow keys to accommodate limited input devices like remote controls.
 - **Normal Arrow Keys**: Move the cursor between ALL logical tokens, including words, punctuation, and symbols, BUT excluding pure whitespace tokens.
 - **Shift + Arrow Keys**: Move the cursor between tokens AND extend the selection highlight.
 
 #### Scenario: Selecting punctuation with keyboard
 - **GIVEN** a subtitle line "Hello, world!"
 - **WHEN** the cursor is at "Hello" and the user presses Right
 - **THEN** the cursor SHALL move to the comma token `,`.
 - **AND** it SHALL NOT stop on the space between "Hello," and "world".
 
 #### Scenario: Starting selection from a symbol
 - **GIVEN** a subtitle line "[UMGEBUNG]"
 - **WHEN** the user presses Right from the start of the line to land on `[`
 - **AND** the user then presses Shift + Right
 - **THEN** the selection SHALL start from `[` and move to "UMGEBUNG".
 
 ### Requirement: Fractional Cursor Rendering
 The Drum Window cursor SHALL correctly highlight and position itself over symbols at fractional logical indices.
 
 #### Scenario: Cursor glow on a period
 - **GIVEN** a period `.` at logical index 1.5
 - **WHEN** the cursor is set to `logical_idx = 1.5`
 - **THEN** the `dw_compute_word_center_x` function SHALL return the X-coordinate of the period.
 - **AND** the OSD SHALL render the highlight color on the period.
