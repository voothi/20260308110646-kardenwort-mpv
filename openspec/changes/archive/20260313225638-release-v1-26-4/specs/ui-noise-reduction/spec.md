## ADDED Requirements

### Requirement: OSD Status Message Suppression
The system SHALL suppress explicit "OPEN/CLOSED" status messages when toggling major UI windows to maintain a minimalist aesthetic.

#### Scenario: Toggling the Drum Window
- **WHEN** the user executes the toggle command
- **THEN** the system SHALL update the visual state of the window WITHOUT displaying a text-based OSD status message.
