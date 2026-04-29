# Keyboard Selection Granularity
 
 ## Purpose
 Enhance the Drum Window keyboard navigation to allow precise, token-level selection of punctuation and symbols, supplementing the default word-to-word movement.
 
 ## Requirements
 
 ### Requirement: Modifier-Driven Selection Granularity
 The Drum Window SHALL support granular token-level selection using the Shift modifier with arrow keys.
 - **Normal Arrow Keys**: Move the cursor between adjacent words (tokens with `is_word=true`).
 - **Shift + Arrow Keys**: Move the cursor between all logical tokens, including punctuation and symbols.
 
 #### Scenario: Selecting punctuation with keyboard
 - **GIVEN** a subtitle line "Hello, world!"
 - **WHEN** the cursor is at "Hello" and the user presses Shift + Right
 - **THEN** the cursor SHALL move to the comma token `,`.
 - **WHEN** the user presses Right (without Shift) from the comma
 - **THEN** the cursor SHALL move to the word "world".
 
 ### Requirement: Fractional Cursor Rendering
 The Drum Window cursor SHALL correctly highlight and position itself over symbols at fractional logical indices.
 
 #### Scenario: Cursor glow on a period
 - **GIVEN** a period `.` at logical index 1.5
 - **WHEN** the cursor is set to `logical_idx = 1.5`
 - **THEN** the `dw_compute_word_center_x` function SHALL return the X-coordinate of the period.
 - **AND** the OSD SHALL render the highlight color on the period.
