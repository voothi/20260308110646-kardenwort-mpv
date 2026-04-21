## ADDED Requirements

### Requirement: Shadow-Based Selection Tracking
The rendering engine must track highlights using absolute subtitle timelines (footprints) rather than simple word indices. This ensures that gaps in split-word selections (Purple) are correctly recognized as "shadowed" by the record.

#### Scenario: Nested Purple Highlights
- **WHEN** Two purple records overlap in time and logical space
- **THEN** The overlapping words must display a darker purple shade (Depth 2 or 3) determined by the number of active shadow footprints.

### Requirement: Disciplined Punctuation Stacks
Punctuation marks must recalculate their Orange and Purple stack counts independently from their neighbor words.

#### Scenario: Punctuation Bleed Prevention
- **WHEN** A word is "Brick" (intersected) but the trailing comma only belongs to an "Orange" record
- **THEN** The comma must be colored Orange, not Brick.

### Requirement: Pixel-Perfect Fractional Export
The Anki export engine must use fractional logical indices with an epsilon guard to determine selection inclusion.

#### Scenario: Sentence Dot Exclusion
- **WHEN** A user highlights `Word.` dragging only over the word
- **THEN** The trailing dot (coordinate `X.1`) must be excluded from the `WordSource` text.

#### Scenario: Multi-Line Selection Continuity
- **WHEN** A user selects multiple lines
- **THEN** Trailing punctuation on all non-terminal lines must be automatically included in the `WordSource`.
