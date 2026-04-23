## ADDED Requirements

### Requirement: Mode-Independent Seek Keys
The system SHALL provide hotkeys for precise 2-second seeking that function independently of whether the Drum Window navigation mode is active.

#### Scenario: Seeking while navigating text
- **WHEN** the Drum Window is active and the user presses `Shift+A` or `Shift+D`
- **THEN** the system SHALL execute an exact 2-second seek without interfering with the text cursor or viewport.

### Requirement: Exact Seek Enforcement
Alternative seek keys SHALL utilize the `exact` seek flag to ensure precise alignment with subtitle boundaries.

#### Scenario: Using alternative seek
- **WHEN** the user presses `A` or `D`
- **THEN** the system SHALL jump exactly 2 seconds from the current position.
