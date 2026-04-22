## ADDED Requirements

### Requirement: Unified OSD Positioning
The system SHALL display all status notifications in the Middle-Left position of the screen to minimize visual distraction from the central content.

#### Scenario: Displaying status notification
- **WHEN** a status change occurs (e.g., toggling subtitles)
- **THEN** the notification SHALL appear at the Middle-Left (`{\an4}`) position.

### Requirement: Reactive OSD Duration
The system SHALL display OSD notifications for a duration that ensures rapid confirmation without lingering.

#### Scenario: Notification timeout
- **WHEN** an OSD message is displayed
- **THEN** it SHALL disappear after 500ms.
