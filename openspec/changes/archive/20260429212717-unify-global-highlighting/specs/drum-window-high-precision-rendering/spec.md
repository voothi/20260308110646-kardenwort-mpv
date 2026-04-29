## ADDED Requirements

### Requirement: Global Stream-Based Punctuation Rendering
The Drum Window SHALL use a **Global Token Stream** pass to determine punctuation colors, ensuring that highlights flow across visual line wraps and subtitle boundaries without "white holes" or color dropouts.

#### Scenario: Cross-subtitle bracket coloring
- **WHEN** A parenthetical expression `(Word)` is split across two subtitle entries
- **THEN** Both the opening and closing brackets SHALL inherit the highlight color of the enclosed word, regardless of the entry boundary.

## MODIFIED Requirements

### Requirement: Disciplined Punctuation Stacks
Punctuation marks SHALL recalculate their Orange and Purple stack counts independently from their neighbor words, using a **whitespace-blind global search** to identify the nearest relevant semantic neighbor in either direction.

#### Scenario: Punctuation Bleed Prevention
- **WHEN** A word is "Brick" (intersected) but the trailing comma only belongs to an "Orange" record
- **THEN** The comma SHALL be colored Orange, not Brick, by identifying the correct neighbor context even across spaces.
