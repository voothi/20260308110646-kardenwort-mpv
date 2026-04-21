## ADDED Requirements

### Requirement: Sticky Horizontal Navigation (VSCode-Style)
The Drum Window SHALL implement a "sticky column" behavior for vertical keyboard navigation. When moving the cursor between lines using arrow keys, the system SHALL preserve the horizontal OSD position (X-coordinate). The cursor SHALL snap to the word on the target line whose horizontal center is closest to this preserved X-coordinate.

#### Scenario: Vertical Movement Across Variable Length Lines
- **WHEN** the cursor is on the 5th word of a long line
- **AND** the user presses the DOWN arrow to move to a shorter line
- **THEN** the system SHALL calculate the horizontal center of the 5th word
- **AND** it SHALL select the word on the shorter line that is closest to that horizontal position (even if it's word 3 or 4)

#### Scenario: Sticky Column Persistence
- **WHEN** a sticky X-coordinate is established via horizontal or vertical movement
- **AND** the user performs multiple consecutive vertical moves (UP/DOWN)
- **THEN** the system SHALL maintain that same X-coordinate as the anchor for each subsequent line transition

#### Scenario: Sticky Column Update on Horizontal Move
- **WHEN** the user moves the cursor horizontally (LEFT/RIGHT)
- **THEN** the system SHALL update the sticky X-coordinate to the horizontal center of the newly selected word

#### Scenario: Sticky Column Reset on Context Change
- **WHEN** the Drum Window cursor is explicitly cleared or repositioned (e.g., via ESC, mouse click, or track change)
- **THEN** the system SHALL reset the sticky X-coordinate to `nil`
- **AND** the next vertical movement SHALL re-anchor the sticky X-coordinate based on the current word's center (or the line's midpoint if no word is selected)
