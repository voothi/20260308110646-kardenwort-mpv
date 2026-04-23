## ADDED Requirements

### Requirement: Unified Layout Hit-Testing
The system SHALL use a pre-calculated layout table to ensure 1:1 mapping between rendered text and mouse click coordinates.

#### Scenario: Clicking a wrapped word
- **WHEN** the user clicks on a word that has been wrapped to a new line
- **THEN** the system SHALL correctly identify the word index by referencing the `dw_build_layout` coordinate table.

### Requirement: Hardware-Accelerated Dragging
The system SHALL bind mouse selection highlights to hardware-level motion events to provide fluid, high-frame-rate feedback.

#### Scenario: Rapidly dragging a selection
- **WHEN** the user drags the mouse to select multiple words
- **THEN** the highlight SHALL update at the player's native frame rate (60fps+) without polling lag.

### Requirement: Double-Click Seek Synchronization
The system SHALL support instant seeking via double-click while automatically synchronizing the viewport.

#### Scenario: Double-clicking a subtitle
- **WHEN** the user double-clicks a visible subtitle line
- **THEN** the system SHALL seek playback to that subtitle's start time and re-enable Follow Mode.
