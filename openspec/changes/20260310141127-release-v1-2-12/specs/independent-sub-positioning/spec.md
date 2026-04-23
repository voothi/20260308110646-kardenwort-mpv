## ADDED Requirements

### Requirement: Manual Secondary Track Control
The system SHALL provide hotkeys for the independent vertical adjustment of secondary subtitle tracks using the `secondary-sub-pos` property.

#### Scenario: Adjusting secondary track position
- **WHEN** the user presses `Shift+R` or `Shift+T`
- **THEN** the system SHALL increment or decrement the `secondary-sub-pos` property.

### Requirement: Positional Persistence across Modes
The system SHALL maintain manual vertical position offsets when transitioning between normal and Drum Mode.

#### Scenario: activating Drum Mode after adjustment
- **WHEN** the user adjusts the base position of a track and then toggles Drum Mode
- **THEN** the context lines SHALL be rendered relative to the new manual base position.
