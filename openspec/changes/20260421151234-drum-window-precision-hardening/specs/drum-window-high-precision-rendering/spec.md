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

## Dialogue Test Cases (Baseline Anchors)

### Case: nummer-59-dot (Anchor 20260421141721)
- **CONTEXT**: `[musik] Nummer 59.`
- **USER ACTION**: Highlighting "Nummer 59" with mouse-drag, avoiding the dot.
- **REQUIREMENT**: The exported `WordSource` MUST be `Nummer 59`. The trailing dot must stay white/neutral.

### Case: multi-line-erreichbar (Anchor 20260421145226)
- **CONTEXT**: Subtitle 1: `...erreichbar.` / Subtitle 2: `Hinterlassen...`
- **USER ACTION**: Selecting a phrase that spans both lines.
- **REQUIREMENT**: The exported `WordSource` MUST contain the dot (`erreichbar.`). The Drum Window must display the dot in full capture color (no "white hole" at the line break).

### Case: punkt-letzte-comma (Anchor 20260421135322)
- **CONTEXT**: `Punkt, letzte`
- **USER ACTION**: Intersection of Orange (`Punkt`) and Purple (`letzte`) selections.
- **REQUIREMENT**: The comma `,` must NOT turn Brick (intersection color) unless it is geometrically and logically part of the intersection of both records. It must independently recalculate its highlight stack.

### Case: nested-purple-gradient (Anchor 20260421124025)
- **CONTEXT**: `dieses Jahr...hoffen, dass` (Overlapping purple records).
- **USER ACTION**: Rendering overlapping split-selections in the Drum Window.
- **REQUIREMENT**: The intersection area must be visually darker (Purple Depth 2 or 3) to represent the nesting of the footprint shadows.

