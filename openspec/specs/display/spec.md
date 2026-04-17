# Capability: original-spacing-preservation

The system must allow users to view subtitles exactly as they were formatted in the source file, preserving character-perfect spacing and punctuation, even when using the state-machine scanner for tokenization.

## ADDED Requirements

### Requirement: Whitespace Tokenization
The `build_word_list` scanner must capture whitespace as a first-class token type to ensure original formatting can be reconstructed during display.

#### Scenario: Preserving irregular spacing
- **WHEN** text is "Hello    World" (four spaces)
- **THEN** it should be tokenized into `["Hello", "    ", "World"]`
- **AND** when rendered with `dw_original_spacing = true`, it should show exactly "Hello    World"

### Requirement: Punctuation Adherence
The display joiner must not add "Smart" spaces around punctuation if `dw_original_spacing` is enabled, respecting the source file's density.

#### Scenario: German acronym display
- **WHEN** text is "z.B. Straubing"
- **THEN** it should be tokenized into `["z", ".", "B", ".", " ", "Straubing"]`
- **AND** when rendered, it should show exactly "z.B. Straubing" (not "z . B . Straubing")

### Requirement: Selection-Display Decoupling
The presence of filler/whitespace tokens must not shift the "Word Index" for selection. Only non-whitespace tokens should count as selectable "words."

#### Scenario: Keyboard navigation skips spaces
- **WHEN** the cursor is on "Hello" in the line "Hello    World"
- **AND** the user presses 'd' (move next word)
- **THEN** the cursor should skip the four spaces and land directly on "World" (Logical Index 2).
