## ADDED Requirements

### Requirement: Viewport Decoupling
The system SHALL support a **Manual Mode** for the Drum Window where the viewport remains static despite changes in video playback position.

#### Scenario: Navigating in Drum Window
- **WHEN** the user presses a navigation key (`UP`, `DOWN`, `LEFT`, `RIGHT`) in the Drum Window
- **THEN** the system SHALL enter Manual Mode and freeze the viewport at its current position.

### Requirement: Seek Synchronization Recovery
The system SHALL automatically re-enable **Follow Mode** and synchronize the viewport with the current playback position upon a seek event.

#### Scenario: Seeking while in Manual Mode
- **WHEN** the user executes a seek command (`a` or `d`)
- **THEN** the system SHALL clear all manual navigation states and re-center the viewport on the current subtitle.
