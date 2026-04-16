## ADDED Requirements

### Requirement: Keyboard Tooltip Toggling
The system SHALL provide a keyboard shortcut to toggle the visibility of the tooltip for the currently active subtitle on the screen.

#### Scenario: Toggling the tooltip with 'e' key
- **WHEN** the user presses the 'e' key (or 'у' in cyrillic layout) while a subtitle is active and the tooltip is hidden
- **THEN** the tooltip for the active subtitle SHALL appear on the screen

#### Scenario: Hiding a visible tooltip with 'e' key
- **WHEN** the user presses the 'e' key (or 'у' in cyrillic layout) while the tooltip is currently visible
- **THEN** the tooltip SHALL be hidden
