## ADDED Requirements

### Requirement: OS Window Dragging Suppression
The system SHALL temporarily suppress native player window-dragging behaviors while the Drum Window is active to prevent event hijacking.

#### Scenario: Dragging selection near screen edge
- **WHEN** the Drum Window is open and the user initiates a drag
- **THEN** the system SHALL ensure `window-dragging` is set to `no` to protect the mouse event.

### Requirement: Layered Subtitle Isolation
The system SHALL snapshot and hide all other subtitle layers when entering the Drum Window to ensure a clean, distraction-free reading environment.

#### Scenario: Opening Drum Window
- **WHEN** the Drum Window is toggled on
- **THEN** the system SHALL store the current visibility state of all tracks, set them to hidden, and restore them upon exit.
