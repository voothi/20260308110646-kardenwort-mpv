# Spec: SRT Subtitle Wrapping and Interactivity

## Requirements

### Requirement: Automatic Line Wrapping
The OSD renderer must automatically wrap subtitles that exceed the visual safe area (1860px).

#### Scenario: Long Sentence Wrapping
- **WHEN** a subtitle line width > 1860px
- **THEN** it must be split at the nearest word boundary.
- **AND** the resulting lines must be centered horizontally at x=960.

### Requirement: Forced Line Breaks
Source-level newlines must be respected as absolute line breaks.

#### Scenario: Manual Wrapping in SRT
- **WHEN** an SRT subtitle contains a `\n` character.
- **THEN** the text must break at that position, regardless of the current line width.

### Requirement: Multi-Line Interactivity
Hover and click interactions must be accurate across all visual lines of a wrapped subtitle.

#### Scenario: Interacting with Wrapped Text
- **WHEN** a word is displayed on the second or third line of a wrapped subtitle.
- **THEN** it must respond to mouse hover with the correct highlighting.
- **AND** clicking it must perform the same action as if it were on a single line.
