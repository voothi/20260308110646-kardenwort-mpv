# Spec: SRT Subtitle Wrapping

## ADDED Requirements

### Requirement: Automatic Line Wrapping in OSD
The OSD rendering engine must automatically wrap subtitle lines that exceed the maximum visual width (1860px) into multiple vertical lines.

#### Scenario: Long SRT Line
- **WHEN** an SRT subtitle contains a sentence longer than the screen width.
- **THEN** it should be split into two or more visual lines.
- **AND** each visual line should be centered horizontally.
- **AND** the total block of wrapped lines should be centered vertically according to the track position.

### Requirement: Interactive Word Highlighting on Wrapped Lines
All words in a wrapped subtitle must remain interactive and correctly mapped to their visual coordinates.

#### Scenario: Clicking a Word on a Second Line
- **WHEN** a subtitle is wrapped to a second line.
- **AND** a user clicks on a word on that second line.
- **THEN** the system must correctly identify the word index.
- **AND** the hover/selection highlight must appear at the correct (x, y) coordinates on that second line.
